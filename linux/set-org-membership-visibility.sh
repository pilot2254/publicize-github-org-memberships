#!/bin/bash
# Script to set the visibility of your membership in a specific GitHub organization

# Check for required dependencies
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        echo "Error: curl is not installed. Please install curl and try again."
        exit 1
    fi
}

# Function to display usage information
usage() {
    echo "Usage: $0 -t TOKEN -o ORGANIZATION -u USERNAME -v VISIBILITY [-k]"
    echo "  -t TOKEN        Your GitHub Personal Access Token with 'admin:org' scope"
    echo "  -o ORGANIZATION The name of the GitHub organization"
    echo "  -u USERNAME     Your GitHub username"
    echo "  -v VISIBILITY   The visibility setting: 'public' or 'private'"
    echo "  -k              Skip SSL certificate validation (optional)"
    echo "Example: $0 -t ghp_yourtokenhere -o EpicGames -u yourusername -v public"
    exit 1
}

# Check dependencies
check_dependencies

# Initialize variables
SKIP_CERT=false

# Process command line arguments
while getopts "t:o:u:v:k" opt; do
    case $opt in
        t) TOKEN="$OPTARG" ;;
        o) ORGANIZATION="$OPTARG" ;;
        u) USERNAME="$OPTARG" ;;
        v) VISIBILITY="$OPTARG" ;;
        k) SKIP_CERT=true ;;
        *) usage ;;
    esac
done

# Check if all required parameters are provided
if [ -z "$TOKEN" ] || [ -z "$ORGANIZATION" ] || [ -z "$USERNAME" ] || [ -z "$VISIBILITY" ]; then
    echo "Error: Missing required parameters."
    usage
fi

# Validate visibility parameter
if [ "$VISIBILITY" != "public" ] && [ "$VISIBILITY" != "private" ]; then
    echo "Error: Visibility must be either 'public' or 'private'."
    usage
fi

# Set up curl options
CURL_OPTS=(-s)
if [ "$SKIP_CERT" = true ]; then
    echo "Warning: Certificate validation will be skipped. This reduces security but may fix connection issues."
    CURL_OPTS+=(-k)
fi

# Set up headers for API requests
HEADERS=(
    -H "Accept: application/vnd.github.v3+json"
    -H "Authorization: token $TOKEN"
)

# Test API connection
echo "Testing connection to GitHub API..."
TEST_RESPONSE=$(curl "${CURL_OPTS[@]}" "${HEADERS[@]}" "https://api.github.com/user")
if [[ "$TEST_RESPONSE" == *"Bad credentials"* ]]; then
    echo "Error: Authentication failed. Check your token has the 'admin:org' scope."
    exit 1
fi

# Set membership visibility
if [ "$VISIBILITY" = "public" ]; then
    # Make membership public
    echo "Setting membership in $ORGANIZATION to public..."
    RESPONSE=$(curl "${CURL_OPTS[@]}" -o /dev/null -w "%{http_code}" -X PUT "${HEADERS[@]}" \
        -H "Content-Length: 0" \
        "https://api.github.com/orgs/$ORGANIZATION/public_members/$USERNAME")
    
    if [ "$RESPONSE" = "204" ]; then
        echo "Success! Your membership in $ORGANIZATION is now public."
    else
        echo "Error: Failed to set membership to public. HTTP status code: $RESPONSE"
        if [ "$RESPONSE" = "404" ]; then
            echo "Organization not found or you're not a member of $ORGANIZATION."
        elif [ "$RESPONSE" = "401" ]; then
            echo "Authentication failed. Check your token has the 'admin:org' scope."
        elif [ "$RESPONSE" = "403" ]; then
            echo "Forbidden. You might not have permission to modify this membership."
        fi
        exit 1
    fi
else
    # Make membership private
    echo "Setting membership in $ORGANIZATION to private..."
    RESPONSE=$(curl "${CURL_OPTS[@]}" -o /dev/null -w "%{http_code}" -X DELETE "${HEADERS[@]}" \
        "https://api.github.com/orgs/$ORGANIZATION/public_members/$USERNAME")
    
    if [ "$RESPONSE" = "204" ]; then
        echo "Success! Your membership in $ORGANIZATION is now private."
    else
        echo "Error: Failed to set membership to private. HTTP status code: $RESPONSE"
        if [ "$RESPONSE" = "404" ]; then
            echo "Organization not found, you're not a member, or your membership is already private."
        elif [ "$RESPONSE" = "401" ]; then
            echo "Authentication failed. Check your token has the 'admin:org' scope."
        elif [ "$RESPONSE" = "403" ]; then
            echo "Forbidden. You might not have permission to modify this membership."
        fi
        exit 1
    fi
fi