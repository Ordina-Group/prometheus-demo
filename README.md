# Monitoring with Prometheus Demo

## Running this demo

**Prerequisites**

* Docker
* Make

**Building and running**

```bash
$ make
```
## Voting App

For each vote,
the application will increment the counter of the Prometheus metric `votes_amount_total`.
The label `vote` is added and the value is set to the name of the vote.

**Metrics**

* `votes_amount_total{vote=<name>}` - Counter that returns the total amount of votes

**Endpoints**

* **POST `/api/vote`** - Make a vote
* **GET `/api/results`** - Fetch results
* **GET `/metrics`** - Returns the Prometheus metrics

```bash
$ curl -X POST -H 'Content-Type: application/json' \ 
-d '{"name":"prometheus"}' \
http://localhost:8000/api/vote

{
  "prometheus": {
    "count": 1
  }
}

$ curl -X GET http://localhost:8000/api/results

{
  "prometheus": {
    "count": 1
  },
  "go": {
    "count": 1
  }
}

```

## Voting Generator

The voting-generator app,
as the name suggests,
generates votes.
