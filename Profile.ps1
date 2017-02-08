# Aliases
# New-Alias -Name ll -Value ls

# List all files and folders including hidden ones using "ll" function
function ll {
  Get-ChildItem -Force @args
}

# Import modules
Import-Module PSColor  # https://github.com/Davlind/PSColor
Import-Module posh-git  # https://github.com/dahlbyk/posh-git

# Module settings
$global:PSColor.File.Executable.Color = 'Blue'  # Set blue color for executables (instead of red)

# Update modules
# Install-Module PSColor
# Update-Module posh-git

# Environment variables
$CONDAENVS = "C:\Program Files\Miniconda2\envs"
