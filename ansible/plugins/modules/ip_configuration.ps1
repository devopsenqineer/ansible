#!powershell

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        vm_name = @{ type = 'str'; required = $true }
        ip = @{ type = 'str'; required = $true }
        mask_bits = @{ type = 'str'; required = $true }
        gateway = @{ type = 'str'; required = $true }
        dns = @{ type = 'str'; required = $true }
        ip_type = @{ type = 'str'; required = $true }
        user = @{ type = 'str'; required = $true }
        p_word = @{ type = 'str'; required = $true }
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$VMName = $module.Params.vm_name
$IP = $module.Params.ip
$MaskBits = $module.Params.mask_bits
$Gateway = $module.Params.gateway
$Dns = $module.Params.dns
$IPType = $module.Params.ip_type
$User = $module.Params.user
$PWord = ConvertTo-SecureString -String "Temp1234" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

try {


    $null = Invoke-Command -VMName $VMName -Credential $Credential -ArgumentList $IP, $MaskBits, $Gateway, $Dns, $IPType -ScriptBlock {

    param(
    $IP,
    $MaskBits,
    $Gateway,
    $Dns,
    $IPType
    )
    
    # Retrieve the network adapter that you want to configure 
    $adapter = Get-NetAdapter | ? {$_.Status -eq "up"}
    # Remove any existing IP, gateway from our ipv4 adapter
    If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
    $adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
    }
    If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
    $adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
    }
    # Configure the IP address and default gateway
    $adapter | New-NetIPAddress `
    -AddressFamily $IPType `
    -IPAddress $IP `
    -PrefixLength $MaskBits `
    -DefaultGateway $Gateway `
    
    # Configure the DNS client server IP addresses
    $adapter | Set-DnsClientServerAddress -ServerAddresses $DNS 
    }
$module.Result.changed=$true
}
catch {
    $module.FailJson("Unhandled exception occurred. Exception: $($_.Exception.Message)", $_)
}
# Return result
$module.ExitJson()