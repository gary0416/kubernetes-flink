VERSION=2.0
PROJECT=gary0416/zkui

all: build

build:
	docker build -t ${PROJECT}:${VERSION} .

push: build
	docker push ${PROJECT}:${VERSION}