Param(
    [object]$WebhookData
)

[string]$callBackUri
[string]$connectionName
[string]$storageAccountKey
[string]$callBackBodyPass
[string]$callBackBodyFail

if($WebhookData){
    $parameters=(ConvertFrom-Json -InputObject $WebhookData.RequestBody)
    if($parameters.connectionName) {$connectionName = $parameters.connectionName} 
    if($parameters.callBackUri) {$callBackUri = $parameters.callBackUri} 
    if($parameters.storageAccountKey) {$storageAccountKey = $parameters.storageAccountKey} 
}

#$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         
 
    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
 
Write-Output "Environment variable" + $env:TEMP
 
$ctx = New-AzureStorageContext -StorageAccountName "bloblogicapps1" -StorageAccountKey $storageAccountKey
 
$LogFull = "sourcefile" 
$LogItem = New-Item -ItemType Directory -Name $LogFull
 
$resultLogFull = "result" 
$resultLogItem = New-Item -ItemType Directory -Name $resultLogFull

$callBackBodyPass = "@{
    Output: {
        // output object will be used in activity output
        testProp: 'testPropValue'
    },
    StatusCode: '200' // when status code is >=400, activity will be marked as failed
}" | ConvertTo-Json

$callBackBodyFail = "@{
    Output: {
        // output object will be used in activity output
        testProp: 'testPropValue'
    },
    Error: {
        // Optional, set it when you want to fail the activity
        ErrorCode: '500001',
        Message: 'Error occured while unzipping'
    },
    StatusCode: '403' // when status code is >=400, activity will be marked as failed
}" | ConvertTo-Json
 
try
{
    $download = Get-AzureStorageBlobContent -Blob "20200226-023303_LOMU_AfmsDWH_dbo_DimProduct.dat.7z" -Container "zipped" -Destination $logfull -Context $ctx

    #Write-Output $download
    Write-Output "Download complete" 

    #deflate zip file
    $sourcepath = $logfull + "\20200226-023303_LOMU_AfmsDWH_dbo_DimProduct.dat.7z"
    Expand-7Zip -ArchiveFileName $sourcepath -TargetPath $resultLogFull
    
    Get-ChildItem -Path $resultLogFull -Recurse | Set-AzureStorageBlobContent -Container "unzipped" -Context $ctx -Force
    
    #Callback
    if($callBackUri)
    {
        Write-Output "Calling success Callback" 
        Invoke-WebRequest -Uri $callBackUri -UseBasicParsing
    }
}
catch
{
    Write-Output "Error"
    #Callback
    if($callBackUri)
    {
        Write-Output "Calling failure Callback" 
        Invoke-WebRequest -Uri $callBackUri -UseBasicParsing -Method POST -Body $callBackBodyFail
    }
}
 
 




