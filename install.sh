#!/bin/bash

#set -ex

export IP=`ip addr show scope global | grep '^    inet ' | cut -c 10- | cut -d / -f 1`
export PORT=3000
export RUNNER_SECRET=`openssl rand -hex 20`

sudo userdel forgejo || true
sudo userdel git || true
sudo groupdel git || true
sudo rm -rf /etc/systemd/system/multi-user.target.wants/forgejo.service || true
sudo service forgejo stop || true

sudo rm -rf /usr/local/bin/forgejo
sudo rm -rf /usr/lib/forgejo
sudo rm -rf /var/lib/forgejo
sudo rm -rf /etc/forgejo
sudo rm -rf /etc/systemd/system/forgejo.service
#sudo rm -rf /tmp/forgejo*

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
#sudo apt update
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
if [ ! -e forgejo.xz ]; then
	wget -c -O forgejo.xz "https://codeberg.org/forgejo/forgejo/releases/download/${FORGEJO_VERSION}/forgejo-${FORGEJO_VERSION#v}-linux-${ARCH}.xz"
fi
unxz -f --keep forgejo.xz
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

# this can't be used for initial setup
#sudo wget -O /etc/forgejo/app.ini https://codeberg.org/forgejo/forgejo/raw/branch/forgejo/custom/conf/app.example.ini

# Generate secrets using Forgejo CLI
echo "5b. Generating security secrets..."
SECRET_KEY=$(/tmp/forgejo generate secret SECRET_KEY)
INTERNAL_TOKEN=$(/tmp/forgejo generate secret INTERNAL_TOKEN)
JWT_SECRET=$(/tmp/forgejo generate secret JWT_SECRET)

cat > /tmp/app.ini <<EOF
APP_NAME = Forgejo: Beyond coding. We Forge.
RUN_USER = git
WORK_PATH = /var/lib/forgejo

[server]
ROOT_URL = http://${IP}:${PORT}/
HTTP_PORT = ${PORT}

[database]
DB_TYPE = sqlite3

[security]
INSTALL_LOCK = true
SECRET_KEY = ${SECRET_KEY}
INTERNAL_TOKEN = ${INTERNAL_TOKEN}

[camo]

[oauth2]
ENABLED = true
JWT_SECRET = ${JWT_SECRET}

[log]
MODE = console
LEVEL = Info

[git]
[service]
EOF
sudo mv /tmp/app.ini /etc/forgejo/app.ini
#sudo chmod 0777 /etc/forgejo/
#sudo chmod 0777 /etc/forgejo/app.ini
sudo cat /etc/forgejo/app.ini

# Download and install systemd service
echo "6. Installing systemd service..."
sudo wget -O /etc/systemd/system/forgejo.service https://codeberg.org/forgejo/forgejo/raw/branch/forgejo/contrib/systemd/forgejo.service

# Enable and start Forgejo service
echo "7. Enabling and starting Forgejo service..."
sudo systemctl daemon-reload
sudo systemctl enable forgejo.service
sudo systemctl start forgejo.service

#export FORGEJO_WORK_DIR=/var/lib/forgejo

echo "proof user has access to app.ini"
sudo -u git wc -l /etc/forgejo/app.ini

echo "# migrating DB"
sudo -u git forgejo -w /var/lib/forgejo --config /etc/forgejo/app.ini migrate

echo "tring to register worker"
# This doesn't work
#sudo -u git forgejo -w /var/lib/forgejo --config /etc/forgejo/app.ini forgejo-cli actions register --name forgejo-runner --scope forgejo-org --secret $RUNNER_SECRET
# This works:
 sudo -u git forgejo -w /var/lib/forgejo --config /etc/forgejo/app.ini forgejo-cli actions register --name forgejo-runner                     --secret $RUNNER_SECRET --labels default

echo ""
echo "Forgejo Server Status:"
sudo systemctl status forgejo.service --no-pager

echo "make admin"
sudo -u git forgejo -w /var/lib/forgejo --config /etc/forgejo/app.ini admin user create --username forgejo-admin --admin --email admin@admin.com --password panacotaisthemessage --admin

echo "# Forgejo server should be running!"
echo "#"
echo "# We used IP: ${IP}"
echo "# We used PORT: ${PORT}"
echo "# RUNNER_SECRET: ${RUNNER_SECRET}"
echo "#"
echo "# Access at http://${IP}:${PORT}"
echo "#"
echo "# To install the worker, run:"
echo "./install-worker.sh ${IP} ${PORT} ${RUNNER_SECRET}"
