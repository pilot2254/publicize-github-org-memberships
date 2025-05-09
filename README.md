### GitHub Organization Membership Visibility Manager

This repository contains scripts to help you manage the visibility of your GitHub organization memberships. You can make your memberships public or private for specific organizations, multiple organizations, or all organizations you belong to.


## Why This Tool Exists

GitHub has a limit on displaying organization members in the UI (approximately 50k members). If you're part of a large organization like Epic Games with hundreds of thousands of members, it becomes impossible to find yourself in the members list to change your visibility status. These scripts use the GitHub API to directly modify your membership visibility without needing to use the GitHub UI.


## Table of Contents

- [Prerequisites](#prerequisites)
- [How to Create a Personal Access Token](#how-to-create-a-personal-access-token)
- [Windows Scripts (PowerShell)](#windows-scripts-powershell)
- [Linux/macOS Scripts (Bash)](#linuxmacos-scripts-bash)
- [Testing Your Scripts](#testing-your-scripts)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Contributing](#contributing)
- [License](#license)


## Prerequisites

- A GitHub Personal Access Token with the `admin:org` scope
- Your GitHub username
- For Linux/macOS scripts: `curl` installed (and `jq` for the all-organizations script)
- For Windows scripts: PowerShell 5.0 or higher


## How to Create a Personal Access Token

1. Go to GitHub and log in
2. Click on your profile picture in the top right corner
3. Select "Settings"
4. Scroll down and click on "Developer settings" (at the bottom of the left sidebar)
5. Click on "Personal access tokens" → "Tokens (classic)"
6. Click "Generate new token" → "Generate new token (classic)"
7. Give your token a descriptive name like "Organization Membership Manager"
8. For scopes, select "admin:org" (this gives access to manage organization settings)
9. Click "Generate token"
10. Copy the token immediately and save it somewhere secure - you won't be able to see it again!


## Windows Scripts (PowerShell)

### 1. Set Visibility for a Single Organization

```powershell
.\windows\Set-OrgMembershipVisibility.ps1 -Token "your_token" -Organization "OrgName" -Username "your_username" -Visibility "public"
```

If you encounter certificate validation issues:

```powershell
.\windows\Set-OrgMembershipVisibility.ps1 -Token "your_token" -Organization "OrgName" -Username "your_username" -Visibility "public" -SkipCertCheck
```

### 2. Set Visibility for Multiple Organizations

```powershell
.\windows\Set-MultipleOrgMembershipVisibility.ps1 -Token "your_token" -Organizations "Org1,Org2,Org3" -Username "your_username" -Visibility "public"
```

With certificate validation skipped:

```powershell
.\windows\Set-MultipleOrgMembershipVisibility.ps1 -Token "your_token" -Organizations "Org1,Org2,Org3" -Username "your_username" -Visibility "public" -SkipCertCheck
```

### 3. Set Visibility for All Organizations

```powershell
.\windows\Set-AllOrgMembershipVisibility.ps1 -Token "your_token" -Username "your_username" -Visibility "public"
```

With certificate validation skipped:

```powershell
.\windows\Set-AllOrgMembershipVisibility.ps1 -Token "your_token" -Username "your_username" -Visibility "public" -SkipCertCheck
```


## Linux/macOS Scripts (Bash)

First, make the scripts executable:

```shellscript
chmod +x linux/*.sh
```

### 1. Set Visibility for a Single Organization

```shellscript
./linux/set-org-membership-visibility.sh -t "your_token" -o "OrgName" -u "your_username" -v "public"
```

If you encounter certificate validation issues:

```shellscript
./linux/set-org-membership-visibility.sh -t "your_token" -o "OrgName" -u "your_username" -v "public" -k
```

### 2. Set Visibility for Multiple Organizations

```shellscript
./linux/set-multiple-org-membership-visibility.sh -t "your_token" -o "Org1,Org2,Org3" -u "your_username" -v "public"
```

With certificate validation skipped:

```shellscript
./linux/set-multiple-org-membership-visibility.sh -t "your_token" -o "Org1,Org2,Org3" -u "your_username" -v "public" -k
```

### 3. Set Visibility for All Organizations

```shellscript
./linux/set-all-org-membership-visibility.sh -t "your_token" -u "your_username" -v "public"
```

With certificate validation skipped:

```shellscript
./linux/set-all-org-membership-visibility.sh -t "your_token" -u "your_username" -v "public" -k
```


## Testing Your Scripts

Before using the scripts on your actual GitHub organizations, you can test them to ensure they work correctly:

### Testing Windows Scripts

1. Test the connection to GitHub API:

```powershell
$token = "your_token"
$headers = @{
    "Accept" = "application/vnd.github.v3+json"
    "Authorization" = "token $token"
}
Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers
```

2. If you encounter certificate errors, use the `-SkipCertCheck` parameter as shown in the examples above.


### Testing Linux/macOS Scripts

1. Test the connection to GitHub API:

```shellscript
token="your_token"
curl -s -H "Accept: application/vnd.github.v3+json" -H "Authorization: token $token" https://api.github.com/user
```

2. If you encounter certificate errors, use the `-k` parameter as shown in the examples above.


## Troubleshooting

### Common Issues and Solutions

#### Certificate Validation Errors

**Windows Error Message:**

```plaintext
Invoke-RestMethod : The underlying connection was closed: Could not establish trust relationship for the SSL/TLS secure channel.
```

or

```plaintext
curl: (35) schannel: next InitializeSecurityContext failed: CRYPT_E_NO_REVOCATION_CHECK (0x80092012) - The revocation function was unable to check revocation for the certificate.
```

**Solution:** Use the `-SkipCertCheck` parameter (Windows) or `-k` parameter (Linux/macOS).

#### Authentication Errors

**Error Message:**

```plaintext
401 - Bad credentials
```

**Solution:**

- Ensure your token is correct and hasn't expired
- Verify your token has the `admin:org` scope
- Create a new token if necessary


#### Organization Not Found

**Error Message:**

```plaintext
404 - Not Found
```

**Solution:**

- Double-check the organization name for typos
- Verify that you are a member of the organization
- Some organizations may require additional verification


#### Rate Limiting

**Error Message:**

```plaintext
403 - API rate limit exceeded
```

**Solution:**

- Wait for your rate limit to reset (usually one hour)
- The scripts include delays between requests to help avoid rate limiting


### Debugging

If you need more detailed information about what's happening:

**Windows:**

```powershell
$DebugPreference = "Continue"
```

**Linux/macOS:**

```shellscript
# Add -v to curl commands for verbose output
curl -v -H "Authorization: token $token" https://api.github.com/user
```

## Security Considerations

- **Never share your Personal Access Token**

- Tokens should be treated like passwords
- Don't commit tokens to version control
- Don't share tokens in screenshots or logs

- **Token Scope**

- The scripts only require the `admin:org` scope
- Avoid using tokens with more permissions than necessary

- **Token Lifecycle**

- Consider revoking the token after you're done using these scripts
- Set an expiration date when creating your token

- **Script Safety**

- These scripts do not store your token anywhere
- They only modify the visibility of your organization memberships
- They don't modify any other settings or data


## Contributing

Contributions are welcome! Here's how you can contribute:

1. Fork the repository
2. Create a new branch (`git checkout -b feature/your-feature-name`)
3. Make your changes
4. Test your changes thoroughly
5. Commit your changes (`git commit -m 'Add some feature'`)
6. Push to the branch (`git push origin feature/your-feature-name`)
7. Open a Pull Request


### Ideas for Contributions

- GUI interface for the scripts
- Support for additional platforms
- Additional features related to GitHub organization management
- Improved error handling and reporting
- Automated tests


## License

This project is licensed under the MIT License - see the LICENSE file for details.


## Acknowledgements

- Thanks to GitHub Support for providing the API guidance
- Special thanks to all contributors to this project

---

**Note:** This project is not affiliated with GitHub, Inc. GitHub is a registered trademark of GitHub, Inc.