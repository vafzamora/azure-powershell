Connect-AzAccount -Tenant 3590422d-8e59-4036-9245-d6edd8cc0f7a

$ResourceGroup = "TJSP_STI7_RG_HOLOS"
$Assignments = (Get-AzRoleAssignment -ResourceGroupName $ResourceGroup)

foreach ($Assignment in $Assignments) {
    
}

