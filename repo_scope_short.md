# cscs-ssh
SSH key management and login automation for CSCS HPC systems (Ela, Daint, Eiger) using MFA-signed certificates, plus node-hour usage reporting.
Key tools: `ssh_ela.sh` (automated SSH login with 1Password OTP), `cscs-keygen.py` (fetch MFA keys), `ela_show_HD_allocation_and_usage.sh` (usage reporting)
Stack: Python, Bash | Deps: requests, progress
