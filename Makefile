.PHONY: default setup dev dev-docker prometheus-docker binaries build-docker build-go clean clean-voting-app clean-voting-generator

MAIN=main

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

HOST_IP=$(ifconfig en0 | awk '/ *inet /{print $2}')

default: dev

dev: build-docker start

dev-docker:
	(cd ${VOTING_APP_SOURCE} && docker build -f Dockerfile.dev --tag=ordina-jworks/${VOTING_APP} .)
	(cd ${VOTING_GENERATOR_SOURCE} && docker build -f Dockerfile.dev --tag=ordina-jworks/${VOTING_GENERATOR} .)

setup:
	go get github.com/ant0ine/go-json-rest/rest
	go get github.com/prometheus/client_golang/prometheus
	go get github.com/prometheus/common/log
	go get github.com/tomverelst/prommer

binaries:
	docker build -t ordina-jworks/prometheus-demo-builder -f ./Dockerfile.build .
	docker run -t ordina-jworks/prometheus-demo-builder /bin/true
	mkdir -p ${VOTING_APP_BUILD}
	mkdir -p ${VOTING_GENERATOR_BUILD}
	docker cp `docker ps -q -n=1`:${BUILD_VOTING_APP_BINARY} ${VOTING_APP_BINARY}
	docker cp `docker ps -q -n=1`:${BUILD_VOTING_GENERATOR_BINARY} ${VOTING_GENERATOR_BINARY}
	chmod 755 ${VOTING_APP_BINARY}
	chmod 755 ${VOTING_GENERATOR_BINARY}

build-docker: binaries
	(cd voting-app && docker build -f Dockerfile.scratch --rm=true --tag=ordina-jworks/${VOTING_APP} .)
	(cd voting-generator && docker build -f Dockerfile.scratch --rm=true --tag=ordina-jworks/${VOTING_GENERATOR} .)
	(cd prometheus && docker build --rm=true --tag=ordina-jworks/prometheus-prommer .)

build-go:
	CGO_ENABLED=0 GOOS=linux go build -ldflags "-s" -a -installsuffix cgo -o ${BUILD_VOTING_APP_BINARY} ./go/src/github.com/ordina-jworks/prometheus-demo/voting-app/main.go
	CGO_ENABLED=0 GOOS=linux go build -ldflags "-s" -a -installsuffix cgo -o ${BUILD_VOTING_GENERATOR_BINARY} ./go/src/github.com/ordina-jworks/prometheus-demo/voting-generator/main.go

start:
	@docker-compose up -d

stop:
	@docker-compose down

clean: clean-voting-app clean-voting-generator

clean-voting-app:
	if [ -f ${VOTING_APP_TARGET} ]; then rm ${VOTING_APP_TARGET}; fi

clean-voting-generator:
	if [ -f ${VOTING_GENERATOR_TARGET} ]; then rm ${VOTING_GENERATOR_TARGET}; fi
