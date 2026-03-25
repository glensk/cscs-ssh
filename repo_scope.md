# cscs-ssh

## Purpose
Tools for SSH access to CSCS login nodes (Ela, Daint, Eiger) using MFA-signed SSH keys, plus OpenStack CLI setup and node-hour usage reporting.

## Key Capabilities
- Fetch MFA-signed SSH key pair from CSCS SSH service (`cscs-keygen.py`, `cscs-keygen.sh`)
- Automated SSH login to Ela with 1Password credential retrieval and daily key rotation (`ssh_ela.sh`)
- Show per-project node-hour usage and storage quotas on Ela (`ela_show_HD_allocation_and_usage.sh`)
- OpenStack CLI environment setup with OTP authentication (`openstack_cli_otp.env`)

## Tech Stack
Python 3, Bash | Deps: requests, progress

## Key Scripts
| Script | Purpose |
|---|---|
| `cscs-keygen.py` | Fetch MFA-signed SSH keys from CSCS (Python version) |
| `cscs-keygen.sh` | Fetch MFA-signed SSH keys from CSCS (Bash version) |
| `ssh_ela.sh` | Full SSH workflow: key rotation, 1Password OTP, SCP keys to Ela, login |
| `ela_show_HD_allocation_and_usage.sh` | Show per-project node-hour usage and storage quotas (runs on Ela) |
| `openstack_cli_otp.env` | Source to set up OpenStack CLI with OTP-based Keycloak auth |

## Related Projects
- `cscs-excel` -- tracks CSCS resource allocation and budgets
