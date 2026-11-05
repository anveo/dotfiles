<#
.SYNOPSIS
    Unlocks a drive that held an old Windows install so you can delete its
    leftovers in Explorer.

.DESCRIPTION
    With only a drive (elevated), walks everything at the top of it that isn't
    in use and lists just the items Explorer couldn't delete even after its
    "Continue" prompt, with a description of common names. Read-only.

    With names, walks each named top-level item and, on every file and folder:
      - makes your account the owner
      - replaces the permissions with full control for your account,
        Administrators and SYSTEM (inherited and deny rules are dropped)
      - clears the read-only, hidden and system flags
    Nothing is deleted. Afterwards, delete what you like in Explorer.

    Junctions and symlinks are unlocked as links and never followed. Old
    installs contain junctions with absolute C:\ targets (for example
    ProgramData\Application Data -> C:\ProgramData) that resolve to your live
    system. That is why this doesn't just run takeown /R and icacls /T, which
    follow them. Permissions are set per item through a handle, so nothing is
    propagated to children behind the script's back either.

    Refused even when named ("in use"):
      - System Volume Information and $Recycle.Bin
      - Boot, Recovery and boot files, if the drive is a system or active
        partition (the current Windows may boot through it)
      - an active page file on the drive
      - WindowsApps / WpSystem / XboxGames / .GamingRoot, if the current
        Windows uses the drive for Store or Xbox apps
      - Steam libraries (from Steam's libraryfolders.vdf)
      - folders holding a WSL distro registered to your account
      - folders holding a service's program or a running program

    With -Delete, the named items are deleted with robocopy in backup mode
    instead of unlocked. Use it for folders Explorer can't remove, such as
    paths over 260 characters deep inside Windows\WinSxS.

.PARAMETER Drive
    Drive to work on, e.g. J, J: or J:\

.PARAMETER Name
    Top-level names to unlock (or delete, with -Delete). Separate several
    with commas; that also works from cmd: "Windows,Program Files"

.PARAMETER Delete
    Delete the named items instead of unlocking them.

.PARAMETER Check
    Read-only. Reports, per item, what Explorer would fail to delete: files
    and folders it lacks permission to delete, folders it can't list, and
    paths too long for it. Checks the named items, or everything not in use.
    Unelevated, it tests Explorer as you; elevated, it tests what happens
    after Explorer's "Continue" prompt, which is the case that matters.

.PARAMETER Force
    Skip the "type YES" confirmation.

.EXAMPLE
    unlock-oldwin J:
    List what's locked on J:, even after Explorer's Continue. Changes nothing.

.EXAMPLE
    unlock-oldwin J: Windows,ProgramData,Users -Check
    Report what Explorer couldn't delete in those three. Changes nothing.

.EXAMPLE
    unlock-oldwin J: Windows,ProgramData,Users
    Unlock those three, after you type YES.

.EXAMPLE
    unlock-oldwin J: Windows -Delete
    Delete J:\Windows outright, for when Explorer gives up on it.
#>
# Not #Requires -RunAsAdministrator: listing and -Check work unelevated.
# Unlock and -Delete check for admin themselves.
[CmdletBinding(SupportsShouldProcess)]
param(
    # Not Mandatory: with no drive the script prints usage, then asks for one.
    [Parameter(Position = 0)]
    [ValidatePattern('^[A-Za-z]:?\\?$')]
    [string]$Drive,

    [Parameter(Position = 1)]
    [string[]]$Name = @(),

    [switch]$Delete,

    [switch]$Check,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not $Drive) {
    Write-Host @'
Usage: unlock-oldwin <drive> [<names>] [-Check | -Delete] [-Force] [-WhatIf]

  unlock-oldwin J:                         list what's locked, even after Explorer's
                                           Continue (read-only, elevated, takes minutes)
  unlock-oldwin J: -Check                  per-folder detail with example paths
  unlock-oldwin J: Windows,ProgramData     unlock those (asks for YES first)
  unlock-oldwin J: 'Program Files,Users'   quote names with spaces or $
                                           (from cmd, use "double quotes")
  unlock-oldwin J: Windows -Delete         delete instead of unlocking

  -Check    report what Explorer couldn't delete; elevated = after "Continue"
  -Delete   delete the named items instead of unlocking them
  -Force    skip the YES confirmation
  -WhatIf   show what would happen, change nothing

Full help (from PowerShell): Get-Help unlock-oldwin -Detailed

'@
    # Validate before assigning: $Drive carries ValidatePattern, and assigning
    # a bad value to it would throw an unfriendly metadata error.
    $answer = (Read-Host 'Drive (e.g. J:)').Trim()
    if ($answer -notmatch '^[A-Za-z]:?\\?$') {
        Write-Host "Not a drive letter: '$answer'." -ForegroundColor Red
        exit 1
    }
    $Drive = $answer
}

# Modules this script auto-loads (CimCmdlets, Storage, Appx) create aliases
# when they load, and those calls inherit -WhatIf, printing dozens of
# "What if: Set Alias" lines. Everything up to "Build the plan" only reads, so
# run that stretch with WhatIf off; it's restored before anything can change.
$savedWhatIf = $WhatIfPreference
$WhatIfPreference = $false

$StoreFolders = @('WindowsApps', 'WpSystem', 'XboxGames', '.GamingRoot')
# What common top-level names are, shown next to them. Just a hint: anything
# can be named. Single-quoted keys: several start with $. Keys match
# case-insensitively.
$Descriptions = @{
    'Windows'                = 'old Windows: the operating system itself'
    'Windows.old'            = 'old Windows: previous install kept after an upgrade'
    'ProgramData'            = 'old Windows: app data and settings shared by all users'
    'Users'                  = 'old Windows: user profiles; check for personal files first'
    'Documents and Settings' = 'old Windows: compatibility link to Users'
    'Program Files'          = 'old Windows: 64-bit programs; may include apps you still use'
    'Program Files (x86)'    = 'old Windows: 32-bit programs; may include apps you still use'
    'Recovery'               = 'old Windows: recovery environment (WinRE)'
    'Boot'                   = 'old Windows: boot manager settings'
    'PerfLogs'               = 'old Windows: performance logs, usually empty'
    'inetpub'                = 'old Windows: IIS web server files'
    '$GetCurrent'            = 'old Windows: Windows Update upgrade logs'
    '$WINDOWS.~BT'           = 'old Windows: feature-upgrade setup files'
    '$Windows.~WS'           = 'old Windows: upgrade files from the Media Creation Tool'
    '$WinREAgent'            = 'old Windows: backup from a recovery-environment update'
    '$SysReset'              = 'old Windows: logs from a "Reset this PC"'
    'ESD'                    = 'old Windows: downloaded upgrade image'
    'Config.Msi'             = 'old Windows: Windows Installer rollback files'
    'MSOCache'               = 'old Windows: Microsoft Office installer cache'
    'OneDriveTemp'           = 'old Windows: OneDrive temporary files'
    'pagefile.sys'           = 'old Windows: page file (virtual memory)'
    'hiberfil.sys'           = 'old Windows: hibernation file'
    'swapfile.sys'           = 'old Windows: swap file for Store apps'
    'bootmgr'                = 'old Windows: boot manager'
    'BOOTNXT'                = 'old Windows: boot manager'
    'BOOTSECT.BAK'           = 'old Windows: backup of an older boot sector'
    'bootTel.dat'            = 'old Windows: boot telemetry'
    'DumpStack.log'          = 'old Windows: crash-dump log'
    'DumpStack.log.tmp'      = 'old Windows: crash-dump log'
    'Intel'                  = 'driver installer leftovers'
    'AMD'                    = 'driver installer leftovers'
    'NVIDIA'                 = 'driver installer leftovers'
    'adobeTemp'              = 'Adobe apps: temporary and installer files'
    'VstPlugins'             = 'audio plugins (VST) for music software'
    'SteamLibrary'           = 'Steam game library'
    'WindowsApps'            = 'Microsoft Store app installs'
    'WpSystem'               = 'Microsoft Store app data'
    'XboxGames'              = 'Xbox app game installs'
    '.GamingRoot'            = 'marker file for the Xbox app'
}
$BootItems    = @('Boot', 'Recovery', 'bootmgr', 'BOOTNXT', 'BOOTSECT.BAK')
$Protected    = @('System Volume Information', '$Recycle.Bin')

function Format-Bytes([Nullable[long]]$Bytes) {
    if ($null -eq $Bytes) { return '?' }
    $units = 'B', 'KB', 'MB', 'GB', 'TB'
    $v = [double]$Bytes; $i = 0
    while ([Math]::Abs($v) -ge 1024 -and $i -lt $units.Count - 1) { $v /= 1024; $i++ }
    '{0:N1} {1}' -f $v, $units[$i]
}

function Format-Elapsed([TimeSpan]$Span) {
    if ($Span.TotalHours -ge 1)   { return '{0}h{1:00}m' -f [int][Math]::Floor($Span.TotalHours), $Span.Minutes }
    if ($Span.TotalMinutes -ge 1) { return '{0}m{1:00}s' -f [int][Math]::Floor($Span.TotalMinutes), $Span.Seconds }
    '{0:N1}s' -f $Span.TotalSeconds
}

# --- Native tree walker ------------------------------------------------------
# Every item is opened with FILE_FLAG_OPEN_REPARSE_POINT (acts on a link, not
# its target) and FILE_FLAG_BACKUP_SEMANTICS (with SeRestorePrivilege enabled,
# the item's own ACL can't refuse us). SetKernelObjectSecurity writes only that
# one item's descriptor; SetSecurityInfo and SetNamedSecurityInfo would also
# propagate to existing children. Paths use the \\?\
# prefix, so long paths work. Compiles under Windows PowerShell 5.1 (C# 5).

$unlockerSource = @'
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;
using Microsoft.Win32.SafeHandles;

namespace OldWin
{
    public class UnlockResult
    {
        public long Items;
        public long Links;
        public long Bytes;
        public long Errors;
        public List<string> ErrorSamples = new List<string>();
    }

    public class CheckResult
    {
        public long Items;
        public long CantDelete;   // open for DELETE refused: Explorer's delete would fail
        public long CantList;     // folder can't be listed: Explorer can't empty it
        public long TooLong;      // path >= 260 chars: Explorer can't handle it
        public long InUse;        // sharing violation: something has it open
        public long Other;
        // Category -> first few example paths.
        public Dictionary<string, List<string>> Samples = new Dictionary<string, List<string>>();
    }

    public static class Unlocker
    {
        const uint DELETE = 0x00010000;
        const uint WRITE_DAC = 0x00040000;
        const uint WRITE_OWNER = 0x00080000;
        const uint FILE_READ_ATTRIBUTES = 0x0080;
        const uint FILE_WRITE_ATTRIBUTES = 0x0100;
        const uint FILE_SHARE_ALL = 0x7;
        const uint OPEN_EXISTING = 3;
        const uint FILE_FLAG_BACKUP_SEMANTICS = 0x02000000;
        const uint FILE_FLAG_OPEN_REPARSE_POINT = 0x00200000;
        // NtOpenFile options: the same two behaviours as the flags above.
        const uint FILE_OPEN_FOR_BACKUP_INTENT = 0x00004000;
        const uint FILE_OPEN_REPARSE_POINT = 0x00200000;
        const uint OBJ_CASE_INSENSITIVE = 0x40;
        const uint OWNER_SECURITY_INFORMATION = 0x1;
        const uint DACL_SECURITY_INFORMATION = 0x4;
        const uint A_READONLY = 0x1, A_HIDDEN = 0x2, A_SYSTEM = 0x4;
        const uint A_DIRECTORY = 0x10, A_NORMAL = 0x80, A_REPARSE = 0x400;
        // Attributes SetFileInformationByHandle accepts: readonly, hidden,
        // system, archive, temporary, offline, not-content-indexed.
        const uint A_SETTABLE = 0x1 | 0x2 | 0x4 | 0x20 | 0x100 | 0x1000 | 0x2000;
        const uint INVALID_ATTRS = 0xFFFFFFFF;
        const int MaxSamples = 20;

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        struct WIN32_FIND_DATA
        {
            public uint dwFileAttributes;
            public System.Runtime.InteropServices.ComTypes.FILETIME ftCreationTime;
            public System.Runtime.InteropServices.ComTypes.FILETIME ftLastAccessTime;
            public System.Runtime.InteropServices.ComTypes.FILETIME ftLastWriteTime;
            public uint nFileSizeHigh;
            public uint nFileSizeLow;
            public uint dwReserved0;
            public uint dwReserved1;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string cFileName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 14)] public string cAlternateFileName;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct FILE_BASIC_INFO
        {
            public long CreationTime;   // 0 = leave unchanged
            public long LastAccessTime;
            public long LastWriteTime;
            public long ChangeTime;
            public uint FileAttributes;
            public uint Padding;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct UNICODE_STRING { public ushort Length; public ushort MaximumLength; public IntPtr Buffer; }

        [StructLayout(LayoutKind.Sequential)]
        struct OBJECT_ATTRIBUTES
        {
            public int Length;
            public IntPtr RootDirectory;
            public IntPtr ObjectName;
            public uint Attributes;
            public IntPtr SecurityDescriptor;
            public IntPtr SecurityQualityOfService;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct IO_STATUS_BLOCK { public IntPtr Status; public IntPtr Information; }

        [StructLayout(LayoutKind.Sequential)]
        struct LUID { public uint Low; public int High; }

        [StructLayout(LayoutKind.Sequential)]
        struct TOKEN_PRIVILEGES { public uint Count; public LUID Luid; public uint Attributes; }

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        static extern IntPtr FindFirstFileExW(string name, int infoLevel, out WIN32_FIND_DATA data, int searchOp, IntPtr filter, int flags);
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        static extern bool FindNextFileW(IntPtr h, out WIN32_FIND_DATA data);
        [DllImport("kernel32.dll")]
        static extern bool FindClose(IntPtr h);
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        static extern uint GetFileAttributesW(string name);
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        static extern SafeFileHandle CreateFileW(string name, uint access, uint share, IntPtr sa, uint disposition, uint flags, IntPtr template);
        [DllImport("ntdll.dll")]
        static extern int NtOpenFile(out SafeFileHandle h, uint access, ref OBJECT_ATTRIBUTES oa,
                                     out IO_STATUS_BLOCK iosb, uint share, uint options);
        [DllImport("ntdll.dll")]
        static extern int RtlNtStatusToDosError(int status);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool SetFileInformationByHandle(SafeFileHandle h, int infoClass, ref FILE_BASIC_INFO info, uint size);
        // Low-level: writes this one object's descriptor and nothing else.
        // (SetSecurityInfo / SetNamedSecurityInfo propagate to children.)
        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool SetKernelObjectSecurity(SafeFileHandle h, uint securityInfo, byte[] descriptor);
        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool OpenProcessToken(IntPtr process, uint access, out IntPtr token);
        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        static extern bool LookupPrivilegeValueW(string system, string name, out LUID luid);
        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool AdjustTokenPrivileges(IntPtr token, bool disableAll, ref TOKEN_PRIVILEGES state, uint len, IntPtr prev, IntPtr retLen);
        [DllImport("kernel32.dll")]
        static extern IntPtr GetCurrentProcess();
        [DllImport("kernel32.dll")]
        static extern bool CloseHandle(IntPtr h);

        // Turns backup/restore/take-ownership on or off for this process. They
        // stay on for the life of the process, which is the whole PowerShell
        // session when the .ps1 is run directly, so callers turn them off again.
        public static void SetPrivileges(bool enable)
        {
            IntPtr token;
            if (!OpenProcessToken(GetCurrentProcess(), 0x28 /* ADJUST_PRIVILEGES | QUERY */, out token))
                throw new Win32Exception();
            try
            {
                foreach (string name in new[] { "SeBackupPrivilege", "SeRestorePrivilege", "SeTakeOwnershipPrivilege" })
                {
                    TOKEN_PRIVILEGES tp = new TOKEN_PRIVILEGES();
                    tp.Count = 1;
                    tp.Attributes = enable ? 2u : 0u; // SE_PRIVILEGE_ENABLED or disabled
                    if (!LookupPrivilegeValueW(null, name, out tp.Luid)) throw new Win32Exception();
                    if (!AdjustTokenPrivileges(token, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero)) throw new Win32Exception();
                    // ERROR_NOT_ALL_ASSIGNED: the token doesn't hold it. Fatal
                    // when enabling; already off (fine) when disabling.
                    if (enable && Marshal.GetLastWin32Error() == 1300)
                        throw new InvalidOperationException(name + " is not held by this process; run elevated.");
                }
            }
            finally { CloseHandle(token); }
        }

        // Walks path and everything under it, calling visit(path, attributes,
        // size) on each item, the top included. Never descends into a
        // junction or symlink. A folder is listed after it has been visited,
        // so the unlock can grant itself list rights first.
        static void Walk(string path, Action<string, uint, long> visit, Action<string, string, int> fail,
                         Func<long> count, Action<long, string> progress)
        {
            string top = @"\\?\" + path.TrimEnd('\\');
            uint topAttrs = GetFileAttributesW(top);
            if (topAttrs == INVALID_ATTRS) { fail(top, "read attributes", Marshal.GetLastWin32Error()); return; }

            visit(top, topAttrs, 0);
            Stack<string> dirs = new Stack<string>();
            if (IsRealDir(topAttrs)) dirs.Push(top);

            int last = Environment.TickCount;
            while (dirs.Count > 0)
            {
                string dir = dirs.Pop();
                WIN32_FIND_DATA fd;
                // 1 = FindExInfoBasic, 2 = FIND_FIRST_EX_LARGE_FETCH
                IntPtr h = FindFirstFileExW(dir + @"\*", 1, out fd, 0, IntPtr.Zero, 2);
                if (h == new IntPtr(-1)) { fail(dir, "list folder", Marshal.GetLastWin32Error()); continue; }
                try
                {
                    do
                    {
                        string name = fd.cFileName;
                        if (name == "." || name == "..") continue;
                        string child = dir + @"\" + name;
                        uint a = fd.dwFileAttributes;
                        long size = (a & A_DIRECTORY) != 0 ? 0 : ((long)fd.nFileSizeHigh << 32) | fd.nFileSizeLow;
                        visit(child, a, size);
                        if (IsRealDir(a)) dirs.Push(child);

                        if (progress != null && unchecked(Environment.TickCount - last) >= 1000)
                        {
                            last = Environment.TickCount;
                            progress(count(), Display(child));
                        }
                    } while (FindNextFileW(h, out fd));
                }
                finally { FindClose(h); }
            }
        }

        public static UnlockResult Unlock(string path, string userSid, Action<long, string> progress)
        {
            UnlockResult r = new UnlockResult();
            // Self-relative descriptors: owner = user, protected DACL (no
            // inheritance from the parent) granting full control.
            byte[] dirSd  = SdBytes("O:" + userSid + "D:P(A;OICI;FA;;;" + userSid + ")(A;OICI;FA;;;BA)(A;OICI;FA;;;SY)");
            byte[] fileSd = SdBytes("O:" + userSid + "D:P(A;;FA;;;" + userSid + ")(A;;FA;;;BA)(A;;FA;;;SY)");

            Walk(path,
                 (p, a, size) => { Fix(r, p, a, dirSd, fileSd); r.Bytes += size; },
                 (p, stage, err) => Fail(r, p, stage, err),
                 () => r.Items, progress);
            return r;
        }

        // Read-only. Asks Windows to open each item for DELETE, which it grants
        // only if Explorer's delete would pass the permission check (DELETE on
        // the item, or delete-child on its folder), then closes it untouched.
        // Must run WITHOUT EnablePrivileges: with backup/restore privileges on,
        // the open would succeed regardless and the check would mean nothing.
        public static CheckResult Check(string path, Action<long, string> progress)
        {
            CheckResult r = new CheckResult();
            Walk(path,
                 (p, a, size) => Probe(r, p),
                 (p, stage, err) => {
                     if (stage == "list folder" && err == 5) { r.CantList++; Sample(r, "can't list", p); }
                     else { r.Other++; Sample(r, stage + ": " + new Win32Exception(err).Message, p); }
                 },
                 () => r.Items, progress);
            return r;
        }

        static void Probe(CheckResult r, string p)
        {
            r.Items++;
            if (Display(p).Length >= 260) { r.TooLong++; Sample(r, "path too long", p); }
            using (SafeFileHandle h = CreateFileW(p, DELETE, FILE_SHARE_ALL, IntPtr.Zero, OPEN_EXISTING,
                FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OPEN_REPARSE_POINT, IntPtr.Zero))
            {
                if (!h.IsInvalid) return;
                int err = Marshal.GetLastWin32Error();
                if (err == 5)       { r.CantDelete++; Sample(r, "can't delete", p); }
                else if (err == 32) { r.InUse++;      Sample(r, "in use", p); }
                else                { r.Other++;      Sample(r, new Win32Exception(err).Message, p); }
            }
        }

        static void Sample(CheckResult r, string category, string p)
        {
            List<string> list;
            if (!r.Samples.TryGetValue(category, out list)) { list = new List<string>(); r.Samples[category] = list; }
            if (list.Count < 3) list.Add(Display(p));
        }

        static bool IsRealDir(uint a) { return (a & A_DIRECTORY) != 0 && (a & A_REPARSE) == 0; }

        static void Fix(UnlockResult r, string p, uint attrs, byte[] dirSd, byte[] fileSd)
        {
            r.Items++;
            if ((attrs & A_REPARSE) != 0) r.Links++;
            int openErr;
            using (SafeFileHandle h = OpenExact(p, WRITE_DAC | WRITE_OWNER | FILE_READ_ATTRIBUTES | FILE_WRITE_ATTRIBUTES, out openErr))
            {
                if (h == null || h.IsInvalid) { Fail(r, p, "open", openErr); return; }

                byte[] sd = (attrs & A_DIRECTORY) != 0 ? dirSd : fileSd;
                if (!SetKernelObjectSecurity(h, OWNER_SECURITY_INFORMATION | DACL_SECURITY_INFORMATION, sd))
                { Fail(r, p, "set permissions", Marshal.GetLastWin32Error()); return; }

                if ((attrs & (A_READONLY | A_HIDDEN | A_SYSTEM)) != 0)
                {
                    FILE_BASIC_INFO info = new FILE_BASIC_INFO();
                    uint keep = attrs & A_SETTABLE & ~(A_READONLY | A_HIDDEN | A_SYSTEM);
                    info.FileAttributes = keep == 0 ? A_NORMAL : keep;
                    if (!SetFileInformationByHandle(h, 0 /* FileBasicInfo */, ref info, (uint)Marshal.SizeOf(typeof(FILE_BASIC_INFO))))
                        Fail(r, p, "clear flags", Marshal.GetLastWin32Error());
                }
            }
        }

        // Opens with exactly the requested rights. CreateFile always adds
        // SYNCHRONIZE (and FILE_READ_ATTRIBUTES), so a deny rule on those, which
        // icacls' simple rights such as (D) include, would block the open even
        // though we never need them. NtOpenFile asks for only what we pass.
        // Backup intent + reparse point: same as the CreateFile flags.
        static SafeFileHandle OpenExact(string win32Path, uint access, out int error)
        {
            // \\?\J:\x -> \??\J:\x (the NT form of the same path)
            string nt = @"\??\" + win32Path.Substring(4);
            IntPtr buffer = Marshal.StringToHGlobalUni(nt);
            IntPtr name = IntPtr.Zero;
            try
            {
                UNICODE_STRING us = new UNICODE_STRING();
                us.Length = (ushort)(nt.Length * 2);
                us.MaximumLength = (ushort)(nt.Length * 2 + 2);
                us.Buffer = buffer;
                name = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(UNICODE_STRING)));
                Marshal.StructureToPtr(us, name, false);

                OBJECT_ATTRIBUTES oa = new OBJECT_ATTRIBUTES();
                oa.Length = Marshal.SizeOf(typeof(OBJECT_ATTRIBUTES));
                oa.ObjectName = name;
                oa.Attributes = OBJ_CASE_INSENSITIVE;

                SafeFileHandle h;
                IO_STATUS_BLOCK iosb;
                int status = NtOpenFile(out h, access, ref oa, out iosb, FILE_SHARE_ALL,
                                        FILE_OPEN_FOR_BACKUP_INTENT | FILE_OPEN_REPARSE_POINT);
                error = status < 0 ? RtlNtStatusToDosError(status) : 0;
                return h;
            }
            finally
            {
                if (name != IntPtr.Zero) Marshal.FreeHGlobal(name);
                Marshal.FreeHGlobal(buffer);
            }
        }

        static void Fail(UnlockResult r, string p, string stage, int code)
        {
            r.Errors++;
            if (r.ErrorSamples.Count < MaxSamples)
                r.ErrorSamples.Add(Display(p) + ": " + stage + ": " + new Win32Exception(code).Message);
        }

        static string Display(string p) { return p.StartsWith(@"\\?\") ? p.Substring(4) : p; }

        static byte[] SdBytes(string sddl)
        {
            RawSecurityDescriptor sd = new RawSecurityDescriptor(sddl);
            byte[] b = new byte[sd.BinaryLength];
            sd.GetBinaryForm(b, 0);
            return b;
        }
    }
}
'@

# A compiled type can't be replaced inside a running PowerShell, and running
# the .ps1 directly runs it in your session. Name the namespace after a hash
# of the source, so an edited script compiles a fresh copy instead of calling
# the stale one an earlier run left behind.
$sourceHash = [Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($unlockerSource))
$namespace  = 'OldWin_' + (-join ($sourceHash[0..5] | ForEach-Object { $_.ToString('x2') }))
$Unlocker   = "$namespace.Unlocker" -as [type]
if (-not $Unlocker) {
    Add-Type -Language CSharp -TypeDefinition ($unlockerSource -replace '(?m)^namespace OldWin\s*$', "namespace $namespace")
    $Unlocker = [type]"$namespace.Unlocker"
}

# --- Safety checks -----------------------------------------------------------

$letter = $Drive.Substring(0, 1).ToUpper()
$root   = "${letter}:\"

if ("${letter}:" -ieq $env:SystemDrive) {
    throw "Refusing to run on the system drive ($env:SystemDrive)."
}
$vol = Get-Volume -DriveLetter $letter -ErrorAction SilentlyContinue
if (-not $vol)                  { throw "Drive ${letter}: not found." }
if ($vol.FileSystem -ne 'NTFS') { throw "Drive ${letter}: is $($vol.FileSystem), expected NTFS." }

$me      = [Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = ([Security.Principal.WindowsPrincipal]$me).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# --- Things the current Windows is still using -------------------------------

$skip = @{}

# On BIOS/MBR machines with several disks, a Windows installed on a second disk
# often keeps booting through bootmgr on the first (old) disk. Leave boot files
# alone on a system or active partition.
$sysVol = Get-CimInstance Win32_Volume -Filter "DriveLetter='${letter}:'" -ErrorAction SilentlyContinue
$part   = Get-Partition -DriveLetter $letter -ErrorAction SilentlyContinue
$bootReason = $null
if ($sysVol -and $sysVol.SystemVolume)  { $bootReason = 'system volume (boot files in use)' }
elseif ($part -and $part.IsSystem)      { $bootReason = 'system partition (boot files in use)' }
elseif ($part -and $part.IsActive)      { $bootReason = 'active partition (BIOS may boot from it)' }
if ($bootReason) { foreach ($f in $BootItems) { $skip[$f] = $bootReason } }

$pageFiles = @(Get-CimInstance Win32_PageFileUsage | Where-Object { $_.Name -like "${letter}:\*" })
if ($pageFiles.Count) {
    $skip['pagefile.sys'] = 'active page file'
    $skip['swapfile.sys'] = 'active page file'
}

$storeReason = $null
if (Test-Path -LiteralPath (Join-Path $root "WpSystem\$($me.User.Value)")) {
    $storeReason = 'current user has Store app data here'
} else {
    try {
        if ($PSVersionTable.PSEdition -eq 'Core') {
            Import-Module Appx -UseWindowsPowerShell -WarningAction SilentlyContinue
        }
        $appxVol = Get-AppxVolume |
            Where-Object { $_.PackageStorePath -like "${letter}:\*" } |
            Select-Object -First 1
        if ($appxVol) {
            $storeReason = 'Store/Xbox apps install here'
        } else {
            $onDrive = Get-AppxPackage -AllUsers |
                Where-Object { $_.InstallLocation -like "${letter}:\*" } |
                Select-Object -First 1
            if ($onDrive) { $storeReason = "Store app installed here ($($onDrive.Name))" }
        }
    } catch {
        Write-Warning "Couldn't query Store apps ($($_.Exception.Message)); leaving $($StoreFolders -join ', ') alone."
        $storeReason = 'Store app check failed'
    }
}
if ($storeReason) { foreach ($f in $StoreFolders) { $skip[$f] = $storeReason } }

# The top-level name on this drive that a path lives under, or $null.
function Get-TopName([string]$Path) {
    if (-not $Path) { return $null }
    $p = ($Path.Trim().Trim('"') -replace '^\\\\\?\\', '') -replace '/', '\'
    if ($p -notlike "${letter}:\?*") { return $null }
    $p.Substring(3).Split('\')[0]
}
function Add-InUse([string]$Path, [string]$Reason) {
    $top = Get-TopName $Path
    if ($top -and -not $skip.ContainsKey($top)) { $skip[$top] = $Reason }
}

# Steam libraries. libraryfolders.vdf lines look like: "path"  "J:\\SteamLibrary"
try {
    $steamKey = Get-Item 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue
    $steamDir = if ($steamKey) { $steamKey.GetValue('SteamPath') } else { $null }
    if ($steamDir) {
        $vdf = Join-Path $steamDir 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
                Add-InUse ($m.Groups[1].Value -replace '\\\\', '\') 'Steam library'
            }
        }
    }
} catch {
    Write-Warning "Couldn't read Steam's library list ($($_.Exception.Message))."
}

# WSL distros registered to this account.
foreach ($k in @(Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' -ErrorAction SilentlyContinue)) {
    Add-InUse $k.GetValue('BasePath') "WSL distro '$($k.GetValue('DistributionName'))'"
}

# Services and running programs that live on the drive.
foreach ($svc in @(Get-CimInstance Win32_Service)) {
    if ($svc.PathName -and $svc.PathName -match '^\s*"?([A-Za-z]:\\[^"]*?\.(exe|dll|sys))') {
        Add-InUse $Matches[1] "service '$($svc.Name)'"
    }
}
foreach ($proc in @(Get-Process -ErrorAction SilentlyContinue)) {
    $exe = $null
    try { $exe = $proc.Path } catch { }
    if ($exe) { Add-InUse $exe "running: $($proc.ProcessName)" }
}

# Stop with a plain red message rather than a PowerShell error record.
function Stop-Script([string]$Message) {
    Write-Host $Message -ForegroundColor Red
    exit 1
}

# --- Build the plan ----------------------------------------------------------

$WhatIfPreference = $savedWhatIf

function ConvertTo-Target($Item) {
    $isLink = [bool]($Item.Attributes -band [IO.FileAttributes]::ReparsePoint)
    [pscustomobject]@{
        Name  = $Item.Name
        Kind  = if ($isLink) { 'Link' } elseif ($Item.PSIsContainer) { 'Folder' } else { 'File' }
        IsDir = [bool]$Item.PSIsContainer
        Path  = $Item.FullName
    }
}

function Get-Description([string]$ItemName) {
    if ($skip.ContainsKey($ItemName))         { return "in use: $($skip[$ItemName])" }
    if ($Descriptions.ContainsKey($ItemName)) { return $Descriptions[$ItemName] }
    if ($ItemName -match '^Python\d+$')       { return 'a Python install (python.org installer)' }
    ''
}

$onRoot   = @(Get-ChildItem -LiteralPath $root -Force | Where-Object { $_.Name -notin $Protected })
$volLabel = if ($vol.FileSystemLabel) { " ($($vol.FileSystemLabel))" } else { '' }
$names    = @($Name | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })

if ($Delete -and $Check) {
    Stop-Script '-Check and -Delete can''t be combined.'
}
if ($Delete -and -not $names.Count) {
    Stop-Script "-Delete needs the names to delete, e.g.: unlock-oldwin ${letter}: Windows -Delete"
}

# No names, no -Check: the "locked" listing. It tests Explorer after you
# click Continue, which only an elevated token can stand in for.
$listLocked = -not $names.Count -and -not $Check -and -not $Delete
if ($listLocked -and -not $isAdmin) {
    Stop-Script ("Listing locked folders tests Explorer after its Continue prompt, which needs an elevated terminal`n" +
                 "(Win+X, then Terminal (Admin)). Unelevated, this shows what's locked for you as-is: unlock-oldwin ${letter}: -Check")
}

# --- Names: validate ---------------------------------------------------------

$targets = [Collections.Generic.List[object]]::new()
$seen    = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($n in $names) {
    if (-not $seen.Add($n)) { continue }
    if ($n -match '[\\/:*?"<>|]' -or $n -in '.', '..') { Stop-Script "Invalid name '$n' (top-level names only, no paths)." }
    if ($n -in $Protected)     { Stop-Script "Refusing '$n': protected system folder." }
    # -Check only reads, so in-use items may be checked.
    if ($skip.ContainsKey($n) -and -not $Check) { Stop-Script "Refusing '$n': in use ($($skip[$n]))." }
    $item = $onRoot | Where-Object { $_.Name -ieq $n } | Select-Object -First 1
    if (-not $item) { Stop-Script "'$n' not found on ${letter}:." }
    $t = ConvertTo-Target $item
    $t | Add-Member -NotePropertyName Description -NotePropertyValue (Get-Description $t.Name)
    $targets.Add($t)
}

# No names (the listing, or -Check): everything that isn't in use.
if (-not $names.Count) {
    foreach ($item in $onRoot) {
        if ($skip.ContainsKey($item.Name)) { continue }
        $t = ConvertTo-Target $item
        $t | Add-Member -NotePropertyName Description -NotePropertyValue (Get-Description $t.Name)
        $targets.Add($t)
    }
}

# --- Check what Explorer would fail to delete (read-only) --------------------

# Walks each target and returns one row per target. With -Detailed, also
# prints a line per target with example paths as it goes.
function Invoke-Check($Targets, [switch]$Detailed) {
    # Backup/restore privileges would make every probe succeed. They're off
    # by default, but an unlock earlier in this PowerShell session leaves them on.
    $Unlocker::SetPrivileges($false)

    $activity = "Checking ${letter}:"
    $timer    = [Diagnostics.Stopwatch]::StartNew()
    $rows     = [Collections.Generic.List[object]]::new()
    try {
        for ($i = 0; $i -lt $Targets.Count; $i++) {
            $t      = $Targets[$i]
            $pct    = [int](100 * $i / $Targets.Count)
            $status = '[{0}/{1}] {2}' -f ($i + 1), $Targets.Count, $t.Path
            Write-Progress -Activity $activity -Status $status -PercentComplete $pct
            $onProgress = [Action[long, string]] {
                param($n, $p)
                Write-Progress -Activity $activity -Status ('{0}  ({1:N0} items, {2} elapsed)' -f $status, $n, (Format-Elapsed $timer.Elapsed)) `
                    -CurrentOperation $p -PercentComplete $pct
            }

            $sw = [Diagnostics.Stopwatch]::StartNew()
            $r  = $Unlocker::Check($t.Path, $onProgress)

            # -Delete (robocopy in backup mode) ignores permissions too, so
            # long paths decide it whatever else is wrong.
            $verdict = if ($r.TooLong)                        { 'use -Delete (paths too long for Explorer)' }
                       elseif ($r.CantDelete -or $r.CantList) { 'unlock first' }
                       elseif ($r.InUse)                      { 'files in use' }
                       elseif ($r.Other)                      { 'errors, see -Check' }
                       else                                   { 'Explorer can delete' }

            if ($Detailed) {
                Write-Host ('[{0}/{1}] {2}: {3:N0} items; {4:N0} can''t delete, {5:N0} can''t list, {6:N0} too long ({7})' -f
                    ($i + 1), $Targets.Count, $t.Name, $r.Items, $r.CantDelete, $r.CantList, $r.TooLong, (Format-Elapsed $sw.Elapsed))
                foreach ($cat in $r.Samples.Keys) {
                    foreach ($p in $r.Samples[$cat]) { Write-Host ("        {0,-14} {1}" -f $cat, $p) -ForegroundColor DarkGray }
                }
                $color = if ($verdict -eq 'Explorer can delete') { 'Green' } else { 'Yellow' }
                Write-Host "        -> $verdict" -ForegroundColor $color
            }

            $rows.Add([pscustomobject]@{
                Name = $t.Name; Kind = $t.Kind; Items = $r.Items
                "Can't delete" = $r.CantDelete; "Can't list" = $r.CantList; 'Too long' = $r.TooLong
                Verdict = $verdict; Description = $t.Description
            })
        }
    } finally {
        Write-Progress -Activity $activity -Completed
    }
    [pscustomobject]@{ Rows = $rows; Elapsed = $timer.Elapsed }
}

if ($listLocked) {
    Write-Host "`nLooking for locked items on ${letter}:$volLabel (what Explorer can't delete, even after Continue)" -ForegroundColor Cyan
    Write-Host 'Read-only: nothing is changed. In-use items are skipped.' -ForegroundColor DarkGray
    $result = Invoke-Check $targets
    $locked = @($result.Rows | Where-Object { $_.Verdict -ne 'Explorer can delete' })

    if (-not $locked.Count) {
        Write-Host "`nNothing locked: Explorer can delete everything that isn't in use. ($(Format-Elapsed $result.Elapsed))" -ForegroundColor Green
        return
    }
    $locked | ForEach-Object {
        [pscustomobject]@{
            Name = $_.Name; Kind = $_.Kind
            # A folder can be both undeletable and unlistable, so the two
            # aren't summed. Unlistable folders hide what's inside them.
            Locked = ('{0:N0} of {1:N0}' -f $_."Can't delete", $_.Items) +
                     $(if ($_."Can't list") { ' (+{0:N0} unlistable)' -f $_."Can't list" } else { '' })
            Description = $_.Description
        }
    } | Format-Table -AutoSize | Out-Host

    $tooLong = @($locked | Where-Object { $_.'Too long' })
    if ($tooLong.Count) {
        Write-Host ("Paths too long for Explorer in: {0}. Use -Delete for those." -f (($tooLong | ForEach-Object { $_.Name }) -join ', ')) -ForegroundColor Yellow
    }
    Write-Host "Checked in $(Format-Elapsed $result.Elapsed). To unlock, name what you want, e.g.:"
    # Single quotes: in PowerShell, "$GetCurrent" would expand as a variable.
    Write-Host ("  unlock-oldwin {0}: '{1}'" -f $letter, (($locked | ForEach-Object { $_.Name }) -join ','))
    Write-Host 'Per-folder detail with example paths: add -Check'
    return
}

if ($Check) {
    $who = if ($isAdmin) {
        'an elevated Explorer delete (after you click Continue)'
    } else {
        "Explorer as $($me.Name), before any Continue prompt (run elevated to test after Continue)"
    }
    Write-Host "`nChecking ${letter}:$volLabel for $who" -ForegroundColor Cyan
    Write-Host 'Read-only: nothing is changed.' -ForegroundColor DarkGray
    $result = Invoke-Check $targets -Detailed
    Write-Host "`nSummary ($(Format-Elapsed $result.Elapsed))" -ForegroundColor Cyan
    $result.Rows | Format-Table Name, Items, "Can't delete", "Can't list", 'Too long', Verdict, Description -AutoSize | Out-Host
    return
}

if (-not $isAdmin -and -not $WhatIfPreference) {
    Stop-Script 'Unlocking and deleting need an elevated terminal (Win+X, then Terminal (Admin)).'
}

# --- Report ------------------------------------------------------------------

if ($Delete) {
    Write-Host "`nTo delete from ${letter}:$volLabel" -ForegroundColor Cyan
} else {
    Write-Host "`nTo unlock on ${letter}:$volLabel (owner and full control: $($me.Name))" -ForegroundColor Cyan
}
$targets | Format-Table Name, Kind, Description -AutoSize | Out-Host

if (-not $WhatIfPreference -and -not $Force) {
    $question = if ($Delete) {
        "Delete the items above from ${letter}:? Type YES to continue"
    } else {
        "Take ownership of everything above and replace its permissions? Type YES to continue"
    }
    if ((Read-Host $question) -cne 'YES') {
        Write-Host 'Aborted.'
        return
    }
}

if (-not $WhatIfPreference) { $Unlocker::SetPrivileges($true) }

$allTimer   = [Diagnostics.Stopwatch]::StartNew()
$freeBefore = $vol.SizeRemaining

# --- Unlock ------------------------------------------------------------------

if (-not $Delete) {
    $activity = "Unlocking ${letter}:"
    $sid      = $me.User.Value
    $sum      = @{ Items = [long]0; Errors = [long]0 }
    try {
        for ($i = 0; $i -lt $targets.Count; $i++) {
            $t = $targets[$i]
            if (-not $PSCmdlet.ShouldProcess($t.Path, 'Take ownership and grant full control')) { continue }

            $pct    = [int](100 * $i / $targets.Count)
            $status = '[{0}/{1}] {2}' -f ($i + 1), $targets.Count, $t.Path
            Write-Progress -Activity $activity -Status $status -PercentComplete $pct
            Write-Host ('[{0}/{1}] Unlocking {2}' -f ($i + 1), $targets.Count, $t.Path)

            # Called about once a second from inside the walk, on this thread.
            $onProgress = [Action[long, string]] {
                param($n, $p)
                Write-Progress -Activity $activity -Status ('{0}  ({1:N0} items, {2} elapsed)' -f $status, $n, (Format-Elapsed $allTimer.Elapsed)) `
                    -CurrentOperation $p -PercentComplete $pct
            }

            $sw = [Diagnostics.Stopwatch]::StartNew()
            $r  = $Unlocker::Unlock($t.Path, $sid, $onProgress)
            $sum.Items  += $r.Items
            $sum.Errors += $r.Errors

            $color = if ($r.Errors) { 'Yellow' } else { 'DarkGray' }
            Write-Host ('        {0:N0} items ({1}), {2:N0} links, {3:N0} errors in {4}' -f
                $r.Items, (Format-Bytes $r.Bytes), $r.Links, $r.Errors, (Format-Elapsed $sw.Elapsed)) -ForegroundColor $color
            foreach ($e in $r.ErrorSamples) { Write-Warning "  $e" }
            if ($r.Errors -gt $r.ErrorSamples.Count) {
                Write-Warning ('  ... and {0:N0} more' -f ($r.Errors - $r.ErrorSamples.Count))
            }
        }
    } finally {
        Write-Progress -Activity $activity -Completed
        $Unlocker::SetPrivileges($false)
    }

    if (-not $WhatIfPreference) {
        Write-Host ("`nDone in {0}. Unlocked {1:N0} items with {2:N0} errors." -f
            (Format-Elapsed $allTimer.Elapsed), $sum.Items, $sum.Errors) -ForegroundColor Green
        Write-Host "Delete what you want in Explorer. For anything it can't remove, run: unlock-oldwin ${letter}: <name> -Delete"
    }
    return
}

# --- Delete ------------------------------------------------------------------

$activity = "Deleting from ${letter}:"
$empty = Join-Path ([IO.Path]::GetTempPath()) ('empty-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $empty -WhatIf:$false | Out-Null

try {
    for ($i = 0; $i -lt $targets.Count; $i++) {
        $t = $targets[$i]
        if (-not $PSCmdlet.ShouldProcess($t.Path, 'Delete')) { continue }
        Write-Progress -Activity $activity `
            -Status ('[{0}/{1}] {2}  ({3} elapsed)' -f ($i + 1), $targets.Count, $t.Path, (Format-Elapsed $allTimer.Elapsed)) `
            -PercentComplete ([int](100 * $i / $targets.Count))
        Write-Host ('[{0}/{1}] Removing {2}' -f ($i + 1), $targets.Count, $t.Path)
        $sw = [Diagnostics.Stopwatch]::StartNew()
        try {
            switch ($t.Kind) {
                'Folder' {
                    # Backup mode ignores ACLs; /XJ never descends into junctions.
                    & robocopy.exe $empty $t.Path /MIR /B /XJ /R:0 /W:0 /NFL /NDL /NJH /NJS /NP | Out-Null
                    if ($LASTEXITCODE -ge 8) {
                        Write-Warning "  robocopy hit errors (exit $LASTEXITCODE); some files may be locked"
                    }
                    # rmdir /s removes leftover junctions as links, never their targets.
                    & cmd.exe /d /c rmdir /s /q $t.Path
                }
                'Link' {
                    # Never Remove-Item a directory junction: Windows PowerShell
                    # can recurse into its target.
                    if ($t.IsDir) { & cmd.exe /d /c rmdir $t.Path }
                    else          { Remove-Item -LiteralPath $t.Path -Force -Confirm:$false }
                }
                'File' {
                    [void]$Unlocker::Unlock($t.Path, $me.User.Value, $null)
                    Remove-Item -LiteralPath $t.Path -Force -Confirm:$false
                }
            }
        } catch {
            Write-Warning "  $($_.Exception.Message)"
        }
        if (Test-Path -LiteralPath $t.Path) {
            Write-Warning '  still present; something may have it open (a reboot usually clears this)'
        }
        $freedSoFar = (Get-Volume -DriveLetter $letter).SizeRemaining - $freeBefore
        Write-Host ('        done in {0}; {1} freed so far' -f (Format-Elapsed $sw.Elapsed), (Format-Bytes $freedSoFar)) -ForegroundColor DarkGray
    }
} finally {
    Write-Progress -Activity $activity -Completed
    $Unlocker::SetPrivileges($false)
    Remove-Item -LiteralPath $empty -Force -WhatIf:$false -Confirm:$false -ErrorAction SilentlyContinue
}

if (-not $WhatIfPreference) {
    $freed = (Get-Volume -DriveLetter $letter).SizeRemaining - $freeBefore
    Write-Host ("`nDone in {0}. Freed {1} on {2}:" -f (Format-Elapsed $allTimer.Elapsed), (Format-Bytes $freed), $letter) -ForegroundColor Green
}
