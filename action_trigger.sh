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

# Get current repository info
REPO_INFO=$(gh repo view --json owner,name)
OWNER=$(echo "$REPO_INFO" | jq -r '.owner.login')
REPO=$(echo "$REPO_INFO" | jq -r '.name')

echo -e "${YELLOW}Repository: ${OWNER}/${REPO}${NC}"
echo -e "${YELLOW}Workflow: vault-demo.yaml${NC}"

# Trigger the workflow
echo -e "${YELLOW}Triggering workflow...${NC}"
if gh workflow run vault-demo.yaml; then
    echo -e "${GREEN}✅ Workflow triggered successfully!${NC}"
    
    # Wait a moment for the run to appear
    sleep 3
    
    # Show the latest run
    echo -e "${YELLOW}Latest workflow runs:${NC}"
    gh run list --workflow=vault-demo.yaml --limit=3
    
    # Get the latest run ID and provide a link to view it
    LATEST_RUN_ID=$(gh run list --workflow=vault-demo.yaml --limit=1 --json databaseId --jq '.[0].databaseId')
    if [ ! -z "$LATEST_RUN_ID" ]; then
        echo -e "${GREEN}🔗 View the run at: https://github.com/${OWNER}/${REPO}/actions/runs/${LATEST_RUN_ID}${NC}"
        
        # Option to watch the run
        echo -e "${YELLOW}Would you like to watch the run? (y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            gh run watch "$LATEST_RUN_ID"
        fi
    fi
else
    echo -e "${RED}❌ Failed to trigger workflow${NC}"
    exit 1
fi