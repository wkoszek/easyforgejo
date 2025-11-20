# EasyForgejo

**BETA** - Self-hosted Git server with CI/CD in one command

A simple, automated installation script for [Forgejo](https://forgejo.org/) (community-driven fork of Gitea) with built-in CI/CD runner support.

## Features

- 🚀 **One-command installation** - Get Forgejo running in minutes
- 🔐 **Secure by default** - Auto-generated secrets and credentials using Forgejo CLI
- 💾 **SQLite-based** - No external database required
- 🔧 **CI/CD ready** - GitHub Actions-compatible runner setup
- 📦 **Minimal dependencies** - Works on any Linux system with systemd

## Quick Start

Visit [https://wkoszek.github.io/easyforgejo/](https://wkoszek.github.io/easyforgejo/) for installation commands.

### Step 1: Install Forgejo Server

```bash
curl -sSL https://wkoszek.github.io/easyforgejo/install.sh | bash
```

This will:
- Download and install the latest Forgejo version
- Generate secure credentials (SECRET_KEY, INTERNAL_TOKEN, JWT_SECRET)
- Create an admin account with random password
- Configure systemd service
- Register a runner token for CI/CD

### Step 2: Install CI Runner (Optional, for full CI setup)

First, download the worker script:
```bash
curl -sSL -O https://wkoszek.github.io/easyforgejo/install-worker.sh
```

Then run the command output from Step 1:
```bash
sh ./install-worker.sh [IP] [PORT] [SECRET]
```

**Note:** The CI runner requires Docker to be installed.

## Testing with Multipass

You can easily test EasyForgejo in an isolated VM using [Multipass](https://multipass.run/):

```bash
# Clone the repository
git clone https://github.com/wkoszek/easyforgejo.git
cd easyforgejo

# Create a VM with 50GB disk
multipass launch --name vm1 --disk 50G

# Mount the project directory
multipass mount . vm1:/easyforgejo

# Enter the VM
multipass shell vm1

# Navigate to the project
cd /easyforgejo

# Run the installation
sudo bash install.sh
```

Clean up when done:
```bash
exit  # Exit the VM
multipass delete vm1
multipass purge
```

## Requirements

### Forgejo Server
- Linux with systemd - tested on Ubuntu 24.04
- curl, wget, git
- sudo access

### CI Runner
- All server requirements
- Docker
- jq

## Configuration

The installation script uses these default settings:
- **Port:** 3000 (configurable via `PORT` variable)
- **Database:** SQLite
- **Admin user:** forgejo-admin
- **Admin email:** admin@admin.com

All secrets and the admin password are randomly generated and displayed at the end of installation.

## Post-Installation

After installation:

1. **Login** with the admin credentials shown
2. **Create your own account** for daily use
3. **Change the admin password** in settings
4. **Install the CI runner** for GitHub Actions-compatible workflows

Access your instance at: `http://[YOUR-IP]:3000`

Check runners at: `http://[YOUR-IP]:3000/admin/actions/runners`

## Project Structure

```
.
├── install.sh         # Main Forgejo server installation
├── install-worker.sh  # CI runner installation
└── index.html        # GitHub Pages landing page
```

## Security Notes

- Admin credentials are auto-generated
- All secrets use Forgejo's built-in generators or `openssl rand`
- Runner secrets are created per-installation
- Change default admin password after first login

TODO: it's all shown at STDOUT during install

## Uninstalling

TODO

## Reinstalling 

Purge mode will allow you to reinstall the server (useful for testing script modifications):

```bash
sudo bash install.sh purge
```

TODO: need to support this for worker too

## Contributing

Contributions welcome! This is a beta project under active development.

## License

MIT License - See LICENSE file for details

## Links

- [Landing Page](https://wkoszek.github.io/easyforgejo/)
- [Forgejo Project](https://forgejo.org/)
- [Forgejo Documentation](https://forgejo.org/docs/)
- [GitHub Repository](https://github.com/wkoszek/easyforgejo)

## Author

Created by [Adam Koszek](https://x.com/wkoszek) for the Forgejo self-hosting community.
