# Monitoring with Prometheus Demo

This project demonstrates the possibilities of monitoring with Prometheus.

# Overview

This project contains the following components:

* [Prometheus](https://prometheus.io)
* [Prommer](https://github.com/tomverelst/prommer) for custom target discovery
* [Alert Manager](https://github.com/prom/alertmanager) for managing alerts
* [Grafana](http://grafana.org/) for metric and analytic dashboards
* [cAdvisor](https://github.com/google/cadvisor) for exposing container and host metrics
* A voting app with a _RESTish_ API which exposes custom metrics for the votes
* A voting generator app that generates votes
* An alert console that displays the alerts

## Running This Project

**Prerequisites**

* [Docker](https://docker.com)
* Make

**Building and running**

The project can be completely built and run with the default `make` command.


```bash
$ make
```

All build steps are containerized with Docker.
After the build process,
all services are started with Docker Compose.

To stop all services, use the `stop` command:

```bash
$ make stop
```

To clean the project,
use the `clean` command.
This will remove all built binaries and images.
Note that this will not remove any third-party images (like cAdvisor) that were pulled in.

```bash
$ make clean
```

## Prometheus Server With Custom Service Discovery

The Prometheus server is configured to use [Prommer](https://github.com/tomverelst/prommer) as service discovery.
Prommer listens to the Docker events stream and updates the target groups configuration of Prometheus.


## Voting App

For each vote,
the application will increment the counter of the Prometheus metric `votes_amount_total`.
The label `vote` is added and the value is set to the name of the vote.

**Metrics**

* `votes_amount_total{name=<name>}` - Counter that returns the total amount of votes

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

Pass in the `-vote` flag for which thing it should vote for (e.g. `-vote=dog`).

The `docker-compose.yml` file contains two different voting generator services:
`vote-cats` and `vote-dogs`.
If you wish to generate more votes,
you can scale them up with `docker-compose scale`:

```bash
$ docker-compose scale vote-dogs=3 vote-cats=2
```

## Alert Console

The alert console is an application that consumes the alerts sent by the Alert Manager.
It is configured as a webhook receiver in the Alert Manager.
When it receives an alert,
it logs the JSON body to the console.

You can view the logs of the alert console using `docker-compose logs`:

```bash
$ docker-compose logs --tail="all" -f alert-console
```
