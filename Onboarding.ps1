$rgName="ConflueraResourceGroup"
$namespaceName="ConflueraNamespace$(Get-Random)"
$ehubName="ConflueraEventHub"
$region="eastus"
$authorizationRole="ConflueraAuthorizationRole"
$conflueraDiagSettingsName="ConflueraDiagSettingsMonitor"
$ConflueraDiagSettingsNameAD="ConflueraDiagSettingsAD"
$account = az account show
$account_json = $account | ConvertFrom-Json
# $subscriptionId=$account_json.id
$onboardAD = $true
$subscriptionIds = @("ac08270f-318f-4fe5-aa77-7a1ac39af23f")

$ADOnboarded = $false
foreach ( $subscriptionId in $subscriptionIds )
{
    az account set --subscription $subscriptionId > $null
    if(!$?)
    {
        Write-Host "Error: Failed connect subscription - "$subscriptionId -ForegroundColor Red
        continue;
    }
    Write-Host "Info: connected to subscription - "$subscriptionId
    #New-AzResourceGroup –Name $rgName –Location $region
    az group create --name $rgName --location $region > $null
    if(!$?)
    {
        Write-Host "Error: Failed creating resource group - "$rgName -ForegroundColor Red
        continue;
    }

    #New-AzEventHubNamespace -ResourceGroupName $rgName -Name $namespaceName -Location $region
    az eventhubs namespace create --name $namespaceName --resource-group $rgName -l $region > $null
    if(!$?)
    {
        Write-Host "Error: Failed creating evenhub namespaceName - "$rgName "/" $namespaceName -ForegroundColor Red
        continue;
    }

    #New-AzEventHub -ResourceGroupName $rgName -NamespaceName $namespaceName -Name $ehubName
    az eventhubs eventhub create --name $ehubName --resource-group $rgName --namespace-name $namespaceName > $null
    if(!$?)
    {
        Write-Host "Error: Failed creating evenhub entity - "$rgName "/" $namespaceName "/" $ehubName -ForegroundColor Red
        continue;
    }

    az eventhubs eventhub authorization-rule create --resource-group $rgName --namespace-name $namespaceName --eventhub-name $ehubName --rights "Listen" --name $authorizationRole > $null
    if(!$?)
    {
        Write-Host "Error: Failed creating eventhub authorization-rule on - "$rgName "/" $namespaceName "/" $ehubName -ForegroundColor Red
        continue;
    }

    $keys = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaceName --eventhub-name $ehubName --name $authorizationRole
    if(!$?)
    {
        Write-Host "Error: Failed listing keys of - "$rgName "/" $namespaceName "/" $ehubName -ForegroundColor Red
        continue;
    }

    $serviceBusRuleId = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.EventHub/namespaces/$namespaceName/authorizationrules/RootManageSharedAccessKey"

    az monitor diagnostic-settings subscription create -n "$conflueraDiagSettingsName" --event-hub-auth-rule $serviceBusRuleId --event-hub-name $ehubName --logs "[{category:Security,enabled:true},{category:Administrative,enabled:true},{category:Policy,enabled:true}]" > $null

    if(!$?)
    {
        Write-Host "Error: Failed creating diag settings - "$rgName "/" $namespaceName "/" $ehubName -ForegroundColor Red
        continue;
    }

    $keys_j = $keys | ConvertFrom-Json
    Write-Host "`n`n`nCopy/Paste to Confluera monitor onboarding:"
    Write-Host $keys_j.primaryConnectionString -ForegroundColor Green
    if (!($ADOnboarded) -and ($onboardAD)) {
            # Generate an access token for the management API
            $accessToken = (Get-AzAccessToken -ResourceUrl "https://management.azure.com").Token

            if(!$?)
            {
                Write-Host "Error get access token" -ForegroundColor Red
                continue;
            }

            # Set the API endpoint
            $apiEndpoint = "https://management.azure.com/providers/microsoft.aadiam/diagnosticSettings/$ConflueraDiagSettingsNameAD`?api-version=2017-04-01-preview"

            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            $json = "{'id':'/providers/microsoft.aadiam/providers/microsoft.insights/diagnosticSettings/$ConflueraDiagSettingsNameAD','name':'$ConflueraDiagSettingsNameAD','properties':{'logs':[{'category':'AuditLogs','categoryGroup':null,'enabled':true,'retentionPolicy':{'days':0,'enabled':false}},{'category':'SignInLogs','categoryGroup':null,'enabled':false,'retentionPolicy':{'days':0,'enabled':false}},{'category':'NonInteractiveUserSignInLogs','categoryGroup':null,'enabled':false,'retentionPolicy':{'days':0,'enabled':false}},{'category':'ServicePrincipalSignInLogs','categoryGroup':null,'enabled':false,'retentionPolicy':{'days':0,'enabled':false}},{'category':'ManagedIdentitySignInLogs','categoryGroup':null,'enabled':false,'retentionPolicy':{'days':0,'enabled':false}},{'category':'ProvisioningLogs','categoryGroup':null,'enabled':false,'retentionPolicy':{'days':0,'enabled':false}},{'category':'ADFSSignInLogs','categoryGroup':null,'enabled':false,'retentionPolicy':{'days':0,'enabled':false}},{'category':'RiskyUsers','categoryGroup':null,'enabled':false,'retentionPolicy':{'days':0,'enabled':false}},{'category':'UserRiskEvents','categoryGroup':null,'enabled':false,'retentionPolicy':{'days':0,'enabled':false}},{'category':'NetworkAccessTrafficLogs','categoryGroup':null,'enabled':false,'retentionPolicy':{'days':0,'enabled':false}},{'category':'RiskyServicePrincipals','categoryGroup':null,'enabled':false,'retentionPolicy':{'days':0,'enabled':false}},{'category':'ServicePrincipalRiskEvents','categoryGroup':null,'enabled':false,'retentionPolicy':{'days':0,'enabled':false}},{'category':'EnrichedOffice365AuditLogs','categoryGroup':null,'enabled':false,'retentionPolicy':{'days':0,'enabled':false}},{'category':'MicrosoftGraphActivityLogs','categoryGroup':null,'enabled':false,'retentionPolicy':{'days':0,'enabled':false}},{'category':'RemoteNetworkHealthLogs','categoryGroup':null,'enabled':false,'retentionPolicy':{'days':0,'enabled':false}}],'metrics':[],'eventHubAuthorizationRuleId':'$serviceBusRuleId','eventHubName':'$ehubName'}}"

            $response = Invoke-RestMethod -Uri $apiEndpoint -Headers $headers -Body $json -Method PUT
            if(!$?)
            {
                Write-Host "Error create diagnosticSettings for Azure AD" -ForegroundColor Red
                continue;
            }
            $onboardingID = $subscriptionId+"*"+$conflueraDiagSettingsName+"*"+$rgName+"*"+$ConflueraDiagSettingsNameAD
            $toPrint = $toPrint + ":::" + $onboardingID
            $ADOnboarded = $true
     } else {
        $onboardingID = $subscriptionId+"*"+$conflueraDiagSettingsName+"*"+$rgName
        $toPrint = $toPrint + ":::" + $onboardingID
     }
    Write-Host "`n`n`nCopy/Paste to UnOnboard script:"
    Write-Host $toPrint
}






# az eventhubs eventhub authorization-rule list --resource-group "ConflueraResourceGroup" --namespace-name "ConflueraNamespace" --eventhub-name "ConflueraEventHub"
# az eventhubs namespace authorization-rule keys list --resource-group "ConflueraResourceGroup" --namespace-name "ConflueraNamespace" --name "RootManageSharedAccessKey"
#New-AzServiceBusAuthorizationRule -Name "myauthorule1" -NamespaceName "ConflueraNamespace" -ResourceGroupName "ConflueraResourceGroup" -Rights $("Listen")
#Get-AzEventHubKey -ResourceGroupName "ConflueraResourceGroup" -NamespaceName "ConflueraNamespace" -EventHubName "ConflueraEventHub" -AuthorizationRuleName "myauthorule"

# Invoke-RestMethod -Uri "https://raw.githubusercontent.com/test75374/azure/main/Onboarding.ps1" | Invoke-Expression


