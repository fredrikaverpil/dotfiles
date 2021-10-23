# Enable Hyper-V (for WSL)
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart

# Install from ms store
winget install --source msstore "Windows Subsystem for Linux" --id 9P9TQF7MRM4R
winget install --source msstore "Ubuntu 20.04 LTS" --id 9N6SVWS3RX71
