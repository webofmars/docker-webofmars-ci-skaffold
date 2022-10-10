ARG platform="linux/amd64"
FROM --platform=${platform} webofmars/asdf:v0.8.1

# install as root
USER 0

# install docker
RUN apk add --no-cache docker && \
    addgroup asdf docker

# add make for supporting makefile usage in skaffold CI jobs
RUN apk add --no-cache make

# should run asdf as the dedicated user
USER 1000

RUN asdf plugin update --all
ARG SKAFFOLD_VERSION=1.9.1
RUN asdf install skaffold ${SKAFFOLD_VERSION} && \
    asdf global skaffold ${SKAFFOLD_VERSION}
