$SK = "CDQYnpg3CUC0oVaR9CTKMJtf7rYiQ5U1" # Update the value everyday
$AppVersionID = "appv-1ji83rdf"
$Token = "aXsGdwTcw0wOulmBAmYTnYRWrU8T0VFQ" 

[System.Uri]$Uri = "https://appcenter.qingcloud.com/api/" # Add the Uri
$Method = 'POST'
$WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession

$Cookie = New-Object System.Net.Cookie
$Cookie.Name = "lang" 
$Cookie.Value = "en" 
$Cookie.Domain = $uri.DnsSafeHost
$WebSession.Cookies.Add($Cookie)

$Cookie = New-Object System.Net.Cookie
$Cookie.Name = "csrftoken" 
$Cookie.Value = $Token 
$Cookie.Domain = $uri.DnsSafeHost
$WebSession.Cookies.Add($Cookie)

$Cookie = New-Object System.Net.Cookie
$Cookie.Name = "sk" 
$Cookie.Value = $SK
$Cookie.Domain = $uri.DnsSafeHost
$WebSession.Cookies.Add($Cookie)

$Headers = @{
    'Accept' = 'application/json, text/javascript, */*'
    'Accept-Encoding' = 'gzip, deflate, br'
    'X-CSRFToken' = $Token
    'cache-control' = 'no-cache'
}

# We need a boundary (something random() will do best)
$boundary = [System.Guid]::NewGuid().ToString()

# Linefeed character
$LF = "`r`n"

#$fileName = $AppVersionID +".zip"
$fileName = ((Get-Date).tostring("dd-MM-yyyy-hh-mm-ss")+".zip")
$zipfilename = $PWD.Path + "\"+ $fileName
function ZipAppFolder {
    $sourcedir = ".\app"
    if(Test-Path $zipfilename) {
        Remove-Item -Path $zipfilename
    }
    Add-Type -Assembly System.IO.Compression.FileSystem
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
    [System.IO.Compression.ZipFile]::CreateFromDirectory($sourcedir,$zipfilename, $compressionLevel, $false)
}

function ZipAppFolderusing7Zip {
    $app = 'C:\Program Files\7-Zip\7z.exe'
    $arg1 = 'a'
    $arg2 = '-tzip'
    $folderLocation = '"..\app\*"'
    & $app $arg1 $arg2 $arg3 $zipFileName $folderLocation
}

# Create the Zip of App folder
ZipAppFolderusing7Zip
$AttachmentContent = [Convert]::ToBase64String([IO.File]::ReadAllBytes($zipfilename))
#[IO.File]::WriteAllBytes($zipfilename, [Convert]::FromBase64String($AttachmentContent))

# Build Body for our form-data manually since PS does not support multipart/form-data out of the box
$bodyLines = (
    "--$boundary",
    "Content-Disposition: form-data; name=`"params`"",
    "$LF{`"resource_id`":`"$AppVersionID`",`"resource_type`":`"app_version`",`"filext`":`"zip`",`"category`":`"resource_kit`",`"attachment_type`":`"archive`",`"attachment_content`":`"$AttachmentContent`",`"filename`":`"$fileName`",`"action`":`"UploadCommonAttachment`"}",
    "--$boundary--$LF"
 ) -join $LF
 
# Splat the parameters
$props = @{
    Uri         = $uri.AbsoluteUri
    Headers     = $Headers
    ContentType = "multipart/form-data; boundary=`"$boundary`""
    Method      = $Method
    WebSession  = $WebSession
    Body        = $bodyLines
}

try {
    $Response = Invoke-RestMethod @props

    If (-NOT  ($Response.ret_code -eq 0)) {
        throw $Response.message
        return
    }

    Write-Output "Content testing passed..."
    return
}
# In case of emergency...
catch [System.Net.WebException] {
    Write-Error( "REST-API-Call failed for '$URL': $_" )
    throw $_
    return
}
