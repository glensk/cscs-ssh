# cscs-ssh

SSH-key + login automation for CSCS HPC login nodes (Ela, Daint, Eiger) using the
`cscs-key` CLI (OIDC SSO, locally-generated ed25519 keypair, daily-signed 24h
cert), plus a Slurm node-hour usage report. Use when a ticket is about signing or
refreshing a CSCS SSH key, logging in to ela/daint/eiger, the `cscs-key` CLI, or
the retired `sshservice.cscs.ch` username+password+OTP flow (decommissioned
2026-05-04, removed from this repo). Mostly Albert's own daily-login automation,
not a shared team service. Search terms: CSCS SSH, ela.cscs.ch, cscs-key, sign
SSH key, HPC login, user-account.cscs.ch.

Key tools: `ssh_ela.sh` (daily login orchestrator: keypair → `cscs-key sign` → push cert to ela → interactive SSH; optional `<cscs_username>` arg, `-h`), `ela_show_HD_allocation_and_usage.sh` (Slurm node-hour usage report — must run on ela)
Stack: Bash | Deps: `cscs-key` (github.com/eth-cscs/cscs-key), OpenSSH
