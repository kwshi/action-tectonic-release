# vi: ft=dockerfile
FROM alpine:latest
RUN ["apk", "add", "bash", "tectonic", "findutils"]
COPY ["tectonic-release.bash", "/bin/tectonic-release"]
RUN ["chmod", "+x", "/bin/tectonic-release"]
ENTRYPOINT "/bin/tectonic-release"
CMD [""]
