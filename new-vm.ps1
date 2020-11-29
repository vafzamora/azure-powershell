param(
    [string] $Location="EastUS", 
    [Parameter(Mandatory=$True)]
    [string] $ResourceGroupName,
    [Parameter(Mandatory=$True)]
    [string] $VmName
)

Connect-AzAccount 

#Create Resource Group
New-AzResourceGroup -Name $ResourceGroupName -Location $Location

#Create subnet and virtual network
$subnet = New-AzVirtualNetworkSubnetConfig `
    -Name default `
    -AddressPrefix 10.0.0.0/24

$vnet = New-AzVirtualNetwork `
    -Name myVnet `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -AddressPrefix 10.0.0.0/16 `
    -Subnet $subnet

# Create a public IP address and specify a DNS name
$pip = New-AzPublicIpAddress `
  -ResourceGroupName $ResourceGroupName `
  -Location $Location `
  -AllocationMethod Dynamic `
  -IdleTimeoutInMinutes 4 `
  -Name "$VmName$(Get-Random)"

# Create an inbound network security group rule for port 22
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
  -Name "myNetworkSecurityGroupRuleSSH"  `
  -Protocol "Tcp" `
  -Direction "Inbound" `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 22 `
  -Access "Allow"

# Create an inbound network security group rule for port 80
$nsgRuleWeb = New-AzNetworkSecurityRuleConfig `
  -Name "myNetworkSecurityGroupRuleWWW"  `
  -Protocol "Tcp" `
  -Direction "Inbound" `
  -Priority 1001 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access "Allow"

# Create a network security group
$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName $ResourceGroupName `
  -Location $Location `
  -Name "myNetworkSecurityGroup" `
  -SecurityRules $nsgRuleSSH,$nsgRuleWeb

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface `
  -Name "myNic" `
  -ResourceGroupName $ResourceGroupName `
  -Location $Location `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $pip.Id `
  -NetworkSecurityGroupId $nsg.Id

# Define a credential object
$securePassword = ConvertTo-SecureString '!P@ssw0rd666' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("vzamora", $securePassword)

# Create a virtual machine configuration
$vmConfig = New-AzVMConfig `
  -VMName $VmName `
  -VMSize "Standard_B2s" | `
Set-AzVMOperatingSystem `
  -Linux `
  -ComputerName $VmName `
  -Credential $cred `
  -DisablePasswordAuthentication | `
Set-AzVMSourceImage `
  -PublisherName "Canonical" `
  -Offer "UbuntuServer" `
  -Skus "18.04-LTS" `
  -Version "latest" | `
Add-AzVMNetworkInterface `
  -Id $nic.Id

# Configure the SSH key
$sshPublicKey = Get-Content ~/.ssh/id_rsa.pub
Add-AzVMSshPublicKey `
  -VM $vmconfig `
  -KeyData $sshPublicKey `
  -Path "/home/vzamora/.ssh/authorized_keys"

 #Create virtual machine
 New-AzVm `
    -VM $vmConfig `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `


