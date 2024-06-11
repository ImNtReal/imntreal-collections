#!powershell

# Copyright: (c) 2019, Jameson Pugh

#Requires -Module Ansible.ModuleUtils.Legacy

$ErrorActionPreference = "Stop"

# Create a new result object
$result = @{
  changed = $false
  ansible_facts = @{
    ansible_mssql =  @{
      instances = @()
    }
  }
}

$instances = [System.Collections.ArrayList]@()

if ($PSVersionTable.PSVersion.Major -lt 6) {
  $IsWindows = $True
}

If ($IsWindows) {
  try {
    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Services\SQL Server') {
      $service_lname = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Services\SQL Server').LName
      $service_name = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Services\SQL Server').Name
      $agent_lname = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Services\SQL Agent').LName
      $agent_name = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Services\SQL Agent').Name
    }
    if (Test-Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\Services\SQL Server') {
      $service_lname = (Get-ItemProperty 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\Services\SQL Server').LName
      $service_name = (Get-ItemProperty 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\Services\SQL Server').Name
      $agent_lname = (Get-ItemProperty 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\Services\SQL Agent').LName
      $agent_name = (Get-ItemProperty 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\Services\SQL Agent').Name
    }
  } catch {
    Fail-Json -obj $result -message "Failed to get SQL service LName/Names on the target: $($_.Exception.Message)"
  }

  try {
    foreach ($instance in ((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances)) {
      foreach ($Path in (Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server' | Where-Object { $_.Name -like "*MSSQL*" }).PSPath) {  
        if ((Get-ItemProperty -Path $Path).'(default)' -eq $instance) {
          $instance_path = $Path
        }
      }
      if ($instance_path -eq $null -and $instance -eq 'MSSQLSERVER') {
        $instance_path = (Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server' | Where-Object { $_.Name -like "*MSSQL*.$env:COMPUTERNAME" }).PSPath
      }
      $instance_port = (Get-ItemProperty -Path "$instance_path\MSSQLServer\SuperSocketNetLib\Tcp\IPAll" -Name TcpPort).TcpPort
      if ($instance_port -eq '') {
        $instance_port = (Get-ItemProperty -Path "$instance_path\MSSQLServer\SuperSocketNetLib\Tcp\IPAll" -Name TcpDynamicPorts).TcpDynamicPorts
      }
      if ($instance = 'MSSQLSERVER') {
        $instance_instance = "$env:COMPUTERNAME".ToUpper()
        $instance_fqdn = "$env:COMPUTERNAME.$env:USERDNSDOMAIN".ToLower()
        $instance_service = $service_name
        $instance_agent = $agent_name
      } else {
        $instance_instance = "$env:COMPUTERNAME".ToUpper() + "\$instance"
        $instance_service = "$service_lname$instance"
        $instance_fqdn = "$env:COMPUTERNAME.$env:USERDNSDOMAIN".ToLower() + "\$instance"
        $instance_agent = "$agent_lname$instance"
      }
      $instance_info = @{
        name = $instance
        port = $instance_port
        reg_path = $instance_path -replace 'Microsoft.PowerShell.Core\\Registry::HKEY_LOCAL_MACHINE', "HKLM:"
        instance = $instance_instance
        fqdn = $instance_fqdn
        service = $instance_service
        agent = $instance_agent
      }
      $instances.Add($instance_info)
    }
    foreach ($instance in ((Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server').InstalledInstances)) {
      foreach ($Path in (Get-ChildItem -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server' | Where-Object { $_.Name -like "*MSSQL*" }).PSPath) {
        if ((Get-ItemProperty -Path $Path).'(default)' -eq $instance) {
          $instance_path = $Path
        }
      }
      if ($instance_path -eq $null -and $instance -eq 'MSSQLSERVER') {
        $instance_path = (Get-ChildItem -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server' | Where-Object { $_.Name -like "*MSSQL*.$env:COMPUTERNAME" }).PSPath
      }
      $instance_port = (Get-ItemProperty -Path "$instance_path\MSSQLServer\SuperSocketNetLib\Tcp\IPAll" -Name TcpPort).TcpPort
      if ($instance_port -eq '') {
        $instance_port = (Get-ItemProperty -Path "$instance_path\MSSQLServer\SuperSocketNetLib\Tcp\IPAll" -Name TcpDynamicPorts).TcpDynamicPorts
      }
      if ($instance = 'MSSQLSERVER') {
        $instance_instance = "$env:COMPUTERNAME".ToUpper()
        $instance_fqdn = "$env:COMPUTERNAME.$env:USERDNSDOMAIN".ToLower()
        $instance_service = $service_name
        $instance_agent = $agent_name
      } else {
        $instance_instance = "$env:COMPUTERNAME".ToUpper() + "\$instance"
        $instance_service = "$service_lname$instance"
        $instance_fqdn = "$env:COMPUTERNAME.$env:USERDNSDOMAIN".ToLower() + "\$instance"
        $instance_agent = "$agent_lname$instance"
      }
      $instance_info = @{
        name = $instance
        port = $instance_port
        reg_path = $instance_path -replace 'Microsoft.PowerShell.Core\\Registry::HKEY_LOCAL_MACHINE', "HKLM:"
        instance = $instance_instance
        fqdn = $instance_fqdn
        service = $instance_service
        agent = $instance_agent
      }
      $instances.Add($instance_info)
    }
  } catch {
    Fail-Json -obj $result -message "Failed to get SQL instances on the target: $($_.Exception.Message)"
  }
}

If ($IsLinux) {
  $instance = "MSSQLSERVER"
  $instance_instance = (hostname).ToUpper()
  $instance_fqdn = (hostname -f).ToLower()
  $instance_service = "mssql-server"
  $instance_agent = ""
  try {
    $instance_port = (cat /var/opt/mssql/mssql.conf | awk '/tcpport/ {print $3}')
  } catch {
    Fail-Json -obj $result -message "Failed to get SQL instance port."
  }
  If (! $instance_port) {
    $instance_port = "1433"
  }
  $instance_info = @{
    name = $instance
    port = $instance_port
    reg_path = $instance_path -replace 'Microsoft.PowerShell.Core\\Registry::HKEY_LOCAL_MACHINE', "HKLM:"
    instance = $instance_instance
    fqdn = $instance_fqdn
    service = $instance_service
    agent = $instance_agent
  }
  $instances.Add($instance_info)
}

$result.ansible_facts.ansible_mssql.instances = $instances

# Return result
Exit-Json -obj $result
