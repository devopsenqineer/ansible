#!powershell

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        sitename = @{ type = "str"; required = $true }
        sitesubnet = @{ type = "str"; required = $true }
        firstsite = @{ type = "str"; required = $true }
        secondsite = @{ type = "str"; required = $true }
        sitelinkname = @{ type = "str"; required = $true }    
    }   
}
$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$Sitename = $module.Params.sitename
$SiteSubnet = $module.Params.sitesubnet
$SiteIncluded = $module.Params.firstsite
$SiteIncluded2 = $module.Params.secondsite
$SiteLinkName= $module.Params.sitelinkname

try {
if (Get-ADReplicationSite -Filter {Name -eq $SiteName}) {
    exit 1
}
else {
$module.Result.new_site = New-ADReplicationSite $SiteName 
$module.Result.changed=$true
if (Get-ADReplicationSubnet -Filter {Name -ne $SiteSubnet}) {
    New-ADReplicationSubnet -Name $SiteSubnet -Site $SiteName
    }

New-ADReplicationSiteLink -Name $SiteLinkName -SitesIncluded $SiteIncluded,$SiteIncluded2 -Cost 10 -ReplicationFrequencyInMinutes 60
}
}
catch {
    $module.FailJson("Unhandled exception occurred. Exception: $($_.Exception.Message)", $_)
}
$module.ExitJson()