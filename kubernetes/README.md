# 🧩 Canton Monitor Integration (Kubernetes)

This integration lets your validator running on Kubernetes report uptime and system metrics to **[cantonmonitor.com](https://cantonmonitor.com)**. There’s no need to modify or rebuild your Helm release. Our YAML file is a clean “addon manifest”. And since it's isolated: zero-risk, and it requires no Helm edits or pod-level tinkering.

### 🔐 1. Create secrets for Canton Monitor

Create a Kubernetes Secret that holds your validator ID and the SECRET:

```bash
# Replace values accordingly
kubectl -n validator create secret generic cantonmonitor-secrets \
  --from-literal=CM_VALIDATOR_ID="val_XXXXXX" \
  --from-literal=CM_SECRET="replace-with-your-secret"
```

- The CronJob/sidecar reads:
  - `KEY_ID` from `cantonmonitor-secrets: CM_VALIDATOR_ID`
  - `SECRET` from `cantonmonitor-secrets: CM_SECRET`

If you need to rotate the secret later:

```bash
kubectl -n validator delete secret cantonmonitor-secrets
kubectl -n validator create secret generic cantonmonitor-secrets \
  --from-literal=CM_VALIDATOR_ID="val_XXXXXX" \
  --from-literal=CM_SECRET="new-secret"
kubectl -n validator rollout restart deploy/validator-app
```

### 📄 2. Installation

1. **Download the CronJob manifest** 
   ```bash
   curl -O https://github.com/ALUMLABS/canton-monitor-client/raw/refs/heads/main/kubernetes/cantonmonitor-cronjob.yaml
   ```

2. **Edit the file if needed**
   - Ensure the correct namespace is set (default: `validator`).
   - Confirm the internal Canton API endpoint:
     ```yaml
     VERSION_URI: "http://validator-app:5003/api/validator/version"
     ```
     Adjust if your validator service has a different name or port.

3. **Apply once**
   ```bash
   kubectl apply -f cantonmonitor-cronjob.yaml -n validator
   ```

4. **Verify**
   ```bash
   kubectl -n validator get cronjobs
   kubectl -n validator get jobs
   kubectl -n validator logs job/<recent-job-name>
   ```

That’s it — the CronJob runs every minute, collects metrics from the pod (CPU, RAM, disk, uptime), queries your validator’s version API, and posts to the Canton Monitor backend.

### 🧼 Updating or removing

- **Update**
  ```bash
  kubectl apply -f cantonmonitor-cronjob.yaml -n validator
  ```
- **Remove**
  ```bash
  kubectl delete -f cantonmonitor-cronjob.yaml -n validator
  ```

### 💡 Notes

- No changes to your Helm chart or validator containers are required.  
- Secrets (`KEY_ID`, `SECRET`) must exist in a Kubernetes Secret named `cantonmonitor-secrets`.  
- Uses minimal resources (<100 MiB RAM, <0.1 CPU).  
- Runs in a regular namespace; no cluster-admin privileges needed.
