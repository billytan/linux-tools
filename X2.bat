@echo off

set HOST=kaveri

set DEST_DIR=/home/billy/working

call C:\bin\X.bat %HOST% %DEST_DIR%               ../debian-repo-tools/common.tcl
call C:\bin\X.bat %HOST% %DEST_DIR%               ../debian-repo-tools/common-tests.tcl

call C:\bin\X.bat %HOST% %DEST_DIR%               DebianAutoBuilder.tcl
call C:\bin\X.bat %HOST% %DEST_DIR%               DebianAutoBuilder-tests.tcl

call C:\bin\X.bat %HOST% %DEST_DIR%               scripts/init-chroot.sh
call C:\bin\X.bat %HOST% %DEST_DIR%               scripts/builder-keygen.sh

REM call C:\bin\X.bat %HOST% %DEST_DIR%               scripts/do-sbuild-tests.sh

call C:\bin\X.bat %HOST% %DEST_DIR%               scripts/sbuild.conf


call C:\bin\X.bat %HOST% %DEST_DIR%               do-chroot.sh

exit /B

call C:\bin\X.bat %HOST% %DEST_DIR%               ../bin/Linux64_kbsmk8.6-cli




