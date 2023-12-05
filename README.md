# windows-installer

Welcome to the Windows Installer repository! This repository hosts Ansible playbooks designed to streamline the installation and configuration of software on Windows systems using Ansible on WSL2.

## Configure WinRM to allow Ansible to connect to Windows

To establish a connection between Ansible and Windows, you'll need to set up the WinRM (Windows Remote Management) service. Follow these steps in an elevated PowerShell session:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = "https://raw.githubusercontent.com/ansible/ansible-documentation/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)

powershell.exe -ExecutionPolicy ByPass -File $file
```

In case you encounter the error message `Unable to check the status of the firewall` after running the commands above, execute the following command to address the issue:

```powershell
netsh advfirewall firewall add rule name="Windows Remote Management (HTTP-In)" dir=in action=allow service=any enable=yes profile=any localport=5985 protocol=tcp
netsh advfirewall firewall add rule name="Windows Remote Management (HTTPS-In)" dir=in action=allow service=any enable=yes profile=any localport=5986 protocol=tcp
```

These steps should help establish a secure and seamless connection between Ansible and Windows systems.

## Generate inventory file (WSL2)

```bash
chmod +x ./generate-wsl2-inventory.sh
./generate-wsl2-inventory.sh
```
