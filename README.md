# Monitoring with Prometheus Demo

This project demonstrates the possibilities of monitoring with Prometheus.

# Overview

This project contains the following components:

* [Prometheus](https://prometheus.io)
* [Prommer](https://github.com/tomverelst/prommer) for custom target discovery
* [PromDash](https://github.com/prometheus/promdash)
* [cAdvisor](https://github.com/google/cadvisor) which exposes container metrics
* A voting app with a _RESTish_ API which exposes custom metrics for the votes
* A voting generator app that generates votes

## Running This Demo

**Prerequisites**

* [Docker](https://docker.com)
* Make

**Building and running**

```bash
$ make
```

All build steps are containerized with Docker.
After the build process,
all services are started with Docker Compose.

Stopping the demo can be done with the following command:

```bash
$ make stop
```

## Prometheus Server With Custom Service Discovery

The Prometheus server is configured to use [Prommer](https://github.com/tomverelst/prommer) as service discovery.
Prommer listens to the Docker events stream and updates the target groups configuration of Prometheus.


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
http://$(docker-compose port voting-app 8080)/api/vote

{
  "prometheus": {
    "count": 1
  }
}

$ curl -X GET http://$(docker-compose port voting-app 8080)/api/results

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
