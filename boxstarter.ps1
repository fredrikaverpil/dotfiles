# Description: Boxstarter Script
#
# Install boxstarter:
# 	. { iwr -useb http://boxstarter.org/bootstrapper.ps1 } | iex; get-boxstarter -Force
#
# You might need to set: Set-ExecutionPolicy RemoteSigned
#
# Run this boxstarter by calling the following from an **elevated** command-prompt:
# 	start http://boxstarter.org/package/nr/url?<URL-TO-RAW-GIST>
# OR
# 	Install-BoxstarterPackage -PackageName <URL-TO-RAW-GIST> -DisableReboots
# OR
#   Install-BoxstarterPackage -PackageName boxstarter.ps1 -DisableReboots
#
# Learn more: http://boxstarter.org/Learn/WebLauncher
#
# Other Boxstarter gists:
# Jess Frazelle: https://gist.github.com/jessfraz/7c319b046daa101a4aaef937a20ff41f
# Nick Craver: https://gist.github.com/NickCraver/7ebf9efbfd0c3eab72e9


#--- Windows Subsystems/Features ---

# Enable WSL
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -norestart

# Install Powershell Core and update packages
iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet"
Install-PackageProvider Nuget -Force
Install-Module -Name PowerShellGet -Force
Update-Module -Name PowerShellGet



#--- Prompt (PsGet and modules) ---

# (new-object Net.WebClient).DownloadString("http://psget.net/GetPsGet.ps1") | iex
# Powershell 5
Install-Module PSColor -Scope CurrentUser -Force  # https://github.com/Davlind/PSColor
Install-Module Posh-Git -Scope CurrentUser -Force  # https://github.com/dahlbyk/posh-git
# Powershell Core
pwsh -Command "Install-Module PSColor -Scope CurrentUser -Force"  # https://github.com/Davlind/PSColor
pwsh -Command "Install-Module Posh-Git -Scope CurrentUser -Force"  # https://github.com/dahlbyk/posh-git


#--- Windows Settings ---

Disable-BingSearch
Disable-GameBarTips
Enable-RemoteDesktop
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions
Set-TaskbarOptions -Size Small -Dock Bottom -Combine Always -Lock
Set-TaskbarOptions -Size Small -Dock Bottom -Combine Always -AlwaysShowIconsOn


#--- Uninstall unecessary applications that come with Windows out of the box ---

# 3D Builder
Get-AppxPackage Microsoft.3DBuilder | Remove-AppxPackage

# Alarms
Get-AppxPackage Microsoft.WindowsAlarms | Remove-AppxPackage

# Autodesk
Get-AppxPackage *Autodesk* | Remove-AppxPackage

# Bing Weather, News, Sports, and Finance (Money):
Get-AppxPackage Microsoft.BingFinance | Remove-AppxPackage
Get-AppxPackage Microsoft.BingNews | Remove-AppxPackage
Get-AppxPackage Microsoft.BingSports | Remove-AppxPackage
Get-AppxPackage Microsoft.BingWeather | Remove-AppxPackage

# BubbleWitch
Get-AppxPackage *BubbleWitch* | Remove-AppxPackage

# Candy Crush
Get-AppxPackage king.com.CandyCrush* | Remove-AppxPackage

# Comms Phone
Get-AppxPackage Microsoft.CommsPhone | Remove-AppxPackage

# Dell
Get-AppxPackage *Dell* | Remove-AppxPackage

# Dropbox
Get-AppxPackage *Dropbox* | Remove-AppxPackage

# Facebook
Get-AppxPackage *Facebook* | Remove-AppxPackage

# Feedback Hub
Get-AppxPackage Microsoft.WindowsFeedbackHub | Remove-AppxPackage

# Get Started
Get-AppxPackage Microsoft.Getstarted | Remove-AppxPackage

# Keeper
Get-AppxPackage *Keeper* | Remove-AppxPackage

# Mail & Calendar
Get-AppxPackage microsoft.windowscommunicationsapps | Remove-AppxPackage

# Maps
Get-AppxPackage Microsoft.WindowsMaps | Remove-AppxPackage

# March of Empires
Get-AppxPackage *MarchofEmpires* | Remove-AppxPackage

# McAfee Security
Get-AppxPackage *McAfee* | Remove-AppxPackage

# Uninstall McAfee Security App
$mcafee = gci "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_ -match "McAfee Security" } | select UninstallString
if ($mcafee) {
	$mcafee = $mcafee.UninstallString -Replace "C:\Program Files\McAfee\MSC\mcuihost.exe",""
	Write "Uninstalling McAfee..."
	start-process "C:\Program Files\McAfee\MSC\mcuihost.exe" -arg "$mcafee" -Wait
}

# Messaging
Get-AppxPackage Microsoft.Messaging | Remove-AppxPackage

# Minecraft
Get-AppxPackage *Minecraft* | Remove-AppxPackage

# Netflix
Get-AppxPackage *Netflix* | Remove-AppxPackage

# Office Hub
Get-AppxPackage Microsoft.MicrosoftOfficeHub | Remove-AppxPackage

# One Connect
Get-AppxPackage Microsoft.OneConnect | Remove-AppxPackage

# OneNote
Get-AppxPackage Microsoft.Office.OneNote | Remove-AppxPackage

# People
Get-AppxPackage Microsoft.People | Remove-AppxPackage

# Phone
Get-AppxPackage Microsoft.WindowsPhone | Remove-AppxPackage

# Photos
Get-AppxPackage Microsoft.Windows.Photos | Remove-AppxPackage

# Plex
Get-AppxPackage *Plex* | Remove-AppxPackage

# Skype (Metro version)
Get-AppxPackage Microsoft.SkypeApp | Remove-AppxPackage

# Sound Recorder
Get-AppxPackage Microsoft.WindowsSoundRecorder | Remove-AppxPackage

# Solitaire
Get-AppxPackage *Solitaire* | Remove-AppxPackage

# Sticky Notes
Get-AppxPackage Microsoft.MicrosoftStickyNotes | Remove-AppxPackage

# Sway
Get-AppxPackage Microsoft.Office.Sway | Remove-AppxPackage

# Twitter
Get-AppxPackage *Twitter* | Remove-AppxPackage

# Xbox
Get-AppxPackage Microsoft.XboxApp | Remove-AppxPackage
Get-AppxPackage Microsoft.XboxIdentityProvider | Remove-AppxPackage

# Zune Music, Movies & TV
Get-AppxPackage Microsoft.ZuneMusic | Remove-AppxPackage
Get-AppxPackage Microsoft.ZuneVideo | Remove-AppxPackage


#--- Install software ---

# cinst sysinternals
cinst procexp
cinst which
cinst git
cinst googlechrome  # known issue: checksum errors
cinst visualstudiocode
cinst visualstudiocode-insiders --pre
cinst ctags
cinst docker-for-windows
cinst docker-compose
cinst slack
cinst gitter
cinst wunderlist

# Download Miniconda3
(New-Object System.Net.WebClient).DownloadFile("https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe", "${HOME}\Downloads\Miniconda3-latest-Windows-x86_64.exe")
& "${HOME}\Downloads\Miniconda3-latest-Windows-x86_64.exe" /S /InstallationType=JustMe /AddToPath=1 /D=${HOME}\Miniconda3


#--- Windows Update ---

Enable-MicrosoftUpdate
Install-WindowsUpdate -acceptEula


#--- Rename the Computer ---

# Requires restart, or add the -Restart flag
$computername = "faverpil-win"
if ($env:computername -ne $computername) {
	Rename-Computer -NewName $computername
}
