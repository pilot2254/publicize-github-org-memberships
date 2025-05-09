<#
.SYNOPSIS
    Sets the visibility of your membership in a specific GitHub organization.
.DESCRIPTION
    This script uses the GitHub API to set your membership visibility in a specific organization to either public or private.
.PARAMETER Token
    Your GitHub Personal Access Token with the 'admin:org' scope.
.PARAMETER Organization
    The name of the GitHub organization.
.PARAMETER Username
    Your GitHub username.
.PARAMETER Visibility
    The visibility setting: 'public' or 'private'.
.PARAMETER SkipCertCheck
    Skip SSL certificate validation (use if you encounter certificate errors).
.EXAMPLE
    .\Set-OrgMembershipVisibility.ps1 -Token "ghp_yourtokenhere" -Organization "EpicGames" -Username "yourusername" -Visibility "public"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$Token,
    
    [Parameter(Mandatory=$true)]
    [string]$Organization,
    
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("public", "private")]
    [string]$Visibility,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipCertCheck
)

# Set TLS 1.2 for compatibility with GitHub API
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Skip certificate validation if requested
if ($SkipCertCheck) {
    Write-Host "Warning: Certificate validation will be skipped. This reduces security but may fix connection issues." -ForegroundColor Yellow
    
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # PowerShell 6+ has a built-in parameter
        $PSDefaultParameterValues['Invoke-RestMethod:SkipCertificateCheck'] = $true
    } else {
        # PowerShell 5.1 and below needs this workaround
        add-type @"
            using System.Net;
            using System.Security.Cryptography.X509Certificates;
            public class TrustAllCertsPolicy : ICertificatePolicy {
                public bool CheckValidationResult(
                    ServicePoint srvPoint, X509Certificate certificate,
                    WebRequest request, int certificateProblem) {
                    return true;
                }
            }
"@
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    }
}

# Headers for API requests
$headers = @{
    "Accept" = "application/vnd.github.v3+json"
    "Authorization" = "token $Token"
}

try {
    if ($Visibility -eq "public") {
        # Make membership public
        $uri = "https://api.github.com/orgs/$Organization/public_members/$Username"
        Write-Host "Setting membership in $Organization to public..." -ForegroundColor Yellow
        Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -ContentLength 0
        Write-Host "Success! Your membership in $Organization is now public." -ForegroundColor Green
    }
    else {
        # Make membership private
        $uri = "https://api.github.com/orgs/$Organization/public_members/$Username"
        Write-Host "Setting membership in $Organization to private..." -ForegroundColor Yellow
        Invoke-RestMethod -Uri $uri -Method DELETE -Headers $headers
        Write-Host "Success! Your membership in $Organization is now private." -ForegroundColor Green
    }
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorMessage = $_.ErrorDetails.Message
    
    if ($statusCode -eq 404) {
        Write-Host "Error: Organization not found or you're not a member of $Organization." -ForegroundColor Red
    }
    elseif ($statusCode -eq 401) {
        Write-Host "Error: Authentication failed. Check your token has the 'admin:org' scope." -ForegroundColor Red
    }
    elseif ($statusCode -eq 403) {
        Write-Host "Error: Forbidden. You might not have permission to modify this membership." -ForegroundColor Red
    }
    else {
        Write-Host "Error: $statusCode - $errorMessage" -ForegroundColor Red
        Write-Host "If you're experiencing certificate errors, try running the script with -SkipCertCheck" -ForegroundColor Yellow
    }
}