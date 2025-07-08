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

# subject claim: "repo:songlining/github-action-vault-demo:environment:dev"
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

#!/bin/bash

# List all entity IDs
entity_ids=$(vault list -format=json identity/entity/id | jq -r '.[]')

# Loop through each alias ID and read its details
for id in $entity_ids; do
  echo "Reading entity ID: $id"
  vault read -format=json identity/entity/id/$id | jq
  echo "-----------------------------"
done

# an Entity sample
{
  "request_id": "1c60caf9-b9b8-ccce-77a5-d2a6c0a6df87",
  "lease_id": "",
  "lease_duration": 0,
  "renewable": false,
  "data": {
    "aliases": [
      {
        "canonical_id": "91b1b7eb-7cea-16c6-3e90-47aa017d4bd6",
        "creation_time": "2025-07-08T23:32:06.620963077Z",
        "custom_metadata": null,
        "id": "3de5ede1-ea21-6665-ec67-b32bbbb92b7e",
        "last_update_time": "2025-07-08T23:32:06.620963077Z",
        "local": false,
        "merged_from_canonical_ids": null,
        "metadata": {
          "role": "myproject-github-role-dev"
        },
        "mount_accessor": "auth_jwt_35e55670",
        "mount_path": "auth/jwt/",
        "mount_type": "jwt",
        "name": "repo:songlining/github-action-vault-demo:environment:dev"
      }
    ],
    "creation_time": "2025-07-08T23:32:06.620955463Z",
    "direct_group_ids": [],
    "disabled": false,
    "group_ids": [],
    "id": "91b1b7eb-7cea-16c6-3e90-47aa017d4bd6",
    "inherited_group_ids": [],
    "last_update_time": "2025-07-08T23:32:06.620955463Z",
    "merged_entity_ids": null,
    "metadata": null,
    "name": "entity_c1cdc31c",
    "namespace_id": "root",
    "policies": []
  },
  "warnings": null,
  "mount_type": "identity"
}