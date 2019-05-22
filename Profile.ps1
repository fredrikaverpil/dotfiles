# Aliases
# New-Alias -Name ll -Value ls

# List all files and folders including hidden ones using "ll" function
function ll {
  Get-ChildItem -Force @args
}

function last_cmd_time {
  $command = Get-History -Count 1
  $dt = $command.EndExecutionTime - $command.StartExecutionTime

  if (!$command) {
    return ""
  } elseif ($dt.Milliseconds -lt 1000000) {
    return "(" + "$($dt.Milliseconds.toString())ms)"
  } else {
    return "(" + "$($dt.Seconds.toString())s)"
  }
}

function last_exit_code {
  #$global:LASTEXITCODE = $origLastExitCode
  if ($global:LASTEXITCODE = 0) {
    return "NO"
  } else {
    return "SUCCESS"
  }
}

# Import modules
# See modules paths with command: $env:PSModulePath
Import-Module PSColor  # https://github.com/Davlind/PSColor
Import-Module posh-git  # https://github.com/dahlbyk/posh-git

# PSColor settings
$global:PSColor.File.Executable.Color = 'Blue'  # Set blue color for executables (instead of red)

# Built-in, default PowerShell prompt
# function prompt {
#   "PS $($ExecutionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
# }

# Custom Posh-Git prompt
# https://github.com/dahlbyk/posh-git/wiki/Customizing-Your-PowerShell-Prompt
#
# v0.x
# $GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
# $GitPromptSettings.AfterText += "`n"
#
# v1.x
$GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
$GitPromptSettings.DefaultPromptBeforeSuffix.Text = '`n'
$GitPromptSettings.DefaultPromptPrefix = '$(last_cmd_time) `n'
$GitPromptSettings.DefaultPromptPath.ForegroundColor = 0xFFA500
