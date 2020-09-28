#DOWNLOAD AND INSTALL CHOCOLATEY ON TARGET MACHINE
#Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
#nav to choco bin so choco command recognized
#cd C:/ProgramData/chocolatey/bin

#choco install virtualbox -y
#choco install vagrant -y

$url = "https://releases.hashicorp.com/vagrant/2.2.10/vagrant_2.2.10_x86_64.msi"
$filePath = "vagrantInstall.msi"
Invoke-RestMethod -Method 'Get' -Uri $url -OutFile $filePath


$timeStamp = get-date -Format yyyyMMddTHHmmss
$logFile = '{0}-{1}.log' -f $filePath,$timeStamp
$MSIArguments = @(
    "/i"
    ('"{0}"' -f $filePath)
    "/qn"
    "/promptrestart"
    "/L*v"
    $logFile
)
Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow 

Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All

[System.Environment]::SetEnvironmentVariable('VAGRANT_EXPERIMENTAL', 'disks',[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('VAGRANT_EXPERIMENTAL', 'disks',[System.EnvironmentVariableTarget]::User)

vagrant plugin install vagrant-disksize
vagrant --version