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

BUILD_VOTING_APP_BINARY=/build/${VOTING_APP}/${MAIN}
BUILD_VOTING_GENERATOR_BINARY=/build/${VOTING_GENERATOR}/${MAIN}

BUILD_IMAGE=${REPOSITORY}/prometheus-demo-builder
VOTING_APP_IMAGE=${REPOSITORY}/${VOTING_APP}
VOTING_GENERATOR_IMAGE=${REPOSITORY}/${VOTING_GENERATOR}
PROMETHEUS_IMAGE=${REPOSITORY}/prometheus-prommer

HOST_IP=$(ifconfig en0 | awk '/ *inet /{print $2}')

.PHONY: default
default: build

.PHONY: build
build: build-docker start

.PHONY: setup
setup:
	go get github.com/ant0ine/go-json-rest/rest
	go get github.com/prometheus/client_golang/prometheus
	go get github.com/prometheus/common/log
	go get github.com/tomverelst/prommer

.PHONY: binaries
binaries:
	docker build -t ${BUILD_IMAGE} -f ./Dockerfile.build .
	docker run --rm -t ${BUILD_IMAGE} /bin/true
	mkdir -p ${VOTING_APP_BUILD}
	mkdir -p ${VOTING_GENERATOR_BUILD}
	docker cp `docker ps -q -n=1`:${BUILD_VOTING_APP_BINARY} ${VOTING_APP_BINARY}
	docker cp `docker ps -q -n=1`:${BUILD_VOTING_GENERATOR_BINARY} ${VOTING_GENERATOR_BINARY}
	chmod 755 ${VOTING_APP_BINARY}
	chmod 755 ${VOTING_GENERATOR_BINARY}

.PHONY: build-docker
build-docker: binaries
	(cd voting-app && docker build -f Dockerfile.scratch --rm=true --tag=${VOTING_APP_IMAGE} .)
	(cd voting-generator && docker build -f Dockerfile.scratch --rm=true --tag=${VOTING_GENERATOR_IMAGE} .)
	(cd prometheus && docker build --rm=true --tag=${PROMETHEUS_IMAGE} .)

.PHONY: build-go
build-go:
	CGO_ENABLED=0 GOOS=linux go build -ldflags "-s" -a -installsuffix cgo -o ${BUILD_VOTING_APP_BINARY} ./go/src/github.com/ordina-jworks/prometheus-demo/voting-app/main.go
	CGO_ENABLED=0 GOOS=linux go build -ldflags "-s" -a -installsuffix cgo -o ${BUILD_VOTING_GENERATOR_BINARY} ./go/src/github.com/ordina-jworks/prometheus-demo/voting-generator/main.go

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

.PHONY: clean-docker
clean-docker:
	@echo "Cleaning Docker images"
	@if docker history -q ${BUILD_IMAGE} >/dev/null 2>&1; then docker rmi -f ${BUILD_IMAGE} >/dev/null; fi;
	@if docker history -q ${VOTING_APP_IMAGE} >/dev/null 2>&1; then docker rmi -f ${VOTING_APP_IMAGE} >/dev/null; fi;
	@if docker history -q ${VOTING_GENERATOR_IMAGE} >/dev/null 2>&1; then docker rmi -f ${VOTING_GENERATOR_IMAGE} >/dev/null; fi;
	@if docker history -q ${PROMETHEUS_IMAGE} >/dev/null 2>&1; then docker rmi -f ${PROMETHEUS_IMAGE} >/dev/null; fi;
