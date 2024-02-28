# `supabase-grafana`

Observability for your Supabase project, using Prometheus/Grafana, collecting [~200 metrics](./docs/metrics.md):

![./docs/supabase-grafana.png](./docs/supabase-grafana.png)

## Getting started

To run the collector locally using Docker Compose:

### Create secrets

Create an `.env` file:

```
cp .env.example .env
```

Fill it out with your project details. You'll need your project ref and service role key, which you can find [here](https://app.supabase.com/project/_/settings/api).
Alternatively, to monitor multiple projects you'll need to create an access token [here](https://supabase.com/dashboard/account/tokens).

### Access the dashboard

![./docs/supabase-grafana-prometheus.png](./docs/supabase-grafana-prometheus.png)

Visit [localhost:8000](https://localhost:8000) and login with the credentials:

- Username: `admin`
- Password: [the password in your `.env` file]

## Deploying

Deploy this service to a server which is always running to continuously collect metrics for your Supabase project.

```sh
docker build -t capgo/supabase-grafana:latest . 
docker push capgo/supabase-grafana:latest
```

