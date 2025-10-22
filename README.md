# canton-monitor-client
BASH script to send metrics to the API

## PREREQUISITES

```bash
sudo apt update && sudo apt install -y curl jq
```

## INSTALLATION

#### 1. SCRIPT LOCATION

* Upload the script to the same directory as where `splice-node` is located.
* In our examples below, `splice-node` is located inside `/root`:

```
|- /root
|  |- cantonmonitor.sh
|  |- splice-node/
```

* Set the credentials on top of the file to the values that you have received from us. Example:

```bash
KEY_ID="val_XXXXXX"
SECRET="<put-shared-secret-here>"

VERSION_URI=""
```

If variable `VERSION_URI` is set, an additional uptime check is enabled to verify if the validator (splice-node) is running. If your node is not reachable from the outside, use the internal URL to `/api/validator/version` mentioned in the [docs](https://docs.dev.sync.global/validator_operator/validator_helm.html) (e.g. `https://wallet.validator.<YOUR_HOSTNAME>/api/validator`). Leave it empty to disable the additional uptime check.

#### 2. CRONJOB

* Then, add a cronjob to execute the script every minute: `crontab -e`

```
* * * * * /bin/bash /root/cantonmonitor.sh >/dev/null 2>&1
```
