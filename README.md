# docker-nexus

A container image for Sonatype Nexus Repository Manager OSS, based on Alpine Linux.

[![Docker Repository on Quay](https://quay.io/repository/elm-company/sonatype-nexus/status "Docker Repository on Quay")](https://quay.io/repository/elm-company/sonatype-nexus)

## Current software

* Alpine Linux 3.14
* OpenJDK JRE 8u212
* Nexus Repository Manager OSS 3.54.1 ([release notes](https://help.sonatype.com/repomanager3/product-information/release-notes/2023-release-notes/sonatype-nexus-repository-3.54.0---3.54.1-release-notes))

## Running

Running it locally (for the latest tag, check [quay.io/repository/elm-company/sonatype-nexus](https://quay.io/repository/elm-company/sonatype-nexus?tab=tags):

```shell
docker run -p 8081:8081 --name nexus quay.io/elm-company/sonatype-nexus:3.54.1-01
```

# Releases
- 3.54.1-01
- 3.42.0-01

## Reasoning

The Official Sonatype Nexus Docker image: https://hub.docker.com/r/sonatype/nexus3/ is suitable for most use cases. But as discussed in this blog post:
https://www.sonatype.com/travel-audience-devops-pipeline-solution
being able to `restore` from a backup requires stopping the nexus service. And this is not possible with the official image, as described in this bug report: https://issues.sonatype.org/browse/NEXUS-23442

So while `travel audience` would prefer to support the official image, this is not possible at this time, and we hope that this lightweight image provides a suitable alternative to the community in the meantime.

The travel audience Nexus Docker image provides the following features that are not present in the official image:

* uses `runit` to run nexus under a secondary process
* uses an Alpine base image, instead of RedHat's UBI8
* provides an optional flag to make sure all mounted data is owned by the `nexus` user _(nexus will have issues if that's not the case)_
