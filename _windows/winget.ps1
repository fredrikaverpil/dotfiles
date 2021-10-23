
# Install Windows Terminal
winget install --source msstore "Windows Terminal" --id 9N0DX20HK701
# Crete symlink for Windows Terminal
rm $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
New-Item -ItemType SymbolicLink -Path $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json -Value \\wsl.localhost\Ubuntu-20.04\home\fredrik\code\repos\dotfiles\_windows/terminal_settings.json

# Coding
winget install --spirce winget "Docker Desktop" --id "Docker.DockerDesktop"
winget install --source msstore "Visual Studio Code" --id XP9KHM4BK9FZ7Q

# HHKB/macOS compatible workflow
winget install --source msstore  "AutoHotkey Store Edition" --id 9NQ8Q8J78637
winget install "SharpKeys" --id "RandyRants.SharpKeys"

# Other apps
winget install "1Password" --id "AgileBits.1Password"
winget install --source msstore "Spotify Music" --id 9NCBCSZSJRSB
winget install --source msstore "Adobe Reader Touch" --id 9WZDNCRFJ2GC