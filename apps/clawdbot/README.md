# ClawdBot

ClawdBot deployment for Kubernetes using bjw-s app-template v4.0.1.

## Prerequisites

### 1. Build and Push Docker Image

You'll need to build the ClawdBot Docker image and push it to GitHub Container Registry (GHCR).

#### Build the Docker image locally

```bash
# From your clawdbot source directory
docker build -t ghcr.io/le-g/clawdbot:latest .
```

#### Authenticate to GHCR

```bash
# Create a GitHub Personal Access Token (PAT) with write:packages scope
# Then login:
echo $GITHUB_TOKEN | docker login ghcr.io -u le-g --password-stdin
```

#### Push the image

```bash
docker push ghcr.io/le-g/clawdbot:latest
```

#### Optional: Set up automated builds

Create a GitHub Actions workflow in your clawdbot repository to automatically build and push images:

```yaml
# .github/workflows/docker-build.yml
name: Build and Push Docker Image

on:
  push:
    branches: [main, master]
  release:
    types: [published]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v3

      - name: Log in to GHCR
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

### 2. Configure Secrets in Vault

Add the following secrets to your secrets backend (vault/1Password/etc.) that ExternalSecrets will sync:

```bash
# Gateway authentication token (generate a random hex token)
clawdbot.gateway-token: <random-64-char-hex-string>

# Claude credentials (optional but recommended for full functionality)
clawdbot.claude-ai-session-key: <your-session-key>
clawdbot.claude-web-session-key: <your-web-session-key>
clawdbot.claude-web-cookie: <your-cookie>
```

To generate a gateway token:
```bash
openssl rand -hex 32
```

### 3. Initial Onboarding (One-time Setup)

Before deploying to Kubernetes, you should run the onboarding process locally or in a temporary pod:

#### Option A: Local Docker onboarding (Recommended)

```bash
# Create local directories
mkdir -p ~/.clawdbot ~/clawd

# Run onboarding
docker run --rm -it \
  -v ~/.clawdbot:/home/node/.clawdbot \
  -v ~/clawd:/home/node/clawd \
  ghcr.io/le-g/clawdbot:latest \
  node dist/index.js onboard --no-install-daemon

# When prompted:
# - Gateway bind: lan
# - Gateway auth: token
# - Gateway token: <paste the token from your vault>
# - Tailscale exposure: Off
# - Install Gateway daemon: No
```

#### Option B: Kubernetes temporary pod

```bash
# Deploy the app first, then exec into the pod
kubectl -n apps exec -it deployment/clawdbot-gateway -- \
  node dist/index.js onboard --no-install-daemon
```

### 4. Provider Setup (Optional)

After onboarding, configure messaging providers:

#### WhatsApp (QR code)
```bash
kubectl -n apps exec -it deployment/clawdbot-gateway -- \
  node dist/index.js providers login
```

#### Telegram (bot token)
```bash
kubectl -n apps exec -it deployment/clawdbot-gateway -- \
  node dist/index.js providers add --provider telegram --token <token>
```

#### Discord (bot token)
```bash
kubectl -n apps exec -it deployment/clawdbot-gateway -- \
  node dist/index.js providers add --provider discord --token <token>
```

## Deployment

Once prerequisites are complete, ArgoCD will automatically deploy ClawdBot when you commit these files.

Or manually deploy:
```bash
helm dependency update apps/clawdbot
helm upgrade --install clawdbot apps/clawdbot -n apps --create-namespace
```

## Access

ClawdBot is accessible via private ingress at:

**https://clawdbot.le-g.dev**

This is a private URL (no external-dns annotation), accessible only from:
- Within your internal network
- Via Tailscale
- From devices that can resolve and reach your homelab

### Alternative access methods

From within the cluster:
```bash
curl http://clawdbot-gateway.apps.svc.cluster.local:18789/health
```

Port forward for local testing:
```bash
kubectl -n apps port-forward svc/clawdbot-gateway 18789:18789
```

## Health Check

```bash
kubectl -n apps exec deployment/clawdbot-gateway -- \
  node dist/index.js health --token "<your-gateway-token>"
```

## Logs

```bash
kubectl -n apps logs -f deployment/clawdbot-gateway
```

## Storage

- Config: 1Gi Longhorn PVC at `/home/node/.clawdbot`
- Workspace: 10Gi Longhorn PVC at `/home/node/clawd`

Adjust sizes in `values.yaml` if needed.

## Upgrading

To update to a new version:

1. Build and push new image with tag
2. Update image tag in values.yaml
3. Commit and push (ArgoCD will deploy)

Or for manual deployment:
```bash
helm upgrade clawdbot apps/clawdbot -n apps
```

## Troubleshooting

### Check pod status
```bash
kubectl -n apps get pods -l app.kubernetes.io/instance=clawdbot
```

### Check events
```bash
kubectl -n apps get events --field-selector involvedObject.name=clawdbot-gateway
```

### Verify secrets
```bash
kubectl -n apps get externalsecret clawdbot-secret
kubectl -n apps get secret clawdbot-secret
```

### Test gateway connection
```bash
kubectl -n apps exec deployment/clawdbot-gateway -- \
  curl -H "Authorization: Bearer $CLAWDBOT_GATEWAY_TOKEN" \
  http://localhost:18789/health
```

## References

- [ClawdBot Documentation](https://docs.clawd.bot/)
- [bjw-s app-template](https://github.com/bjw-s-labs/helm-charts/tree/main/charts/other/app-template)
