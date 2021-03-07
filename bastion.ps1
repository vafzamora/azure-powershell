$resourceGroup = "learn-bastion-rg"
$region = "EastUS"

Connect-AzureRmAccount -Subscription "23bc054a-a943-4796-866e-2761431f6d8d"

New-AzureRmResourceGroup -Name $resourceGroup -Location $region
