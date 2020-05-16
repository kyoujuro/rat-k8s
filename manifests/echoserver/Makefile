all: push

# TAG 0.0 shouldn't clobber any release builds
TAG = 1.4
PREFIX = maho/echoserver

container:
	docker build --pull -t $(PREFIX):$(TAG) .

push: container
	docker push $(PREFIX):$(TAG)

