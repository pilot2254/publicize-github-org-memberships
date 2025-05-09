#!/bin/bash
# Script to set the visibility of your membership in multiple GitHub organizations

# Function to display usage information
usage() {
    echo "Usage: $0 -t TOKEN -o ORGANIZATIONS -u USERNAME -v VISIBILITY"
    echo "  -t TOKEN        Your GitHub Personal Access Token with 'admin:org' scope"
    echo "  -o ORGANIZATIONS Comma-separated list of GitHub organization names"
    echo "  -u USERNAME     Your GitHub username"
    echo "  -v VISIBILITY   The visibility setting: 'public' or 'private'"
    echo "Example: $0 -t ghp_yourtokenhere -o EpicGames,Microsoft,Google -u yourusername -v public"
    exit 1
}

# Process command line arguments
while getopts "t:o:u:v:" opt; do
    case $opt in
        t) TOKEN="$OPTARG" ;;
        o) ORGANIZATIONS="$OPTARG" ;;
        u) USERNAME="$OPTARG" ;;
        v) VISIBILITY="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if all required parameters are provided
if [ -z "$TOKEN" ] || [ -z "$ORGANIZATIONS" ] || [ -z "$USERNAME" ] || [ -z "$VISIBILITY" ]; then
    echo "Error: Missing required parameters."
    usage
fi

# Validate visibility parameter
if [ "$VISIBILITY" != "public" ] && [ "$VISIBILITY" != "private" ]; then
    echo "Error: Visibility must be either 'public' or 'private'."
    usage
fi

# Set up headers for API requests
HEADERS=(
    -H "Accept: application/vnd.github.v3+json"
    -H "Authorization: token $TOKEN"
)

# Split the organizations string into an array
IFS=',' read -ra ORG_ARRAY <<< "$ORGANIZATIONS"

# Process each organization
for ORG in "${ORG_ARRAY[@]}"; do
    # Trim whitespace
    ORG=$(echo "$ORG" | xargs)
    
    if [ "$VISIBILITY" = "public" ]; then
        # Make membership public
        echo "Setting membership in $ORG to public..."
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${HEADERS[@]}" \
            -H "Content-Length: 0" \
            "https://api.github.com/orgs/$ORG/public_members/$USERNAME")
        
        if [ "$RESPONSE" = "204" ]; then
            echo "Success! Your membership in $ORG is now public."
        else
            echo "Error: Failed to set membership in $ORG to public. HTTP status code: $RESPONSE"
            if [ "$RESPONSE" = "404" ]; then
                echo "Organization not found or you're not a member of $ORG."
            elif [ "$RESPONSE" = "401" ]; then
                echo "Authentication failed. Check your token has the 'admin:org' scope."
            elif [ "$RESPONSE" = "403" ]; then
                echo "Forbidden. You might not have permission to modify this membership."
            fi
        fi
    else
        # Make membership private
        echo "Setting membership in $ORG to private..."
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${HEADERS[@]}" \
            "https://api.github.com/orgs/$ORG/public_members/$USERNAME")
        
        if [ "$RESPONSE" = "204" ]; then
            echo "Success! Your membership in $ORG is now private."
        else
            echo "Error: Failed to set membership in $ORG to private. HTTP status code: $RESPONSE"
            if [ "$RESPONSE" = "404" ]; then
                echo "Organization not found, you're not a member, or your membership is already private."
            elif [ "$RESPONSE" = "401" ]; then
                echo "Authentication failed. Check your token has the 'admin:org' scope."
            elif [ "$RESPONSE" = "403" ]; then
                echo "Forbidden. You might not have permission to modify this membership."
            fi
        fi
    fi
    
    # Add a small delay to avoid rate limiting
    sleep 0.5
done