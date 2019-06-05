all: run

# This makefile contains some convenience commands for deploying and publishing.

# For example, to build and run the docker container locally, just run:
# $ make

# or to publish the :latest version to the specified registry as :1.0.0, run:
# $ make publish version=1.0.0

name = jenkins-master
image_name = jenkinsci/blueocean
registry = 874727002155.dkr.ecr.us-east-1.amazonaws.com/rt-jenkins/master
version ?= latest

ecr_login:
	$(call blue, "Login to AWS ECR...")
	eval $(aws --profile rtdevelopment ecr get-login --no-include-email)

binary:
	$(call blue, "Building binary ready for containerisation...")
	docker run --rm -it -v "${GOPATH}":/gopath -v "$(CURDIR)":/app -e "GOPATH=/gopath" -w /app golang:1.7 sh -c 'CGO_ENABLED=0 go build -a --installsuffix cgo --ldflags="-s" -o app'

image: binary
	$(call blue, "Building docker image from container...")
	docker build -t ${name}:${version} .
	$(MAKE) clean

image_build:
	$(call blue, "Building docker image from Dockerfile...")
	docker build -t ${name}:${version} .
	$(MAKE) clean

myrun:
	$(call blue, "Running Docker image locally...")
	docker run -i -t --rm -p 8080:8080 ${name}:${version} 

run: image
	$(call blue, "Running Docker image locally...")
	docker run -i -t --rm -p 8080:8080 ${name}:${version} 

publish:  
	$(call blue, "Publishing Docker image to registry...")
	docker tag ${name}:latest ${registry}/${name}:${version}
	docker push ${registry}/${name}:${version} 

image_update:  
	$(call blue, "Updating Docker image to latest...")
	docker pull ${image_name}:latest

clean: 
	@rm -f app 

define blue
	@tput setaf 6
	@echo $1
	@tput sgr0
endef
