# vi: ft=dockerfile
FROM alpine:latest
RUN ["apk", "add", "tectonic", "findutils"]
COPY ["tectonic-release.bash", "/bin/tectonic-release"]
RUN ["chmod", "+x", "/bin/tectonic-release"]
ENTRYPOINT "/bin/tectonic-release"
