param(
    [Parameter(Mandatory = $true)]
    [string]$IdleRunnerExe
)

$ErrorActionPreference = 'Stop'
$autoItRoot = 'C:\Program Files (x86)\AutoIt3'
$compiler = Join-Path $autoItRoot 'Aut2Exe\Aut2exe_x64.exe'
$stubSource = Join-Path $PSScriptRoot 'UpdaterHealthStub.au3'
$testRoot = Join-Path $env:TEMP 'Idle Runner Updater Integration'
$installDir = Join-Path $testRoot 'Install With Spaces'
$workDir = Join-Path $testRoot 'Downloaded Update'

Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $installDir, $workDir | Out-Null

$target = Join-Path $installDir 'Idle Runner Test.exe'
$download = Join-Path $workDir 'Idle Runner Download.exe'
$backup = "$target.update-backup"
$signal = Join-Path $workDir 'startup.ready'
$helper = Join-Path $workDir 'Idle Runner Updater.exe'

Copy-Item -LiteralPath "$env:WINDIR\System32\where.exe" -Destination $target
& $compiler /in $stubSource /out $download /nopack
for ($attempt = 0; $attempt -lt 40 -and -not (Test-Path -LiteralPath $download); $attempt++) {
    Start-Sleep -Milliseconds 250
}
if (-not (Test-Path -LiteralPath $download)) {
    throw 'Could not compile the updater health stub.'
}
Copy-Item -LiteralPath $IdleRunnerExe -Destination $helper

$process = Start-Process -FilePath $helper -ArgumentList @(
    '--apply-update',
    ('"{0}"' -f $target),
    ('"{0}"' -f $download),
    ('"{0}"' -f $backup),
    ('"{0}"' -f $signal),
    '999999',
    '""'
) -WorkingDirectory $workDir -PassThru -Wait

if ($process.ExitCode -ne 0) { throw "Updater helper exited with $($process.ExitCode)." }
if (-not (Test-Path -LiteralPath $signal)) { throw 'Updated executable did not produce its health signal.' }
if (Test-Path -LiteralPath $backup) { throw 'Backup was not removed after a healthy startup.' }

$reportedWorkingDir = Get-Content -LiteralPath $signal -Raw
if ($reportedWorkingDir -ne $installDir) {
    throw "Updated executable started in '$reportedWorkingDir' instead of '$installDir'."
}

Write-Output 'PASSED: updater replacement, spaced paths, restart, and health signal'
Remove-Item -LiteralPath $testRoot -Recurse -Force
