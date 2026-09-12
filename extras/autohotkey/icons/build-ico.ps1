# Builds frontman.ico from frontman.svg.
# Renders the SVG once with headless Chrome, downsamples to each icon size with
# System.Drawing, and packs the PNGs into a multi-resolution .ico.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$dir    = $PSScriptRoot
$svg    = Join-Path $dir 'frontman.svg'
$ico    = Join-Path $dir 'frontman.ico'
$master = Join-Path $env:TEMP 'frontman-master.png'
$sizes  = 256, 48, 32, 24, 16

$chrome = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $chrome) { throw 'Need Chrome or Edge to rasterize the SVG.' }

if (Test-Path $master) { Remove-Item $master }
Start-Process -FilePath $chrome -Wait -NoNewWindow -ArgumentList @(
    '--headless=new', '--disable-gpu', '--hide-scrollbars',
    '--force-device-scale-factor=1', '--default-background-color=00000000',
    '--window-size=512,512', "--screenshot=$master",
    "file:///$($svg -replace '\\', '/')"
)

$src = [System.Drawing.Image]::FromFile($master)
$pngs = foreach ($s in $sizes) {
    $bmp = New-Object System.Drawing.Bitmap $s, $s
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode  = 'HighQualityBicubic'
    $g.SmoothingMode      = 'HighQuality'
    $g.PixelOffsetMode    = 'HighQuality'
    $g.CompositingQuality = 'HighQuality'
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($src, 0, 0, $s, $s)
    $g.Dispose()
    if ($s -ge 256) {
        # 256 px is conventionally PNG-compressed.
        $ms = New-Object System.IO.MemoryStream
        $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        $bytes = $ms.ToArray()
    } else {
        # Smaller sizes as classic 32-bit BMP entries: BITMAPINFOHEADER with
        # double height, bottom-up BGRA pixels, then a 1-bpp AND mask.
        # GDI+ and older tooling handle these far more reliably than PNG.
        $rect = New-Object System.Drawing.Rectangle 0, 0, $s, $s
        $data = $bmp.LockBits($rect, 'ReadOnly', 'Format32bppArgb')
        $px = New-Object byte[] ($s * $s * 4)
        [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $px, 0, $px.Length)
        $bmp.UnlockBits($data)
        $maskStride = [int][math]::Ceiling($s / 32) * 4
        $ms = New-Object System.IO.MemoryStream
        $bw = New-Object System.IO.BinaryWriter $ms
        $bw.Write([uint32]40); $bw.Write([int32]$s); $bw.Write([int32]($s * 2))
        $bw.Write([uint16]1); $bw.Write([uint16]32); $bw.Write([uint32]0)
        $bw.Write([uint32]($px.Length + $maskStride * $s))
        $bw.Write([int32]0); $bw.Write([int32]0); $bw.Write([uint32]0); $bw.Write([uint32]0)
        for ($y = $s - 1; $y -ge 0; $y--) { $bw.Write($px, $y * $s * 4, $s * 4) }
        for ($y = $s - 1; $y -ge 0; $y--) {
            $row = New-Object byte[] $maskStride
            for ($x = 0; $x -lt $s; $x++) {
                if ($px[($y * $s + $x) * 4 + 3] -eq 0) { $row[$x -shr 3] = $row[$x -shr 3] -bor (0x80 -shr ($x -band 7)) }
            }
            $bw.Write($row)
        }
        $bw.Flush()
        $bytes = $ms.ToArray()
    }
    $bmp.Dispose()
    @{ size = $s; bytes = $bytes }
}
$src.Dispose()

# ICO container: 6-byte header, 16-byte directory entry per image, then image data.
$fs = [System.IO.File]::Create($ico)
$w  = New-Object System.IO.BinaryWriter $fs
$w.Write([uint16]0); $w.Write([uint16]1); $w.Write([uint16]$pngs.Count)
$offset = 6 + 16 * $pngs.Count
foreach ($p in $pngs) {
    $dim = if ($p.size -ge 256) { 0 } else { $p.size }   # 0 means 256
    $w.Write([byte]$dim); $w.Write([byte]$dim)           # width, height
    $w.Write([byte]0); $w.Write([byte]0)                 # palette, reserved
    $w.Write([uint16]1); $w.Write([uint16]32)            # planes, bpp
    $w.Write([uint32]$p.bytes.Length); $w.Write([uint32]$offset)
    $offset += $p.bytes.Length
}
foreach ($p in $pngs) { $w.Write($p.bytes) }
$w.Dispose()

"Wrote $ico ($((Get-Item $ico).Length) bytes): $($sizes -join ', ') px"
