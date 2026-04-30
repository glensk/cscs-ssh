# cscs-ssh

SSH key management and login automation for CSCS HPC systems (Ela, Daint, Eiger) using the new `cscs-key` CLI (OIDC SSO, locally-generated ed25519 keypair, daily-signed cert), plus node-hour usage reporting.
Key tools: `ssh_ela.sh` (automated SSH login orchestrator), `ela_show_HD_allocation_and_usage.sh` (usage reporting)
Stack: Bash | Deps: `cscs-key` (https://github.com/eth-cscs/cscs-key), OpenSSH
