# Explanation Custom Variables

Subject: `https://github.com/ALUMLABS/i-can-monitor-client/blob/main/docker/.env-example`

The **optional** environment variables below are to customize the iCanMonitor client: 

```bash
# Optional
# DOCKER_NETWORK=splice-validator_splice_validator
# BACKEND_BASE=https://api.cantonmonitor.com
# VERSION_URI=http://validator:5003/api/validator/version
# TIMEOUT=6
# INSECURE=0
# POST_PATH=/health
```

#### DOCKER_NETWORK

If you did not customize your Canton Docker setup, you do NOT need to change anything. But if you do have a custom Docker network, do this to find your validator's network:

```bash
root@alumlabs:~# docker network ls
NETWORK ID     NAME                                DRIVER    SCOPE
94de16628941   bridge                              bridge    local
1af49b15f0d2   host                                host      local
0deb2a54c152   none                                null      local
d0b649c34c51   splice-validator_default            bridge    local
3db8ca20433e   splice-validator_splice_validator   bridge    local
```

#### BACKEND_BASE

This is just the URL of our backend API where the monitoring client sends its metrics. If you run our on-prem installation (Enterprise only), change this variable to your own backend API.

#### VERSION_URI

Our monitoring docker container is attached to the same Docker Network as your validator (see DOCKER_NETWORK). Because they are on the same network, our monitoring client can find the validator's version via this URL: `http://validator:5003/api/validator/version`. 

If you did not customize your Canton Docker setup, the default value should be enough. Keep it commented out of the box. But if you did change your setup and are for example working with a reverse proxy and exposing your `/api` endpoint to the internet, you could change this variable to a custom value such as the publicly available URI. E.g. `https://node17.alumlabs.io/api/validator/version`.

#### TIMEOUT

How long to keep waiting when posting the metrics to our backend. If our backend API is offline, after 6 seconds, the POST request will timeout. 

#### INSECURE

If you use HTTPS with self-signed certificates, you might have to toggle this one to `1` to allow the acceptance of unverified SSL certificates.

#### POST_PATH

If you use a custom backend and not ours, you might have to change the API endpoint to which the monitor sends its metrics. 