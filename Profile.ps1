# Import modules
# See modules paths with command: $env:PSModulePath
Import-Module PSColor  # https://github.com/Davlind/PSColor
Import-Module Posh-Git  # https://github.com/dahlbyk/posh-git

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

function is_administrator
{
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

function prompt_state {
  if ($PsDebugContext) {
    '[DBG] '
  } elseif (is_administrator) {
    '[ADMIN] '
  }
  else {
    ''
  }
}

# Custom prompt, requires Posh-Git
function prompt {
  $origLastExitCode = $LASTEXITCODE

  $prompt = ""
  $prompt += Write-Prompt "$(last_exit_code($origLastExitCode)) "
  $prompt += Write-Prompt "$(last_cmd_time) `n"
  $prompt += Write-Prompt "$($env:username)@$($env:computername) " -Foreground "#bdd7a6"
  $prompt += Write-Prompt "$(prompt_state)" -ForegroundColor "#fc88ca"
  # $prompt += & $GitPromptScriptBlock
  $prompt += Write-Prompt "$(path_shortener($ExecutionContext.SessionState.Path.CurrentLocation))" -ForegroundColor "#b0c3d4"
  $prompt += Write-VcsStatus
  $prompt += "`n$('>' * ($nestedPromptLevel + 1)) "

  $LASTEXITCODE = $origLastExitCode
  $prompt
}