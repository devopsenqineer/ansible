#!powershell

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        vm_name = @{ type = 'str'; required = $true }
        user = @{ type = 'str'; required = $true; no_log = $true}
        p_word = @{ type = 'str'; required = $true; no_log = $true } 
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$VMName = $module.Params.vm_name
$User = $module.Params.user
$PWord = ConvertTo-SecureString -String "Temp1234" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

try {

    Start-VM $VMName
    Start-Sleep -Seconds 180
    Invoke-Command -VMName $VMName -Credential $Credential -ArgumentList $VMName -ScriptBlock {

        Rename-Computer -NewName $args[0]
    }
    
    Stop-VM $VMName

    $mac = (Get-VMNetworkAdapter -VMName $VMName | Select-Object -ExpandProperty MacAddress)

    if ($mac -ne $null) {
    Set-VMNetworkAdapter -VMName $VMName -StaticMacAddress $mac | ConvertTo-Json -Compress
    } else {
    $module.result.msg = "Fehler beim Abrufen der Mac-Adresse."
    }

    Start-VM $VMName
    $module.result.msg = "Computer wurde in '$VMName' umbenannt."
    $module.Result.changed=$true
}
catch {
    $module.FailJson("Unhandled exception occurred. Exception: $($_.Exception.Message)", $_)
}
# Return result
$module.ExitJson()