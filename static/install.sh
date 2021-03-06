#! /bin/sh

set -eu


get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"v([^"]+)".*/\1/'                                   # Pluck JSON value, removing 'v' from version number
}

# Usage
# $ get_latest_release "creationix/nvm"
# v0.31.4

# echo $(get_latest_release "mailchain/mailchain")

MAILCHAIN_VERSION=${MAILCHAIN_VERSION:-$(get_latest_release "mailchain/mailchain")}

if [ "$(uname -s)" = "Darwin" ]; then
  OS=macOS
else
  OS=Linux
fi

tmp=$(mktemp -d /tmp/mailchain.XXXXXX)
filename="mailchain-${MAILCHAIN_VERSION}-${OS}-64bit.tar.gz"
url="https://github.com/mailchain/mailchain/releases/download/${MAILCHAIN_VERSION}"
(
  cd "$tmp"

  echo "Downloading ${url}/${filename}..."

  curl -LO "${url}/${filename}"
  echo ""
  echo "Download complete!"

  echo "Extracting ${filename}..."
  tar -xzvf ${filename}
  echo "Extracted complete!"


  echo "Downloading checksum..."
  checksum=$(openssl dgst -sha256 ${filename} | awk '{ print $2 }')
  SHA=$(curl -LO "${url}/checksums.txt" ${url}/checksums.txt | grep "${filename}" | awk '{ print $1 }') 
  
  echo "validating checksum..."
  echo $(curl -LO "${url}/checksums.txt" ${url}/checksums.txt | grep "${filename}") 
  
  if [ "$checksum" != "$SHA" ]; then
    echo "Checksum validation failed." >&2
    exit 1
  fi
  echo "Checksum valid."
  echo ""
)

(
  cd "$HOME"
  mkdir -p ".mailchain/bin"
  mv "${tmp}/mailchain" ".mailchain/bin/mailchain"
  chmod +x ".mailchain/bin/mailchain"
)

rm -r "$tmp"

echo "Mailchain was successfully installed 🎉"
echo ""
echo "Add the mailchain application to your path with:"
echo ""
echo "  export PATH=\$PATH:\$HOME/.mailchain/bin"
echo ""
echo "Now run:"
echo ""
echo "  mailchain help                          # to display available commands"
echo ""
echo "Looking for more? Visit https://docs.mailchain.xyz"
echo ""
