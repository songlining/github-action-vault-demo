# 1. Enable JWT auth method
vault auth enable jwt

# 2. Configure JWT auth method for GitHub
vault write auth/jwt/config \
  bound_issuer="https://token.actions.githubusercontent.com" \
  oidc_discovery_url="https://token.actions.githubusercontent.com"

# 3. Create a policy for your secrets
vault policy write myproject-policy - <<EOF
# Read-only permission on your secret path
path "kv-v2/data/myapp" {
  capabilities = [ "read" ]
}
EOF

# 4. Create a role that binds to your GitHub repository
vault write auth/jwt/role/myproject-github-role -<<EOF
{
  "role_type": "jwt",
  "user_claim": "actor",
  "bound_claims": {
    "repository": "your-username/github-action-vault-demo"
  },
  "policies": ["myproject-policy"],
  "ttl": "10m"
}
EOF