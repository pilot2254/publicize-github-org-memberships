<#
.SYNOPSIS
    Sets the visibility of your membership in multiple GitHub organizations.
.DESCRIPTION
    This script uses the GitHub API to set your membership visibility in multiple organizations to either public or private.
.PARAMETER Token
    Your GitHub Personal Access Token with the 'admin:org' scope.
.PARAMETER Organizations
    A comma-separated list of GitHub organization names.
.PARAMETER Username
    Your GitHub username.
.PARAMETER Visibility
    The visibility setting: 'public' or 'private'.
.EXAMPLE
    .\Set-MultipleOrgMembershipVisibility.ps1 -Token "ghp_yourtokenhere" -Organizations "EpicGames,Microsoft,Google" -Username "yourusername" -Visibility "public"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$Token,
    
    [Parameter(Mandatory=$true)]
    [string]$Organizations,
    
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

# Split the organizations string into an array
$orgArray = $Organizations -split ',' | ForEach-Object { $_.Trim() }

foreach ($org in $orgArray) {
    try {
        if ($Visibility -eq "public") {
            # Make membership public
            $uri = "https://api.github.com/orgs/$org/public_members/$Username"
            Write-Host "Setting membership in $org to public..." -ForegroundColor Yellow
            Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers
            Write-Host "Success! Your membership in $org is now public." -ForegroundColor Green
        }
        else {
            # Make membership private
            $uri = "https://api.github.com/orgs/$org/public_members/$Username"
            Write-Host "Setting membership in $org to private..." -ForegroundColor Yellow
            Invoke-RestMethod -Uri $uri -Method DELETE -Headers $headers
            Write-Host "Success! Your membership in $org is now private." -ForegroundColor Green
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.ErrorDetails.Message
        
        if ($statusCode -eq 404) {
            Write-Host "Error: Organization '$org' not found or you're not a member." -ForegroundColor Red
        }
        elseif ($statusCode -eq 401) {
            Write-Host "Error: Authentication failed for '$org'. Check your token has the 'admin:org' scope." -ForegroundColor Red
        }
        elseif ($statusCode -eq 403) {
            Write-Host "Error: Forbidden for '$org'. You might not have permission to modify this membership." -ForegroundColor Red
        }
        else {
            Write-Host "Error with '$org': $statusCode - $errorMessage" -ForegroundColor Red
        }
    }
}