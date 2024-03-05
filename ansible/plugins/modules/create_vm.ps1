#!powershell

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        vm_name = @{ type = 'str'; required = $true }
        golden_vm = @{ type = 'str'; default = "WindowsServerTest02" }
        network_port = @{ type = 'str'; required = $true }
        vlan_id = @{ type = 'int'; required = $true }
        golden_path = @{ type = 'path'; required = $true }
        vm_path = @{ type = 'path'; required = $true }
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

Import-Module Hyper-V
Import-Module Storage
 
$VMName = $module.Params.vm_name 
$GoldenVM = $module.Params.golden_vm 
$NetworkPort = $module.Params.network_port
$VLANID = $module.Params.vlan_id
$GoldenPath = $module.Params.golden_path 
$VMPath = $module.Params.vm_path 

try {

    $GoldenImage = (get-childitem -path "$GoldenPath$GoldenVM\*.vmcx" -Recurse).FullName
 
    $module.Result.vm_import = Import-VM -Path $GoldenImage -Copy -GenerateNewId -VHDDestinationPath "$VMPath$VMName" -VirtualMachinePath "$VMPath$VMName" | ConvertTo-Json -Compress
    $module.Result.changed=$true 
    Rename-VM $GoldenVM -NewName $VMName 
    Set-VMProcessor $VMName -Count 4 
    Set-VMMemory $VMName -StartupBytes 8GB 
    Set-VMNetworkAdapterVLAN –VMName $VMName –Access –VLANID $VLANID 
    Set-VMSwitch -Name "vswitch01" -AllowManagementOS $true 

}
catch {
    $module.FailJson("Unhandled exception occurred. Exception: $($_.Exception.Message)", $_)
}
# Return result
$module.ExitJson()