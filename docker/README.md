# 🧩 Canton Monitor Integration (Docker)

## 📄 1. Installation

* Create directory `cantonmonitor` 
	* (Or pull this Git repository)
* Download `docker-compose.yml` from this repository to your server
	* (Or just copy paste)
* Put an `.env` file next to it with contents:
	* See file `.env-example` for more optional settings

```
CM_VALIDATOR_ID="val_XXXXXX"
CM_SECRET="replace-with-your-secret"
```

## 💡 2. Execution

* Bring the container up and check the logs:

```
docker compose up -d
docker compose logs -f cantonmonitor-agent
```
