setlocal shiftwidth=2
setlocal softtabstop=2
setlocal tabstop=2

setlocal makeprg=jslint\ %
setlocal errorformat=%-P%f,
                    \%-G/*jslint\ %.%#*/,
                    \%*[\ ]%n\ %l\\,%c:\ %m,
                    \%-G\ \ \ \ %.%#,
                    \%-GNo\ errors\ found.,
                    \%-Q
