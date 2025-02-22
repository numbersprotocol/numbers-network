VERSION=0.0.2 # Populate latest here

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

echo "extracting downloaded subnet-cli"
tar xzvf ${DOWNLOAD_PATH} -C /tmp

/tmp/subnet-cli -h

# OR
# mv /tmp/subnet-cli /usr/bin/subnet-cli
# subnet-cli -h
