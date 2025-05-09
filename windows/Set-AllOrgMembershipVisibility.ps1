<#
.SYNOPSIS
    Sets the visibility of your membership in all GitHub organizations you belong to.
.DESCRIPTION
    This script uses the GitHub API to set your membership visibility in all organizations to either public or private.
.PARAMETER Token
    Your GitHub Personal Access Token with the 'admin:org' scope.
.PARAMETER Username
    Your GitHub username.
.PARAMETER Visibility
    The visibility setting: 'public' or 'private'.
.EXAMPLE
    .\Set-AllOrgMembershipVisibility.ps1 -Token "ghp_yourtokenhere" -Username "yourusername" -Visibility "public"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$Token,
    
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("public", "private")]
    [string]$Visibility
)

# Set TLS 1.2 for compatibility with GitHub API
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Headers for API requests
$headers = @{
    "Accept" = "application/vnd.github.v3+json"
    "Authorization" = "token $Token"
}

# Get all organizations the user belongs to
try {
    Write-Host "Fetching your organizations..." -ForegroundColor Yellow
    $orgsUri = "https://api.github.com/user/orgs?per_page=100"
    $organizations = Invoke-RestMethod -Uri $orgsUri -Method GET -Headers $headers
    
    if ($organizations.Count -eq 0) {
        Write-Host "You don't belong to any organizations." -ForegroundColor Yellow
        exit
    }
    
    Write-Host "Found $($organizations.Count) organizations." -ForegroundColor Cyan
    
    foreach ($org in $organizations) {
        $orgName = $org.login
        
        try {
            if ($Visibility -eq "public") {
                # Make membership public
                $uri = "https://api.github.com/orgs/$orgName/public_members/$Username"
                Write-Host "Setting membership in $orgName to public..." -ForegroundColor Yellow
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers
                Write-Host "Success! Your membership in $orgName is now public." -ForegroundColor Green
            }
            else {
                # Make membership private
                $uri = "https://api.github.com/orgs/$orgName/public_members/$Username"
                Write-Host "Setting membership in $orgName to private..." -ForegroundColor Yellow
                Invoke-RestMethod -Uri $uri -Method DELETE -Headers $headers
                Write-Host "Success! Your membership in $orgName is now private." -ForegroundColor Green
            }
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $errorMessage = $_.ErrorDetails.Message
            
            if ($statusCode -eq 404) {
                Write-Host "Error: Could not modify membership for '$orgName'. You might not have proper permissions." -ForegroundColor Red
            }
            elseif ($statusCode -eq 403) {
                Write-Host "Error: Forbidden for '$orgName'. You might not have permission to modify this membership." -ForegroundColor Red
            }
            else {
                Write-Host "Error with '$orgName': $statusCode - $errorMessage" -ForegroundColor Red
            }
        }
    }
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorMessage = $_.ErrorDetails.Message
    
    if ($statusCode -eq 401) {
        Write-Host "Error: Authentication failed. Check your token has the 'admin:org' scope." -ForegroundColor Red
    }
    else {
        Write-Host "Error: $statusCode - $errorMessage" -ForegroundColor Red
    }
}