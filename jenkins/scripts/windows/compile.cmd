:: Use Python 2 up to Node 12
if %NODEJS_MAJOR_VERSION% leq 12 set "PATH=C:\Python27\;C:\Python27\Scripts;%PATH%"

:: Opt-in for a generating binlog (work with code has https://github.com/nodejs/node/pull/26431/files)
set "msbuild_args=/binaryLogger:node.binlog"

:: Opt-in for a clcache
if not defined DISABLE_CLCACHE if exist C:\clcache\dist\clcache_main\clcache_main.exe (
  set CLCACHE_OBJECT_CACHE_TIMEOUT_MS=60000
  set CLCACHE_BASEDIR="%WORKSPACE%"
  set CLCACHE_HARDLINK=1
  set "msbuild_args=%msbuild_args% /p:CLToolExe=clcache_main.exe /p:CLToolPath=C:\clcache\dist\clcache_main"
  :: multiproc msbuild doesn't play nice with clcache
  set NUMBER_OF_PROCESSORS=1
  :: Ensure cache size
  C:\clcache\dist\clcache_main\clcache_main.exe -M 20000000000
  C:\clcache\dist\clcache_main\clcache_main.exe -s
)

:: Call vcbuild
if "%nodes:~-6%" == "-arm64" (
  :: Building MSI is not yet supported for ARM64 with WiX 3.
  :: Since PR with WiX 4 migration changed folder structure,
  :: this check can determine which WiX is used for the MSI.
  :: Refs: https://github.com/nodejs/node/pull/45943
  if exist tools\msvs\msi\nodemsi.wixproj (
    :: WiX 3 - doesn't build ARM64 MSI
    set "VCBUILD_EXTRA_ARGS=arm64 release"
  ) else (
    :: WiX 4 - builds ARM64 MSI
    set "VCBUILD_EXTRA_ARGS=arm64 %VCBUILD_EXTRA_ARGS%"
  )
) else if "%nodes:~-4%" == "-x86" (
  set "VCBUILD_EXTRA_ARGS=x86 %VCBUILD_EXTRA_ARGS%"
) else (
  set "VCBUILD_EXTRA_ARGS=x64 %VCBUILD_EXTRA_ARGS%"
)
set DEBUG_HELPER=1
call vcbuild.bat %VCBUILD_EXTRA_ARGS%
if errorlevel 1 exit /b
:: echo back on after vcbuild
echo on
