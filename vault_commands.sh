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

vault write auth/jwt/role/myproject-github-role -<<EOF
{
  "role_type": "jwt",
  "user_claim": "aud",
  "bound_audiences": ["https://github.com/songlining/github-action-vault-demo__dev"],
  "bound_claims": {
    "repository": "songlining/github-action-vault-demo"
  },
  "policies": ["myproject-policy"],
  "ttl": "10m"
}
EOF

#!/bin/bash

# List all entity IDs
alias_ids=$(vault list -format=json identity/entity/id | jq -r '.[]')

# Loop through each alias ID and read its details
for id in $alias_ids; do
  echo "Reading entity alias ID: $id"
  vault read -format=json identity/entity/id/$id | jq
  echo "-----------------------------"
done
