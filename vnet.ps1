$Location="EastUS"

#Create Resource Group
New-AzResourceGroup -Name vm-networks -Location $Location

#Create subnet and virtual network
$Subnet=New-AzVirtualNetworkSubnetConfig -Name default -AddressPrefix 10.0.0.0/24
 New-AzVirtualNetwork -Name myVnet -ResourceGroupName vm-networks -Location $Location -AddressPrefix 10.0.0.0/16 -Subnet $Subnet

 #Create virtual machine
 New-AzVm `
 -ResourceGroupName "vm-networks" `
 -Name "dataProcStage1" `
 -VirtualNetworkName "myVnet" `
 -SubnetName "default" `
 -image "Win2016Datacenter" `
 -Size "Basic_A0"

 #Get public IP Address
 Get-AzPublicIpAddress -Name dataProcStage1 
 
 #Get Network Interface Connection
$nic = Get-AzNetworkInterface -Name dataProcStage2 -ResourceGroup vm-networks

#Disassociate public IP Address
$nic.IpConfigurations.publicipaddress.id = $null
Set-AzNetworkInterface -NetworkInterface $nic

