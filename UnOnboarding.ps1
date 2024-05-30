$conflueraDiagSettingsName = "ConflueraDiagSettingsMonitor"
$ConflueraDiagSettingsNameAD = "ConflueraDiagSettingsAD"
$rgName = "ConflueraResourceGroup"


az monitor diagnostic-settings subscription delete -n "$conflueraDiagSettingsName" -y
$accessToken = (Get-AzAccessToken -ResourceUrl "https://management.azure.com").Token

$apiEndpoint = "https://management.azure.com/providers/microsoft.aadiam/diagnosticSettings/$ConflueraDiagSettingsNameAD`?api-version=2017-04-01-preview"

$headers = @{
   "Authorization" = "Bearer $accessToken"
   "Content-Type" = "application/json"
}

$response = Invoke-RestMethod -Uri $apiEndpoint -Headers $headers -Method Delete
Write-Output "Diagnostic setting deleted successfully."
az group delete --name $rgName -y

