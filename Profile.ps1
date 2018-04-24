# Aliases
# New-Alias -Name ll -Value ls

# List all files and folders including hidden ones using "ll" function
function ll {
  Get-ChildItem -Force @args
}

# Import modules
# See modules paths with command: $env:PSModulePath
Import-Module PSColor  # https://github.com/Davlind/PSColor
Import-Module posh-git  # https://github.com/dahlbyk/posh-git

# PSColor settings
$global:PSColor.File.Executable.Color = 'Blue'  # Set blue color for executables (instead of red)
