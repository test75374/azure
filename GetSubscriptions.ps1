Set-Item -Path Env:\AZURE_CLIENTS_SHOW_SECRETS_WARNING -Value $false
$accessToken = (Get-AzAccessToken -ResourceUrl "https://management.azure.com").Token

if(!$?)
{
	Write-Host "Error get access token" -ForegroundColor Red
	return
}
# Set the API endpoint
$apiEndpoint = "https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01"

$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
}
$json = '{"query":"resourcecontainers\n        | where type == \"microsoft.resources/subscriptions\"\n        | join kind=leftouter (securityresources \n            | where type == \"microsoft.security/securescores\"\n            | where properties.environment == \"Azure\" and properties.displayName == \"ASC score\"\n            ) on subscriptionId\n        | extend secureScore=properties1.score.percentage,\n            managementGroup=properties.managementGroupAncestorsChain,\n            subscriptionName=name,\n            status=properties.state\n        | project subscriptionId, subscriptionName"}'
$response = Invoke-RestMethod -Uri $apiEndpoint -Headers $headers -Body $json -Method POST
if(!$?)
{
	Write-Host "Error getting subscription list" -ForegroundColor Red
	return
}

Write-Host "`n`nCopy/Past Subscriptions you would like to onboard: `n" -ForegroundColor Green


Foreach ($i in $response.data) {$i}