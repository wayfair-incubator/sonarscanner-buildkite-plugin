FROM mcr.microsoft.com/dotnet/core/sdk:3.1.412 AS core22
FROM mcr.microsoft.com/dotnet/core/sdk:3.1.412

ARG VERSION=${PLUGIN_VERSION}
ARG DESCRIPTION="Run sonar-scanner in a .NET Docker container"
ARG VCS_URL="https://github.com/wayfair-incubator/sonarscanner-buildkite-plugin"

USER root

RUN apt-get update && \
    apt-get install -y \
    default-jdk \
    && rm -rf /var/lib/apt/lists/*

COPY --from=core22 /usr/share/dotnet /usr/share/dotnet
COPY docker/SonarQube.Analysis.xml /root/.dotnet/tools/SonarQube.Analysis.xml
COPY docker/entrypoints/dotnet-entrypoint.sh /usr/bin/scanner

RUN useradd -m sonar

WORKDIR /workdir
RUN chown -R sonar:sonar /workdir

USER sonar

RUN dotnet tool install --global dotnet-sonarscanner


ENV PATH="${PATH}:/home/sonar/.dotnet/tools"
ENV JAVA_HOME="/etc/alternatives/jre/"

ENTRYPOINT [ "scanner" ]

ARG BUILD_DATE
LABEL \
    com.wayfair.name="sonarscannerbuildkite/sonarscanner-dotnet" \
    com.wayfair.build-date=${BUILD_DATE} \
    com.wayfair.description=${DESCRIPTION} \
    com.wayfair.vsc_url=${VCS_URL} \
    com.wayfair.maintainer="James Curtin <jacurtin@wayfair.com>" \
    com.wayfair.vendor="Wayfair LLC." \
    com.wayfair.version=${VERSION}
