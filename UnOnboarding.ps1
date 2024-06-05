$config = "###Endpoint=flueraEventHub:::ac08270f-318f-4fe5-aa77-7a1ac39af23f,ConflueraDiagSettingsMonitor,ConflueraResourceGroup,ConflueraDiagSettingsAD###EndpoinEntityPath=ConflueraEventHub:::9b36b74d-2b1d-4085-b2d1-55c95f1dc6d0,ConflueraDiagSettingsMonitor,ConflueraResourceGroup"


$config = $config -replace "`n","" -replace "`r","" # Remove line breaks

$config_arr = "$config" -split "###"


foreach ($conf in $config_arr) {
    if($conf -ne ""){
        $conf_arr = "$conf" -split ":::"
        $connection_string = $conf_arr[0]
        $unboarding_vars = $conf_arr[1]
        $unboarding_vars_arr = "$unboarding_vars" -split ","
        $subscriptionId = $unboarding_vars_arr[0]
        $conflueraDiagSettingsName = $unboarding_vars_arr[1]
        $rgName = $unboarding_vars_arr[2]
        $ConflueraDiagSettingsNameAD = $unboarding_vars_arr[3]
        az account set --subscription $subscriptionId > $null
        if(!$?)
        {
            Write-Host "Error: Failed connect subscription - "$subscriptionId -ForegroundColor Red
            continue;
        }
        Write-Host "Info: connected to subscription - "$subscriptionId
        az monitor diagnostic-settings subscription delete -n "$conflueraDiagSettingsName" -y > $null
        if(!$?)
        {
            Write-Host "Error: Failed remove diagnose settings - "$subscriptionId "/"$conflueraDiagSettingsName -ForegroundColor Red
            continue;
        }
        if ($ConflueraDiagSettingsNameAD -ne $null){
            $accessToken = az account get-access-token --resource=https://management.azure.com --query accessToken

            if(!$?)
            {
                Write-Host "Error get access token" -ForegroundColor Red
                continue;
            }
            $accessToken = $accessToken.Replace('"', '')
            $apiEndpoint = "https://management.azure.com/providers/microsoft.aadiam/diagnosticSettings/$ConflueraDiagSettingsNameAD`?api-version=2017-04-01-preview"

            $headers = @{
               "Authorization" = "Bearer $accessToken"
               "Content-Type" = "application/json"
            }

            $response = Invoke-RestMethod -Uri $apiEndpoint -Headers $headers -Method Delete
            if(!$?)
            {
                Write-Host "Error remove diagnose AD "$ConflueraDiagSettingsNameAD -ForegroundColor Red
                continue;
            }

        }
        az group delete --name $rgName -y
        if(!$?)
        {
            Write-Host "Error: Failed remove resource grope - "$subscriptionId "/"$rgName -ForegroundColor Red
            continue;
        }
    }
}