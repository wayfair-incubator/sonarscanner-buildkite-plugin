ARG GOLANG_VERSION=${GOLANG_VERSION:-1.13.4}
ARG CENTOS_VERSION=${CENTOS_VERSION:-8}
FROM golang:${GOLANG_VERSION} AS gobuilder

RUN cd $(mktemp -d); go mod init tmp; go get mvdan.cc/sh/cmd/shfmt
RUN go get -u github.com/shurcooL/markdownfmt

FROM centos:${CENTOS_VERSION} AS centosbuilder

RUN yum update -y && \
    yum install -y \
    curl \
    xz

ARG SCVERSION="stable"

RUN curl -o shellcheck.tar.xz \
    -L "https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-${SCVERSION}.linux.x86_64.tar.xz" \
    && tar xf shellcheck.tar.xz \
    && mv "shellcheck-${SCVERSION}/shellcheck" /usr/bin/

FROM centos:${CENTOS_VERSION}

COPY --from=centosbuilder /usr/bin/shellcheck /usr/bin/
COPY --from=gobuilder /go/bin/* /usr/bin/
COPY docker/run_formatters.sh /usr/bin/run_formatters

RUN useradd -m sonar
USER sonar

WORKDIR /app

ENTRYPOINT [ "run_formatters" ]
