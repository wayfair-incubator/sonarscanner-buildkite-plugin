FROM golang:1.20.1 AS gobuilder

RUN cd $(mktemp -d); go mod init tmp; go get mvdan.cc/sh/cmd/shfmt
RUN go get -u github.com/shurcooL/markdownfmt

FROM centos:8 AS centosbuilder

RUN yum update -y && \
    yum install -y \
    curl \
    xz

ARG SCVERSION="stable"

RUN curl -o shellcheck.tar.xz \
    -L "https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-${SCVERSION}.linux.x86_64.tar.xz" \
    && tar xf shellcheck.tar.xz \
    && mv "shellcheck-${SCVERSION}/shellcheck" /usr/bin/

FROM centos:8

COPY --from=centosbuilder /usr/bin/shellcheck /usr/bin/
COPY --from=gobuilder /go/bin/* /usr/bin/
COPY docker/entrypoints/run_formatters.sh /usr/bin/run_formatters

RUN useradd -m sonar
USER sonar

WORKDIR /app

ENTRYPOINT [ "run_formatters" ]
