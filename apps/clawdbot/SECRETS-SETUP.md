# ClawdBot Secrets Setup - Manual Method

## Quick Setup

Run these commands to manually create the secrets in your Kubernetes cluster:

### 1. Generate and Create Gateway Token

```bash
# Generate a random 64-character hex token and create the secret
kubectl -n global-secrets create secret generic clawdbot.gateway-token \
  --from-literal=gateway-token="$(openssl rand -hex 32)"
```

### 2. Add Claude Credentials (Optional)

If you want to use Claude API features, add your credentials:

```bash
kubectl -n global-secrets create secret generic clawdbot.claude-ai-session-key \
  --from-literal=claude-ai-session-key="your-session-key-here"

kubectl -n global-secrets create secret generic clawdbot.claude-web-session-key \
  --from-literal=claude-web-session-key="your-web-session-key-here"

kubectl -n global-secrets create secret generic clawdbot.claude-web-cookie \
  --from-literal=claude-web-cookie="your-cookie-here"
```

**How to get Claude credentials:**
1. Open Claude.ai in your browser (logged in)
2. Open Developer Tools (F12)
3. Go to Application/Storage → Cookies
4. Find and copy the session values

### 3. Verify Secrets

```bash
# Check secrets were created
kubectl -n global-secrets get secrets | grep clawdbot

# Should show:
# clawdbot.gateway-token
# clawdbot.claude-ai-session-key (if created)
# clawdbot.claude-web-session-key (if created)
# clawdbot.claude-web-cookie (if created)
```

### 4. Deploy ClawdBot

```bash
cd apps/clawdbot
helm dependency update
helm upgrade --install clawdbot . -n apps --create-namespace
```

### 5. Verify ExternalSecret is Working

```bash
# Check ExternalSecret status
kubectl -n apps get externalsecret clawdbot-secret

# Should show: STATUS=SecretSynced, READY=True

# Check the synced secret
kubectl -n apps get secret clawdbot-secret
kubectl -n apps describe secret clawdbot-secret
```

### 6. Retrieve Your Gateway Token

To get the gateway token value (for connecting clients):

```bash
kubectl -n global-secrets get secret clawdbot.gateway-token \
  -o jsonpath='{.data.gateway-token}' | base64 -d && echo
```

**Save this token!** You'll need it to connect messaging providers to your ClawdBot gateway.

## Troubleshooting

### ExternalSecret not syncing

Check if the source secrets exist:
```bash
kubectl -n global-secrets get secrets | grep clawdbot
```

Check ExternalSecret status:
```bash
kubectl -n apps describe externalsecret clawdbot-secret
```

### Update a secret value

```bash
# Delete and recreate the secret
kubectl -n global-secrets delete secret clawdbot.gateway-token
kubectl -n global-secrets create secret generic clawdbot.gateway-token \
  --from-literal=gateway-token="$(openssl rand -hex 32)"

# ExternalSecret will automatically sync the new value within 1 hour
# Or force immediate sync by deleting the target secret:
kubectl -n apps delete secret clawdbot-secret
# It will be recreated automatically within seconds
```

## Summary

**Setup Checklist:**

1. ✅ Create `clawdbot.gateway-token` secret in `global-secrets` namespace
2. ☐ (Optional) Create Claude credential secrets in `global-secrets` namespace
3. ☐ Deploy ClawdBot app
4. ☐ Verify ExternalSecret is syncing
5. ☐ Retrieve and save gateway token for connections

That's it! Your secrets are now manually managed in the cluster.
