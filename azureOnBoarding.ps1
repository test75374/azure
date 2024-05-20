$rgName="ConflueraResourceGroup"
$namespaceName="ConflueraNamespace"
$ehubName="ConflueraEventHub"
$region="eastus"


New-AzResourceGroup –Name $rgName –Location $region
if(!$?)
{
	Write-Host "Error: Failed creating resource group - "$rgName 
	return
}
else
{
	Write-Host "Success: Created resource group - "$rgName
}

New-AzEventHubNamespace -ResourceGroupName $rgName -Name $namespaceName -Location $region
if(!$?)
{
	Write-Host "Error: Failed creating evenhub namespaceName - "$rgName " " $namespaceName
	return
}
else
{
	Write-Host "Success: Created evenhub namespaceName - "$rgName " " $namespaceName
}

New-AzEventHub -ResourceGroupName $rgName -NamespaceName $namespaceName -Name $ehubName
if(!$?)
{
	Write-Host "Error: Failed creating evenhub entity - "$rgName " " $namespaceName " " $ehubName
	return
}
else
{
	Write-Host "Success: Created evenhub entity - "$rgName " " $namespaceName " " $ehubName
}

# Remove-AzResourceGroup $rgName