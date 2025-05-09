#!/bin/bash
# Script to set the visibility of your membership in all GitHub organizations you belong to

# Function to display usage information
usage() {
    echo "Usage: $0 -t TOKEN -u USERNAME -v VISIBILITY"
    echo "  -t TOKEN        Your GitHub Personal Access Token with 'admin:org' scope"
    echo "  -u USERNAME     Your GitHub username"
    echo "  -v VISIBILITY   The visibility setting: 'public' or 'private'"
    echo "Example: $0 -t ghp_yourtokenhere -u yourusername -v public"
    exit 1
}

# Process command line arguments
while getopts "t:u:v:" opt; do
    case $opt in
        t) TOKEN="$OPTARG" ;;
        u) USERNAME="$OPTARG" ;;
        v) VISIBILITY="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if all required parameters are provided
if [ -z "$TOKEN" ] || [ -z "$USERNAME" ] || [ -z "$VISIBILITY" ]; then
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

# Get all organizations the user belongs to
echo "Fetching your organizations..."
ORGS_RESPONSE=$(curl -s "${HEADERS[@]}" "https://api.github.com/user/orgs?per_page=100")

# Check if the response is valid JSON
if ! echo "$ORGS_RESPONSE" | jq . > /dev/null 2>&1; then
    echo "Error: Failed to fetch organizations. Check your token and internet connection."
    exit 1
fi

# Extract organization names
ORG_NAMES=$(echo "$ORGS_RESPONSE" | jq -r '.[].login')

# Check if the user belongs to any organizations
if [ -z "$ORG_NAMES" ]; then
    echo "You don't belong to any organizations."
    exit 0
fi

# Count organizations
ORG_COUNT=$(echo "$ORG_NAMES" | wc -l)
echo "Found $ORG_COUNT organizations."

# Process each organization
echo "$ORG_NAMES" | while read -r ORG; do
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
                echo "Could not modify membership for $ORG. You might not have proper permissions."
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
                echo "Could not modify membership for $ORG. You might not have proper permissions or it's already private."
            elif [ "$RESPONSE" = "403" ]; then
                echo "Forbidden. You might not have permission to modify this membership."
            fi
        fi
    fi
    
    # Add a small delay to avoid rate limiting
    sleep 0.5
done