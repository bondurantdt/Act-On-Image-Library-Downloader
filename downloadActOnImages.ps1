$tokenurl = "https://restapi.actonsoftware.com/token"

# ActOn credentials
$client_id = Read-Host -Prompt "Please enter your ActOn Client ID"
$client_secret = Read-Host -Prompt "Please enter your ActOn Client Secret"
$username = Read-Host -Prompt "Please enter your ActOn Username"
$password = Read-Host -Prompt "Please enter your ActOn Password"

# Body for the token request
$tokenBody = @{
    grant_type = "password"
    username = $username
    password = $password
    client_id = $client_id
    client_secret = $client_secret
}

Write-Host $tokenBody

# Get the bearer token
$tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $tokenBody -ContentType 'application/x-www-form-urlencoded'
$accessToken = $tokenResponse.access_token

Write-Host "Access Token "$accessToken

$downloadPath = Read-Host "Please enter the full path where you would like to download the images to:"

#Get JSON list of images
$uri = "https://restapi.actonsoftware.com/api/1/image"
$headers=@{}
$headers.Add("accept", "application/json")
$headers.Add("Authorization", "Bearer $accessToken")
# Invoke the web request to the API
try {
    $response = Invoke-WebRequest -Uri $uri -Method Get -Headers $headers -ContentType 'application/json'
    
    # Save the response body to a file in the requested directory
    $response.Content | Out-File -FilePath "$downloadPath/ActOnImages.json"
    
    Write-Host "JSON data has been saved to $downloadPath/ActOnImages.json"
} catch {
    Write-Host "Failed to retrieve data: $_"
}
# Load JSON content from a file
$jsonContent = Get-Content -Path "$downloadPath/actonimages.json" -Raw

# Convert JSON string to PowerShell Object
$jsonObject = $jsonContent | ConvertFrom-Json

# Loop through each top-level group in the JSON
foreach ($group in $jsonObject) {
    # The directory name is derived from the 'name' field of each group
    $directoryName = $group.name -replace "[:\/\\*?""<>|]", ""  # Clean up name for invalid filename characters
    $directoryPath = Join-Path -Path "$downloadPath" -ChildPath $directoryName # Specify your base download path

    # Create directory if it does not exist
    if (-not (Test-Path -Path $directoryPath)) {
        New-Item -Path $directoryPath -ItemType Directory
    }

    # Loop through each entry in the 'entries' array
    foreach ($entry in $group.entries) {
        $fileUrl = $entry.url
        $fileName = $entry.name
        $filePath = Join-Path -Path $directoryPath -ChildPath $fileName

        # Download the file
        Invoke-WebRequest -Uri $fileUrl -OutFile $filePath
        Write-Host "Downloaded file: $fileName to $directoryPath"
    }
}