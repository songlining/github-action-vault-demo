#!/bin/bash

# GitHub Action Trigger Script for Vault Demo
# This script triggers the vault-demo workflow using GitHub CLI

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo -e "${YELLOW}Usage: $0 [-a VAULT_URL] [-r ROLE_NAME] [-h]${NC}"
    echo -e "${YELLOW}Options:${NC}"
    echo -e "${YELLOW}  -a VAULT_URL    Specify Vault server URL${NC}"
    echo -e "${YELLOW}  -r ROLE_NAME    Specify Vault role name${NC}"
    echo -e "${YELLOW}  -h              Show this help message${NC}"
    echo -e "${YELLOW}${NC}"
    echo -e "${YELLOW}Environment Variables:${NC}"
    echo -e "${YELLOW}  VAULT_ADDR      Vault server URL (takes precedence over -a flag)${NC}"
    echo -e "${YELLOW}${NC}"
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "${YELLOW}  $0 -a https://vault.example.com:8200 -r myproject-github-role${NC}"
    echo -e "${YELLOW}  VAULT_ADDR=https://vault.example.com:8200 $0 -r production-role${NC}"
}

echo -e "${YELLOW}🚀 Triggering Vault Demo GitHub Action...${NC}"

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed.${NC}"
    echo -e "${YELLOW}Please install it from: https://cli.github.com/${NC}"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ Not authenticated with GitHub CLI.${NC}"
    echo -e "${YELLOW}Please run: gh auth login${NC}"
    exit 1
fi

# Parse command line options
VAULT_ADDR_FLAG=""
ROLE_NAME_FLAG=""
while getopts "a:r:h" opt; do
    case $opt in
        a)
            VAULT_ADDR_FLAG="$OPTARG"
            ;;
        r)
            ROLE_NAME_FLAG="$OPTARG"
            ;;
        h)
            usage
            exit 0
            ;;
        \?)
            echo -e "${RED}❌ Invalid option: -$OPTARG${NC}" >&2
            usage
            exit 1
            ;;
        :)
            echo -e "${RED}❌ Option -$OPTARG requires an argument.${NC}" >&2
            usage
            exit 1
            ;;
    esac
done

# Get VAULT_ADDR from environment variable or command line argument
VAULT_ADDR_INPUT=""
if [ ! -z "$VAULT_ADDR" ]; then
    echo -e "${GREEN}📍 Using VAULT_ADDR from environment variable: $VAULT_ADDR${NC}"
    VAULT_ADDR_INPUT="$VAULT_ADDR"
elif [ ! -z "$VAULT_ADDR_FLAG" ]; then
    echo -e "${GREEN}📍 Using VAULT_ADDR from command line argument: $VAULT_ADDR_FLAG${NC}"
    VAULT_ADDR_INPUT="$VAULT_ADDR_FLAG"
else
    echo -e "${RED}❌ VAULT_ADDR not found in environment variable and no -a flag provided.${NC}"
    usage
    exit 1
fi

# Get ROLE_NAME from command line argument (required)
ROLE_NAME_INPUT=""
if [ ! -z "$ROLE_NAME_FLAG" ]; then
    echo -e "${GREEN}🎭 Using role name: $ROLE_NAME_FLAG${NC}"
    ROLE_NAME_INPUT="$ROLE_NAME_FLAG"
else
    echo -e "${RED}❌ Role name not provided. Please use -r flag to specify the role name.${NC}"
    usage
    exit 1
fi

# Validate URL format (basic check)
if [[ ! "$VAULT_ADDR_INPUT" =~ ^https?:// ]]; then
    echo -e "${RED}❌ Invalid URL format. Please provide a valid HTTP/HTTPS URL.${NC}"
    echo -e "${YELLOW}Example: https://vault.example.com:8200${NC}"
    exit 1
fi

# Trigger the workflow with VAULT_ADDR and ROLE_NAME inputs
echo -e "${YELLOW}Triggering workflow with:${NC}"
echo -e "${YELLOW}  VAULT_ADDR: $VAULT_ADDR_INPUT${NC}"
echo -e "${YELLOW}  ROLE_NAME: $ROLE_NAME_INPUT${NC}"
if gh workflow run vault-demo.yaml --field vault_addr="$VAULT_ADDR_INPUT" --field role_name="$ROLE_NAME_INPUT"; then
    echo -e "${GREEN}✅ Workflow triggered successfully!${NC}"
    
    # Wait for the run to appear
    echo -e "${YELLOW}Waiting for workflow run to start...${NC}"
    sleep 5
    
    # Get the latest run ID
    LATEST_RUN_ID=$(gh run list --workflow=vault-demo.yaml --limit=1 --json databaseId --jq '.[0].databaseId')
    
    if [ ! -z "$LATEST_RUN_ID" ]; then
        echo -e "${GREEN}🔗 Run ID: ${LATEST_RUN_ID}${NC}"
        
        # Wait for the workflow run to complete
        echo -e "${YELLOW}Waiting for workflow run to complete...${NC}"
        gh run watch "$LATEST_RUN_ID" --exit-status

        echo -e "${YELLOW}Fetching logs...${NC}"
        gh run view "$LATEST_RUN_ID" --log
    fi
else
    echo -e "${RED}❌ Failed to trigger workflow${NC}"
    exit 1
fi