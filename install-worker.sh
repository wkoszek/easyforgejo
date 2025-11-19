#!/bin/bash
set -ex

export RUNNER_SECRET=7c31591e8b67225a116d4a4519ea8e507e08f71f

sudo userdel runner || true
sudo groupdel docker || true

sudo useradd --create-home runner
sudo groupadd docker || true
sudo usermod -aG docker runner

ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')

sudo apt install docker.io

echo "4. Downloading Forgejo Runner binary..."
RUNNER_VERSION=$(curl -s https://data.forgejo.org/api/v1/repos/forgejo/runner/releases/latest | grep -o '"tag_name":"[^"]*"' | cut -d\" -f4)
echo "   - Runner Version: $RUNNER_VERSION"
cd /tmp
wget -O forgejo-runner.xz "https://code.forgejo.org/forgejo/runner/releases/download/${RUNNER_VERSION}/forgejo-runner-${RUNNER_VERSION#v}-linux-${ARCH}.xz"
unxz -f --keep forgejo-runner.xz
chmod +x forgejo-runner

# Install Runner binary
echo "5. Installing Forgejo Runner binary..."
sudo cp forgejo-runner /usr/local/bin/forgejo-runner
forgejo-runner --version

# Generate runner configuration
echo "6. Generating runner configuration..."
forgejo-runner generate-config | sudo tee /home/runner/config.yml > /dev/null
sudo chown runner:runner /home/runner/config.yml

# XXX This doesn't have a way to set the label of the worker which appears (from warning in UI)
# to render this runner as useless (can't pickup jobs)
sudo -u runner forgejo-runner create-runner-file \
    --instance http://localhost:3000 \
    --secret "$RUNNER_SECRET" \
    --connect

ls -la

# XXX fixing
sudo -u runner jq '. + { "labels":["default"]}' .runner > .runner.fixed
sudo mv .runner.fixed /home/runner/.runner
sudo chown -Rf runner:runner /home/runner/.runner

sudo tee /etc/systemd/system/forgejo-runner.service > /dev/null <<EOF
[Unit]
Description=Forgejo Runner
After=network.target forgejo.service

[Service]
Type=simple
User=runner
Group=runner
WorkingDirectory=/home/runner
ExecStart=/usr/local/bin/forgejo-runner daemon --config /home/runner/config.yml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable forgejo-runner.service
sudo systemctl start forgejo-runner.service

echo ""
echo "========================================="
echo "Installation Complete!"
echo "========================================="
echo ""
echo "Forgejo Server Status:"
sudo systemctl status forgejo.service --no-pager | head -10

echo ""
echo "Forgejo Runner Status:"
sudo systemctl status forgejo-runner.service --no-pager | head -10

echo ""
echo "========================================="
echo "Access Forgejo at: http://localhost:3000"
echo "Check runners at: http://localhost:3000/admin/actions/runners"
echo ""
echo "Useful commands:"
echo "  - View runner logs: sudo journalctl -u forgejo-runner.service -f"
echo "  - View server logs: sudo journalctl -u forgejo.service -f"
echo "  - Restart runner: sudo systemctl restart forgejo-runner.service"
echo "========================================="
