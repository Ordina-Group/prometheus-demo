MAIN=main
REPOSITORY=ordina-jworks

VOTING_APP=voting-app
VOTING_APP_SOURCE=$(PWD)/${VOTING_APP}
VOTING_APP_BUILD=$(PWD)/${VOTING_APP}/build
VOTING_APP_BINARY=${VOTING_APP_BUILD}/${MAIN}

VOTING_GENERATOR=voting-generator
VOTING_GENERATOR_SOURCE=$(PWD)/${VOTING_GENERATOR}
VOTING_GENERATOR_BUILD=$(PWD)/${VOTING_GENERATOR}/build
VOTING_GENERATOR_BINARY=${VOTING_GENERATOR_BUILD}/${MAIN}

ALERT_CONSOLE=alert-console
ALERT_CONSOLE_SOURCE=$(PWD)/${ALERT_CONSOLE}
ALERT_CONSOLE_BUILD=$(PWD)/${ALERT_CONSOLE}/build
ALERT_CONSOLE_BINARY=${ALERT_CONSOLE_BUILD}/${MAIN}

BUILD_VOTING_APP_BINARY=/build/${VOTING_APP}/${MAIN}
BUILD_VOTING_GENERATOR_BINARY=/build/${VOTING_GENERATOR}/${MAIN}
BUILD_ALERT_CONSOLE_BINARY=/build/${ALERT_CONSOLE}/${MAIN}

BUILD_IMAGE=${REPOSITORY}/prometheus-demo-builder
VOTING_APP_IMAGE=${REPOSITORY}/${VOTING_APP}
VOTING_GENERATOR_IMAGE=${REPOSITORY}/${VOTING_GENERATOR}
ALERT_CONSOLE_IMAGE=${REPOSITORY}/${ALERT_CONSOLE}
PROMETHEUS_IMAGE=${REPOSITORY}/prometheus-prommer

HOST_IP=$(ifconfig en0 | awk '/ *inet /{print $2}')

.PHONY: default
default: build

.PHONY: build
build: build-docker start

.PHONY: setup
setup:
	go get -v -u github.com/ant0ine/go-json-rest/rest
	go get -v -u github.com/prometheus/client_golang/prometheus

.PHONY: binaries
binaries:
	docker build -t ${BUILD_IMAGE} -f ./Dockerfile.build .
	docker run -t ${BUILD_IMAGE} /bin/true
	mkdir -p ${VOTING_APP_BUILD}
	mkdir -p ${VOTING_GENERATOR_BUILD}
	mkdir -p ${ALERT_CONSOLE_BUILD}
	docker cp `docker ps -q -n=1`:${BUILD_VOTING_APP_BINARY} ${VOTING_APP_BINARY}
	docker cp `docker ps -q -n=1`:${BUILD_VOTING_GENERATOR_BINARY} ${VOTING_GENERATOR_BINARY}
	docker cp `docker ps -q -n=1`:${BUILD_ALERT_CONSOLE_BINARY} ${ALERT_CONSOLE_BINARY}
	chmod 755 ${VOTING_APP_BINARY}
	chmod 755 ${VOTING_GENERATOR_BINARY}
	chmod 755 ${ALERT_CONSOLE_BINARY}

.PHONY: build-docker
build-docker: binaries
	(cd voting-app && docker build -f Dockerfile.scratch --rm=true --tag=${VOTING_APP_IMAGE} .)
	(cd voting-generator && docker build -f Dockerfile.scratch --rm=true --tag=${VOTING_GENERATOR_IMAGE} .)
	(cd alert-console && docker build -f Dockerfile.scratch --rm=true --tag=${ALERT_CONSOLE_IMAGE} .)
	(cd prometheus && docker build --rm=true --tag=${PROMETHEUS_IMAGE} .)

.PHONY: build-go
build-go:
	CGO_ENABLED=0 GOOS=linux go build -ldflags "-s" -a -installsuffix cgo -o ${BUILD_VOTING_APP_BINARY} ./go/src/github.com/ordina-jworks/prometheus-demo/voting-app/main.go
	CGO_ENABLED=0 GOOS=linux go build -ldflags "-s" -a -installsuffix cgo -o ${BUILD_VOTING_GENERATOR_BINARY} ./go/src/github.com/ordina-jworks/prometheus-demo/voting-generator/main.go
	CGO_ENABLED=0 GOOS=linux go build -ldflags "-s" -a -installsuffix cgo -o ${BUILD_ALERT_CONSOLE_BINARY} ./go/src/github.com/ordina-jworks/prometheus-demo/alert-console/main.go

.PHONY: start
start:
	@docker-compose up -d

.PHONY: stop
stop:
	@echo "Stopping..."
	@docker-compose down 2> /dev/null

.PHONY: clean
clean: stop clean-binaries clean-docker

.PHONY: clean-binaries
clean-binaries:
	@echo "Cleaning binaries"
	@if [ -f ${VOTING_APP_BINARY} ]; then rm ${VOTING_APP_BINARY}; fi
	@if [ -f ${VOTING_GENERATOR_BINARY} ]; then rm ${VOTING_GENERATOR_BINARY}; fi
	@if [ -f ${ALERT_CONSOLE_BINARY} ]; then rm ${ALERT_CONSOLE_BINARY}; fi

.PHONY: clean-docker
clean-docker:
	@echo "Cleaning Docker images"
	@if docker history -q ${BUILD_IMAGE} >/dev/null 2>&1; then docker rmi -f ${BUILD_IMAGE} >/dev/null; fi;
	@if docker history -q ${VOTING_APP_IMAGE} >/dev/null 2>&1; then docker rmi -f ${VOTING_APP_IMAGE} >/dev/null; fi;
	@if docker history -q ${VOTING_GENERATOR_IMAGE} >/dev/null 2>&1; then docker rmi -f ${VOTING_GENERATOR_IMAGE} >/dev/null; fi;
	@if docker history -q ${ALERT_CONSOLE_IMAGE} >/dev/null 2>&1; then docker rmi -f ${ALERT_CONSOLE_IMAGE} >/dev/null; fi;
	@if docker history -q ${PROMETHEUS_IMAGE} >/dev/null 2>&1; then docker rmi -f ${PROMETHEUS_IMAGE} >/dev/null; fi;

test-config:
	docker run -v $(PWD)/prometheus/prometheus.yml:/etc/prometheus/config.yml \
	--entrypoint /bin/promtool \
	prom/prometheus \
	check-config /etc/prometheus/config.yml

test-rules:
	docker run -v $(PWD)/prometheus/voting.rules:/etc/prometheus/voting.rules \
	--entrypoint /bin/promtool \
	prom/prometheus \
	check-rules /etc/prometheus/voting.rules
