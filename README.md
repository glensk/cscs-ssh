# cscs-ssh

Daily SSH login automation for CSCS HPC login nodes (Ela, Daint, Eiger).

## What this is

`ssh_ela.sh` orchestrates the daily flow: keep a persistent local ed25519
keypair, refresh the short-lived (24 h) certificate via the new
[`cscs-key`](https://github.com/eth-cscs/cscs-key) CLI, push it to ela so
chained jumps to daint / eiger work, and open an interactive SSH session.

## Migration to `cscs-key` (May 2026)

The legacy `sshservice.cscs.ch` API is decommissioned starting **2026-05-04**.
The old `cscs-keygen.py` / `cscs-keygen.sh` scripts and the
`username + password + OTP` POST flow no longer work and have been removed
from this repo. The new flow uses OIDC SSO via the `cscs-key` CLI; the OIDC
token caches for ~24 h, so subsequent runs are silent.

Web alternative: <https://user-account.cscs.ch> ("Sign Your SSH Key").

## One-time setup

1. **Install `cscs-key`** (macOS arm64 example — pick the right asset for your
   platform from <https://github.com/eth-cscs/cscs-key/releases>):

   ```bash
   cd /tmp
   curl -L -O https://github.com/eth-cscs/cscs-key/releases/download/v1.1.0/cscs-key-v1.1.0-aarch64-apple-darwin.tar.gz
   tar -xzf cscs-key-v1.1.0-aarch64-apple-darwin.tar.gz
   mv cscs-key ~/.local/bin/
   chmod +x ~/.local/bin/cscs-key
   cscs-key --version
   ```

2. **First run** (`ssh_ela.sh` generates the keypair if missing and opens a
   browser for CSCS OIDC SSO; the resulting token caches for ~24 h):

   ```bash
   bash ssh_ela.sh
   ```

## Usage

```bash
# Daily login (uses $my_cscs_username default 'aglensk' for $USER in {glensk,albert})
bash ssh_ela.sh

# Different CSCS account
bash ssh_ela.sh <cscs_username>

# Just refresh the cert (without going through the orchestrator)
cscs-key sign -f ~/.ssh/cscs_daily_key/cscs-key

# List signed keys / revoke
cscs-key list
cscs-key revoke <serial>
```

## Files

- `ssh_ela.sh` — daily login orchestrator
- `ela_show_HD_allocation_and_usage.sh` — Slurm node-hour reporting (run on ela)
- `openstack_cli_otp.env` — independent OpenStack/Keycloak token bootstrap (sourced)

## Key paths

- `~/.ssh/cscs_daily_key/cscs-key`         — persistent ed25519 private key
- `~/.ssh/cscs_daily_key/cscs-key.pub`     — its public key
- `~/.ssh/cscs_daily_key/cscs-key-cert.pub` — short-lived (24 h) cert from CSCS
- `~/.ssh/ControlPath_files/<user>@ela.cscs.ch:22` — OpenSSH ControlMaster socket
