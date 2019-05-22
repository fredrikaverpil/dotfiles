# Import modules
# See modules paths with command: $env:PSModulePath
Import-Module PSColor  # https://github.com/Davlind/PSColor
Import-Module posh-git  # https://github.com/dahlbyk/posh-git

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
  } elseif ($dt.Seconds -lt 1) {
    return "(" + "$($dt.Milliseconds.toString())ms)"
  } else {
    return "(" + "$($dt.Seconds.toString())s, $($dt.Milliseconds.toString())ms)"
  }
}

function last_exit_code([int]$code) {
  if ($code -eq 0) {
    return Write-Prompt "0" -ForegroundColor "#bdd7a6"
  } else {
    return Write-Prompt "$($code)" -ForegroundColor "#ee8e96"
  }

}

function path_shortener([string]$path) {
  if ($path.StartsWith("$($HOME)")) {
    $path = $path.Replace("$($HOME)", "~")
  }
  return $path
}

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
# $GitPromptSettings.DefaultPromptBeforeSuffix.Text = '`n'
# $GitPromptSettings.DefaultPromptPrefix = '$(last_cmd_time) `n'
# $GitPromptSettings.DefaultPromptPath.ForegroundColor = 0xFFA500

function prompt {
  $origLastExitCode = $LASTEXITCODE

  $prompt = ""

  $prompt += Write-Prompt "$(last_exit_code($origLastExitCode)) "
  $prompt += Write-Prompt "$(last_cmd_time) `n"
  $prompt += Write-Prompt "$($env:username)@$($env:computername) " -Foreground "#bdd7a6"

  # $prompt += & $GitPromptScriptBlock

  $prompt += Write-Prompt "$(path_shortener($ExecutionContext.SessionState.Path.CurrentLocation))" -ForegroundColor "#b0c3d4"
  $prompt += Write-VcsStatus
  $prompt += Write-Prompt "$(if ($PsDebugContext) {' [DBG]: '} else {''})" -ForegroundColor Magenta
  $prompt += "`n$('>' * ($nestedPromptLevel + 1)) "

  $LASTEXITCODE = $origLastExitCode
  $prompt
}