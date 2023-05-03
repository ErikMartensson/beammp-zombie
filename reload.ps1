
if ($args.Count -lt 1) {
  Write-Error "Usage: reload.ps1 <beammpServerPath>"
  exit
}

$ServerPath = $args[0]

if ($ServerPath.EndsWith("\") -or $ServerPath.EndsWith("/")) {
  $ServerPath = $ServerPath.Substring(0, $ServerPath.Length - 1)
}

$ServerPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
  $ServerPath
)
if (!(Test-Path $ServerPath)) {
  Write-Error "BeamMP server path does not exist: $ServerPath"
  exit
}

$ModClientSourcePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
  ".\client"
)
if (!(Test-Path $ModClientSourcePath)) {
  Write-Error "Mod client path does not exist: $ModClientSourcePath"
  exit
}

$ModServerSourcePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
  ".\server"
)
if (!(Test-Path $ModServerSourcePath)) {
  Write-Error "Mod server path does not exist: $ModServerSourcePath"
  exit
}

# Watcher stuff
$Watcher = New-Object System.IO.FileSystemWatcher
$Watcher.Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(".\")
$Watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite,
  [System.IO.NotifyFilters]::FileName,
  [System.IO.NotifyFilters]::DirectoryName
$Watcher.Filter = "*.lua"
$Watcher.IncludeSubdirectories = $true
$Watcher.EnableRaisingEvents = $true

$ChangeTypes = [System.IO.WatcherChangeTypes]::Created,
  [System.IO.WatcherChangeTypes]::Changed,
  [System.IO.WatcherChangeTypes]::Deleted
$WatcherTimeout = 1000
$CopyTimeout = 2000
$LastChange = [DateTime]::MinValue

function Invoke-SomeAction {
  param (
    [Parameter(Mandatory)]
    [System.IO.WaitForChangedResult]
    $ChangeInformation
  )

  Write-Host "File updated: $($ChangeInformation.Name)" -ForegroundColor Green

  # Zip contents of mod folder and overwrite existing zip file
  $zip = "$ServerPath\Resources\Client\Zombie.zip"
  7z a -tzip $zip "$ModClientSourcePath\*"

  Write-Host "Sucessfully updated client mod" -ForegroundColor Magenta

  $ModServerDestination = "$ServerPath\Resources\Server\Zombie"
  if (!(Test-Path -PathType container $ModServerDestination)) {
    New-Item -ItemType Directory -Force -Path $ModServerDestination
  }
  Copy-Item -Path "$ModServerSourcePath\*" -Destination $ModServerDestination -Recurse

  try {
    # Kill and restart server process
    $processes = Get-Process BeamMP-Server
    Write-host "Killing all processes for BeamMP-Server"
    foreach ($process in $processes) {
      write-host "killing: " + $process.MainWindowTitle
      $process.Kill()
      $process.WaitForExit()
    }
  } catch {
    Write-Error $_
  }

  # Start-Process -FilePath "$ServerPath\BeamMP-Server.exe"
  Start-Process cmd -ArgumentList /c, "$ServerPath\BeamMP-Server.exe" -WorkingDirectory $ServerPath
}

try {
  Write-Host "Watching for changes..." -ForegroundColor DarkYellow
  while ($true) {
    $change = $Watcher.WaitForChanged($ChangeTypes, $WatcherTimeout)
    if ($change.TimedOut) {
      continue
    }

    # Wait a few seconds until we can copy the files again
    if ([DateTime]::Now - $LastChange -lt [TimeSpan]::FromMilliseconds($CopyTimeout)) {
      Write-Host "Waiting for changes to finish..." -ForegroundColor DarkYellow
      Start-Sleep -Milliseconds $CopyTimeout
      Invoke-SomeAction $change
      continue
    }

    $LastChange = [DateTime]::Now
    Invoke-SomeAction $change
  }
} catch {
  Write-Error $_
}
