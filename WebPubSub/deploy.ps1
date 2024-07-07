param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$WpsName,

    [Parameter()]
    [string]$Location = "EastUs",

    [Parameter()]
    [string]$Sku = "Free_F1",

    [Parameter()]
    [string]$PricingTier = "Free",

    [Parameter()]
    [int]$UnitCount = 1
)

# Create a new resource group
az group create --name $ResourceGroupName --location $Location

# Deploy the .bicep file
az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "deploy.bicep" `
    --parameters `
        wpsName=$WpsName `
        sku=$Sku `
        pricingTier=$PricingTier `
        unitCount=$UnitCount