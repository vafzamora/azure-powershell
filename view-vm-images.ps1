[CmdletBinding()]
param (
    [Parameter()]
    $Location = "EastUS",
    [Parameter()]
    $Publisher = "MicrosoftWindowsServer",
    [Parameter()]
    $OfferName="WindowsServer"

)
Get-AzVMImageSku -Location $Location -PublisherName $Publisher -Offer $OfferName | Select-Object Skus