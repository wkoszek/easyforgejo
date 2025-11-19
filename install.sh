#!/bin/bash
set -ex

userdel forgejo && exit 0
userdel git && exit 0
sudo rm -rf /usr/local/bin/forgejo /usr/lib/forgejo /etc/forgejo /etc/systemd/system/forgejo.service /tmp/forgejo*

echo "========================================="
echo "Forgejo Server & Runner Installation"
echo "========================================="

# =========================================
# FORGEJO SERVER INSTALLATION
# =========================================

echo ""
echo "Installing Forgejo Server..."
echo "-------------------------------------------"

# Update package list and install prerequisites
echo "1. Installing prerequisites..."
sudo apt update
sudo apt install -y git git-lfs

# Create system user for Forgejo
echo "2. Creating git system user..."
sudo adduser --system --shell /bin/bash --gecos 'Git Version Control' --group --disabled-password --home /home/git git

# Detect architecture and download Forgejo binary
echo "3. Downloading Forgejo binary..."
ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
FORGEJO_VERSION=$(curl -s https://codeberg.org/api/v1/repos/forgejo/forgejo/releases/latest | grep -o '"tag_name":"[^"]*"' | cut -d\" -f4)
echo "   - Architecture: $ARCH"
echo "   - Version: $FORGEJO_VERSION"
cd /tmp
wget -O forgejo.xz "https://codeberg.org/forgejo/forgejo/releases/download/${FORGEJO_VERSION}/forgejo-${FORGEJO_VERSION#v}-linux-${ARCH}.xz"
unxz forgejo.xz
chmod +x forgejo


# Install Forgejo binary
echo "4. Installing Forgejo binary..."
sudo cp forgejo /usr/local/bin/forgejo
sudo chmod 755 /usr/local/bin/forgejo
forgejo --version

# Create required directories
echo "5. Creating directories..."
sudo mkdir -p /var/lib/forgejo
sudo chown git:git /var/lib/forgejo
sudo chmod 750 /var/lib/forgejo

sudo mkdir -p /etc/forgejo
sudo chown root:git /etc/forgejo
sudo chmod 770 /etc/forgejo

sudo wget -O /etc/forgejo/app.ini https://codeberg.org/forgejo/forgejo/raw/branch/forgejo/custom/conf/app.example.ini

# Download and install systemd service
echo "6. Installing systemd service..."
sudo wget -O /etc/systemd/system/forgejo.service https://codeberg.org/forgejo/forgejo/raw/branch/forgejo/contrib/systemd/forgejo.service

# Enable and start Forgejo service
echo "7. Enabling and starting Forgejo service..."
sudo systemctl daemon-reload
sudo systemctl enable forgejo.service
sudo systemctl start forgejo.service

# XXX ^ this all works
# XXX Below is what I'm debugging.


export FORGEJO_WORK_DIR=/var/lib/forgejo
export RUNNER_SECRET=7c31591e8b67225a116d4a4519ea8e507e08f71f
echo "Secret: $RUNNER_SECRET"

sudo -u git forgejo -w /var/lib/forgejo -c /etc/forgejo/app.ini \
		forgejo-cli actions register --name forgejo-runner --scope forgejo-org \
		--secret $RUNNER_SECRET

echo ""
echo "Forgejo Server Status:"
sudo systemctl status forgejo.service --no-pager

echo ""
echo "========================================="
echo "Forgejo server is now running!"
echo "Access it at: http://localhost:3000"
echo "========================================="
