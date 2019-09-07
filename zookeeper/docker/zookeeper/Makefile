VERSION=3.4.14
PROJECT=gary0416/k8szk

all: build

build:
	docker build --pull -t ${PROJECT}:${VERSION} .

push: build
	docker push ${PROJECT}:${VERSION}