#!/bin/bash

# GitHub Action Trigger Script for Vault Demo
# This script triggers the vault-demo workflow using GitHub CLI

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Get VAULT_ADDR from environment variable or command line argument
VAULT_ADDR_INPUT=""
if [ ! -z "$VAULT_ADDR" ]; then
    echo -e "${GREEN}📍 Using VAULT_ADDR from environment variable: $VAULT_ADDR${NC}"
    VAULT_ADDR_INPUT="$VAULT_ADDR"
elif [ ! -z "$1" ]; then
    echo -e "${GREEN}📍 Using VAULT_ADDR from command line argument: $1${NC}"
    VAULT_ADDR_INPUT="$1"
else
    echo -e "${RED}❌ VAULT_ADDR not found in environment variable and no command line argument provided.${NC}"
    echo -e "${YELLOW}Usage: $0 [VAULT_URL]${NC}"
    echo -e "${YELLOW}Or set VAULT_ADDR environment variable${NC}"
    exit 1
fi

# Validate URL format (basic check)
if [[ ! "$VAULT_ADDR_INPUT" =~ ^https?:// ]]; then
    echo -e "${RED}❌ Invalid URL format. Please provide a valid HTTP/HTTPS URL.${NC}"
    echo -e "${YELLOW}Example: https://vault.example.com:8200${NC}"
    exit 1
fi

# Trigger the workflow with VAULT_ADDR input
echo -e "${YELLOW}Triggering workflow with VAULT_ADDR: $VAULT_ADDR_INPUT${NC}"
if gh workflow run vault-demo.yaml --field vault_addr="$VAULT_ADDR_INPUT"; then
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