
Write-Host "Azure account - " ${env:AZURE_STORAGE_ACCOUNT} ", Container - " ${env:AZ_CONTAINER_NAME}
$ctx = New-AzStorageContext -StorageAccountName ${env:AZURE_STORAGE_ACCOUNT} -StorageAccountKey ${env:AZURE_STORAGE_KEY}

$maxResult = 10000
$idxResult = 1
$cntTotal = 0
$cntNonArch = 0
$nextToken = $Null
Write-Host "Listing non Archive tier blobs by $maxResult per page..."
Do 
{
    Write-Host "Listing non Archive tier blobs from $idxResult to " ($idxResult + $maxResult - 1) "..."
    $blobs = Get-AzStorageBlob -Container ${env:AZ_CONTAINER_NAME} -Context $ctx -MaxCount $maxResult -ContinuationToken $nextToken
    if ($blobs.Length -le 0) { break; }

    $cntTotal += $blobs.Count
    $nextToken = $blobs[$blobs.Count - 1].ContinuationToken
    Write-Host "Blobs found -" $blobs.Count ", Total count -" $cntTotal ", Next page token - " 
    $nextToken

    $naBlobs = $blobs | Where { $_.ICloudBlob.Properties.StandardBlobTier -ne 'Archive' }
    $cntNonArch += $naBlobs.Count
    Write-Host "Non Archive tier blobs found -" $naBlobs.Count ", Total non Archive tier blobs -" $cntNonArch

    $idxResult += $maxResult

    if ($naBlobs.Count -gt 0)
    {
        Write-Host "Setting Archive tier for -" $naBlobs.Count "blobs..."
        $naBlobs.ICloudBlob.SetStandardBlobTier("Archive")
        Write-Host "Set Archive tier finished."
    }
} 
While ($nextToken -ne $Null)
Write-Host "Total blobs -" $cntTotal ", Blobs set Archive tier -" $cntNonArch
