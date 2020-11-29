$RG="az-networkwatcher-rg"
$location = "EastUS"
$password = "PP@ssw0rd666"


#Resource group
#az group create --name $RG --location $location

#vnet+subnet
az network vnet create `
    --resource-group $RG `
    --name MyVNet1 `
    --address-prefix 10.10.0.0/16 `
    --subnet-name FrontendSubnet `
    --subnet-prefix 10.10.1.0/24

#backend subnet
    az network vnet subnet create `
    --address-prefixes 10.10.2.0/24 `
    --name BackendSubnet `
    --resource-group $RG `
    --vnet-name MyVNet1

#create frontend VM
az vm create `
    --resource-group $RG `
    --name FrontendVM `
    --vnet-name MyVNet1 `
    --subnet FrontendSubnet `
    --image Win2019Datacenter `
    --admin-username azureuser `
    --admin-password $password

#install IIS 
$settingIIS = '{""""commandToExecute"""":""""powershell.exe Install-WindowsFeature -Name Web-Server""""}'
az vm extension set `
    --publisher Microsoft.Compute `
    --name CustomScriptExtension `
    --vm-name FrontendVM `
    --resource-group $RG `
    --settings  $settingIIS `
    --no-wait

#backend VM
    az vm create `
    --resource-group $RG `
    --name BackendVM `
    --vnet-name MyVNet1 `
    --subnet BackendSubnet `
    --image Win2019Datacenter `
    --admin-username azureuser `
    --admin-password $password
#install IIS backend
    az vm extension set `
    --publisher Microsoft.Compute `
    --name CustomScriptExtension `
    --vm-name BackendVM `
    --resource-group $RG `
    --settings '{""commandToExecute"":""powershell.exe Install-WindowsFeature -Name Web-Server""}' `
    --no-wait
# create NSG
    az network nsg create `
    --name MyNsg `
    --resource-group $RG   
# create NSG configuration with error
    az network nsg rule create `
    --resource-group $RG `
    --name MyNSGRule `
    --nsg-name MyNsg `
    --priority 4096 `
    --source-address-prefixes '*' `
    --source-port-ranges '*' `
    --destination-address-prefixes '*' `
    --destination-port-ranges 80 443 3389 `
    --access Deny `
    --protocol TCP `
    --direction Outbound `
    --description "Deny from specific IP address ranges on 80, 443 and 3389."

#associate NSG w/ vnet
    az network vnet subnet update `
    --resource-group $RG `
    --name BackendSubnet `
    --vnet-name MyVNet1 `
    --network-security-group MyNsg

#enable network watcher
az network watcher configure `
--resource-group $RG `
--location $location `
--enabled true