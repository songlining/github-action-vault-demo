# GitHub Action Vault Demo
A demonstration project showcasing how to securely retrieve secrets from HashiCorp Vault using GitHub Actions with OIDC (OpenID Connect) authentication. 

## 🎯 Overview
This repository demonstrates:

- OIDC Authentication : Secure, keyless authentication between GitHub Actions and Vault
- Environment-Specific Access : Different Vault roles and policies for different environments (dev, staging, production)
- Secret Retrieval : Safe retrieval and usage of secrets in GitHub Actions workflows
- Automated Workflow Triggering : Command-line script for easy workflow execution
## 📁 Project Structure
```
├── .github/workflows/
│   └── vault-demo.yaml          # Main GitHub Actions workflow
├── action_trigger.sh             # Script to trigger the workflow via GitHub CLI
├── vault_commands.sh             # Vault configuration commands
└── README.md                     # This file
```
## 🚀 Features
### GitHub Actions Workflow (vault-demo.yaml)
- Manual Trigger : Workflow dispatch with configurable inputs
- Environment Context : Dynamic environment assignment for OIDC token differentiation
- Secure Authentication : Uses GitHub's OIDC provider for keyless Vault authentication
- Secret Masking : Demonstrates proper handling of retrieved secrets
### Workflow Trigger Script (action_trigger.sh)
- Command-line Interface : Easy workflow triggering with parameters
- Input Validation : Validates Vault URL format and required parameters
- Real-time Monitoring : Watches workflow execution and displays logs
- Flexible Configuration : Supports environment variables and command-line flags
### Vault Configuration (vault_commands.sh)
- JWT Auth Setup : Configures Vault for GitHub OIDC authentication
- Environment-Specific Roles : Creates roles bound to specific environments
- Policy Management : Defines granular access policies for secrets
- Entity Management : Scripts for inspecting Vault entities and aliases
## 🔧 Setup Instructions
### Prerequisites
1. HashiCorp Vault Server : Running and accessible
2. GitHub CLI : Installed and authenticated ( gh auth login )
3. Vault CLI : Installed and configured
4. GitHub Repository : With Actions enabled
### 1. Configure Vault
Setup a Vault server that github can access and run the following commands to set it up

```
# 1. Enable JWT auth method 
vault auth enable jwt

# 2. Setup the kv-v2 secret engine
vault secrets enable kv-v2

# this is the secret the pipeline is going to retrieve
vault kv put kv-v2/myapp username="demo-user" password="secure-password"

# 3. Configure JWT auth method for GitHub
vault write auth/jwt/config \
  bound_issuer="https://token.actions.githubusercontent.com" \
  oidc_discovery_url="https://token.actions.githubusercontent.com"

# 4. Create a policy for your secrets
vault policy write myproject-policy - <<EOF
# Read-only permission on your secret path
path "kv-v2/data/myapp" {
  capabilities = [ "read" ]
}
EOF

# 5. Create a role for your secrets
vault write auth/jwt/role/myproject-github-role-dev -<<EOF
{
  "role_type": "jwt",
  "user_claim": "sub",
  "bound_audiences": ["https://github.com/songlining/github-action-vault-demo"],
  "bound_claims": {
    "repository": "songlining/github-action-vault-demo",
    "environment": "dev"
  },
  "policies": ["myproject-policy"],
  "ttl": "10m"
}
EOF

```

### 2. Configure GitHub Repository
Ensure your repository has:

- GitHub Environments : Create environments (dev, staging, production) in repository settings
- OIDC Permissions : The workflow already includes required permissions
## 🎮 Usage
### Method 1: Using the Trigger Script (Recommended)
```
# Make the script executable
chmod +x action_trigger.sh

# Trigger workflow for development environment
./action_trigger.sh -a https://your-vault-server:8200 -r myproject-github-role-dev -e dev

# Trigger workflow for production environment
./action_trigger.sh -a https://your-vault-server:8200 -r myproject-github-role-prod -e production

# Using environment variable for Vault address
VAULT_ADDR=https://your-vault-server:8200 ./action_trigger.sh -r myproject-github-role-dev -e dev
```
### Method 2: Manual GitHub Actions Trigger
1. Go to your repository's Actions tab
2. Select Vault Secret Retrieval workflow
3. Click Run workflow
4. Fill in the required inputs:
   - Vault server URL : Your Vault server address
   - Vault role name : The role configured in Vault
   - Environment : Target environment (dev, staging, production)
## 🔐 Security Features
### OIDC Authentication Flow
1. GitHub generates OIDC token with claims including:
   
   - Repository information
   - Environment context
   - Workflow details
2. Vault validates token against:
   
   - Bound audiences (repository URL)
   - Bound claims (repository, environment)
   - Token signature and expiration
3. Environment-specific access through:
   
   - Different Vault roles per environment
   - Environment-specific policies
   - OIDC token's environment claim
### Subject Claim Format
The OIDC token's sub claim follows this format:

```
repo:{owner}/{repo}:environment:{environment}
```
Example: repo:songlining/github-action-vault-demo:environment:dev

## 🛠️ Troubleshooting
### Debug Commands
```
# Check Vault auth methods
vault auth list

# List JWT roles
vault list auth/jwt/role

# Read specific role configuration
vault read auth/jwt/role/myproject-github-role-dev

# Check Vault entities (after successful authentication)
vault list identity/entity/id
```
## 📚 Key Concepts
- OIDC (OpenID Connect) : Standard for secure, keyless authentication
- JWT (JSON Web Token) : Token format used by GitHub's OIDC provider
- Vault Entity : Represents an authenticated principal in Vault
- Vault Alias : Links external identity (GitHub) to Vault entity
- Environment Context : GitHub feature for deployment environments
## 🤝 Contributing
Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## 📄 License
This project is provided as-is for demonstration purposes.

Note : This is a demonstration project. In production environments, ensure proper security reviews, use appropriate Vault policies, and follow your organization's security guidelines.