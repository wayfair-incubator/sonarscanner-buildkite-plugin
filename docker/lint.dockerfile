ARG GOLANG_VERSION=${GOLANG_VERSION:-1.13.4}
ARG DEBIAN_VERSION=${DEBIAN_VERSION:-10}
FROM golang:${GOLANG_VERSION} AS gobuilder

RUN cd $(mktemp -d); go mod init tmp; go get mvdan.cc/sh/cmd/shfmt
RUN go get -u github.com/shurcooL/markdownfmt

FROM debian:${DEBIAN_VERSION} AS debianbuilder

RUN apt-get update && \
    apt-get install -y \
    curl \
    xz-utils

ARG SCVERSION="stable"

RUN curl -o shellcheck.tar.xz \
    -L "https://storage.googleapis.com/shellcheck/shellcheck-${SCVERSION}.linux.x86_64.tar.xz" \
    && tar xf shellcheck.tar.xz \
    && mv "shellcheck-${SCVERSION}/shellcheck" /usr/bin/

FROM debian:${DEBIAN_VERSION}

COPY --from=debianbuilder /usr/bin/shellcheck /usr/bin/
COPY --from=gobuilder /go/bin/* /usr/bin/
COPY docker/run_formatters.sh /usr/bin/run_formatters

RUN useradd -m sonar
USER sonar

WORKDIR /app

ENTRYPOINT [ "run_formatters" ]
