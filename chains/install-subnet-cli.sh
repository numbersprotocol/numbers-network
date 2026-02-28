VERSION=0.0.2 # Populate latest here
# Update EXPECTED_SHA256 to match the SHA256 checksum for the downloaded version.
# Obtain the checksum from the official release page or the checksums file published with the release.
EXPECTED_SHA256="" # Populate expected SHA256 checksum here

GOARCH=$(go env GOARCH)
GOOS=$(go env GOOS)
DOWNLOAD_PATH=/tmp/subnet-cli.tar.gz
DOWNLOAD_URL=https://github.com/ava-labs/subnet-cli/releases/download/v${VERSION}/subnet-cli_${VERSION}_linux_${GOARCH}.tar.gz
if [[ ${GOOS} == "darwin" ]]; then
  DOWNLOAD_URL=https://github.com/ava-labs/subnet-cli/releases/download/v${VERSION}/subnet-cli_${VERSION}_darwin_${GOARCH}.tar.gz
fi

rm -f ${DOWNLOAD_PATH}
rm -f /tmp/subnet-cli

echo "downloading subnet-cli ${VERSION} at ${DOWNLOAD_URL}"
curl -L ${DOWNLOAD_URL} -o ${DOWNLOAD_PATH}

if [[ -n "${EXPECTED_SHA256}" ]]; then
    echo "verifying checksum"
    if ! echo "${EXPECTED_SHA256}  ${DOWNLOAD_PATH}" | sha256sum -c -; then
        echo "Error: checksum verification failed. Aborting." >&2
        rm -f ${DOWNLOAD_PATH}
        exit 1
    fi
else
    echo "Warning: EXPECTED_SHA256 is not set. Skipping checksum verification." >&2
fi

echo "extracting downloaded subnet-cli"
tar xzvf ${DOWNLOAD_PATH} -C /tmp

/tmp/subnet-cli -h

# OR
# mv /tmp/subnet-cli /usr/bin/subnet-cli
# subnet-cli -h
