# vi: ft=dockerfile
FROM voidlinux/voidlinux:latest
RUN ["xbps-install", "-Sy", "bash", "tectonic", "biber", "curl", "jq"]
COPY ["tectonic-release.bash", "/bin/tectonic-release"]
RUN ["chmod", "+x", "/bin/tectonic-release"]
ENTRYPOINT ["/bin/tectonic-release"]
