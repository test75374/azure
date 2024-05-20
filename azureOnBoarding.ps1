$rgName="ConflueraResourceGroup"
$namespaceName="ConflueraNamespace$(Get-Random)"
$ehubName="ConflueraEventHub"
$region="eastus"
$authorizationRole="ConflueraAuthorizationRole"
$conflueraDiagSettingsName ="ConflueraDiagSettingsName"
$account = az account show
$account_json = $account | ConvertFrom-Json
$subscriptionId=$account_json.id 

#New-AzResourceGroup –Name $rgName –Location $region
az group create --name $rgName --location $region
if(!$?)
{
	Write-Host "Error: Failed creating resource group - "$rgName 
	return
}
else
{
	Write-Host "Success: Created resource group - "$rgName
}

#New-AzEventHubNamespace -ResourceGroupName $rgName -Name $namespaceName -Location $region
az eventhubs namespace create --name $namespaceName --resource-group $rgName -l $region
if(!$?)
{
	Write-Host "Error: Failed creating evenhub namespaceName - "$rgName "/" $namespaceName
	return
}
else
{
	Write-Host "Success: Created evenhub namespaceName - "$rgName "/" $namespaceName
}

#New-AzEventHub -ResourceGroupName $rgName -NamespaceName $namespaceName -Name $ehubName
az eventhubs eventhub create --name $ehubName --resource-group $rgName --namespace-name $namespaceName
if(!$?)
{
	Write-Host "Error: Failed creating evenhub entity - "$rgName "/" $namespaceName "/" $ehubName
	return
}
else
{
	Write-Host "Success: Created evenhub entity - "$rgName "/" $namespaceName "/" $ehubName
}

az eventhubs eventhub authorization-rule create --resource-group $rgName --namespace-name $namespaceName --eventhub-name $ehubName --rights "Listen" --name $authorizationRole
if(!$?)
{
	Write-Host "Error: Failed creating eventhub authorization-rule on - "$rgName "/" $namespaceName "/" $ehubName
	return
}
else
{
	Write-Host "Success: Created eventhub authorization-rule on - "$rgName "/" $namespaceName "/" $ehubName
}

$keys = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaceName --eventhub-name $ehubName --name $authorizationRole
if(!$?)
{
	Write-Host "Error: Failed listing keys of - "$rgName "/" $namespaceName "/" $ehubName
	return
}
else
{
	Write-Host "Success: Created listing keys of - "$rgName "/" $namespaceName "/" $ehubName
}

$serviceBusRuleId = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.EventHub/namespaces/$namespaceName/authorizationrules/RootManageSharedAccessKey"

az monitor diagnostic-settings subscription create -n "$conflueraDiagSettingsName" --event-hub-auth-rule $serviceBusRuleId --event-hub-name $ehubName --logs "[{category:Security,enabled:true},{category:Administrative,enabled:true},{category:Policy,enabled:true}]"

if(!$?)
{
	Write-Host "Error: Failed creating diag settings - "$rgName "/" $namespaceName "/" $ehubName
	return
}
else
{
	Write-Host "Success: Created diag settings - "$rgName "/" $namespaceName "/" $ehubName
}

$keys_j = $keys | ConvertFrom-Json
Write-Host "`n`n`nCopy/Paste to Confluera monitor onboarding:"
Write-Host $keys_j.primaryConnectionString -ForegroundColor Green

# az eventhubs eventhub authorization-rule list --resource-group "ConflueraResourceGroup" --namespace-name "ConflueraNamespace" --eventhub-name "ConflueraEventHub"
# az eventhubs namespace authorization-rule keys list --resource-group "ConflueraResourceGroup" --namespace-name "ConflueraNamespace" --name "RootManageSharedAccessKey"
#New-AzServiceBusAuthorizationRule -Name "myauthorule1" -NamespaceName "ConflueraNamespace" -ResourceGroupName "ConflueraResourceGroup" -Rights $("Listen")
#Get-AzEventHubKey -ResourceGroupName "ConflueraResourceGroup" -NamespaceName "ConflueraNamespace" -EventHubName "ConflueraEventHub" -AuthorizationRuleName "myauthorule"
# az group delete --name $rgName -y
# az monitor diagnostic-settings subscription delete -n "$conflueraDiagSettingsName" -y 
# Invoke-RestMethod -Uri "https://raw.githubusercontent.com/test75374/azure/main/azureOnBoarding.ps1" | Invoke-Expression


