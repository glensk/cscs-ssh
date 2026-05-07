#!/usr/bin/env bash
# Daily SSH login flow for CSCS (ela.cscs.ch).
#
# Migration note (2026-05-04): the legacy POST-username/password/OTP API at
# sshservice.cscs.ch is decommissioned. This script now uses the new `cscs-key`
# CLI (https://github.com/eth-cscs/cscs-key), which signs a *locally* generated
# keypair via OIDC SSO. Run once interactively to do the browser SSO; the OIDC
# token then caches for ~24h so subsequent invocations are silent.
#
# Usage:
#   bash ssh_ela.sh              # uses $my_cscs_username (default: aglensk)
#   bash ssh_ela.sh <username>   # for any other CSCS account

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
echor () { printf "${RED}[ %s ] %s${NC}\n"   "$(basename "$0")" "$1"; }
echog () { printf "${GREEN}[ %s ] %s${NC}\n" "$(basename "$0")" "$1"; }
echob () { printf "${BLUE}[ %s ] %s${NC}\n"  "$(basename "$0")" "$1"; }

print_help () {
    cat <<EOF
Usage: $(basename "$0") [-h|--help] [<cscs_username>]

Daily SSH login to ela.cscs.ch using a locally-generated ed25519 keypair
signed by CSCS via the new \`cscs-key\` CLI.

Options:
  -h, --help    Show this help and exit.

Arguments:
  <cscs_username>   Optional. Defaults to 'aglensk' for \$USER in {glensk,
                    albert}; otherwise required.

Behaviour:
  1. Short-circuits if the OpenSSH ControlMaster socket to ela is alive.
  2. Generates ~/.ssh/cscs_daily_key/cscs-key{,.pub} once if missing.
  3. Runs \`cscs-key sign\` if the cert is missing or older than 24h.
  4. SCPs the keypair + cert to ela so chained jumps to daint/eiger work.
  5. Opens an interactive SSH session to ela.cscs.ch.

First run opens a browser for CSCS OIDC SSO (token caches ~24h).
EOF
}

case "$1" in
    -h|--help) print_help; exit 0 ;;
esac

[ "$(command -v ssh-keygen)" = "" ] && echor "ssh-keygen not found. Install OpenSSH." && exit 1
[ "$(command -v cscs-key)"   = "" ] && echor "cscs-key not found. Install from https://github.com/eth-cscs/cscs-key/releases (place binary in PATH, e.g. ~/.local/bin)." && exit 1


ssh_ela () {
    my_cscs_username="$1"
    if { [ "$USER" = "glensk" ] || [ "$USER" = "albert" ]; } && [ -z "$1" ]; then
        my_cscs_username="aglensk"
    fi
    if [ -z "$my_cscs_username" ]; then
        echor "my_cscs_username is empty. Pass it as the first argument. Exit."
        return 1
    fi
    echog "my_cscs_username: $my_cscs_username"

    folder_ssh="$HOME/.ssh"
    folder_cscs="$folder_ssh/cscs_daily_key"
    cscs_private_key="$folder_cscs/cscs-key"
    cscs_public_key="$folder_cscs/cscs-key.pub"
    cscs_cert="$folder_cscs/cscs-key-cert.pub"

    [ ! -d "$folder_cscs" ] && mkdir -p "$folder_cscs"
    folder_control_path_files="$folder_ssh/ControlPath_files"
    [ ! -d "$folder_control_path_files" ] && mkdir -p "$folder_control_path_files"
    control_path_file="$folder_control_path_files/$my_cscs_username@ela.cscs.ch:22"

    # 1) ControlMaster short-circuit: if ela is already connected, just refresh
    #    the cert on ela (cert may have rotated since the master was opened).
    if [ -e "$control_path_file" ]; then
        echog "ControlPath socket exists at $control_path_file"
        back=$(ssh ela "hostname" 2>/dev/null | cut -c-3)
        if [ "$back" = "ela" ]; then
            echog "Connected to ela via ControlMaster — pushing cert + key, no SSH login needed."
            if [ -e "$cscs_cert" ];        then scp -i "$cscs_private_key" "$cscs_cert"        "$my_cscs_username@ela.cscs.ch:/users/$my_cscs_username/.ssh/cscs-key-cert.pub"; fi
            if [ -e "$cscs_private_key" ]; then scp -i "$cscs_private_key" "$cscs_private_key" "$my_cscs_username@ela.cscs.ch:/users/$my_cscs_username/.ssh/cscs-key"; fi
            return 0
        else
            echob "Stale ControlPath socket — removing and continuing."
            rm -f "$control_path_file"
        fi
    fi

    # 2) Persistent local keypair: generate once, never rotate automatically.
    #    `cscs-key` refuses to sign legacy server-generated keys, so a clean
    #    locally-generated ed25519 pair is required.
    if [ ! -e "$cscs_private_key" ] || [ ! -e "$cscs_public_key" ]; then
        echob "No persistent local keypair found at $cscs_private_key — generating ed25519 keypair (one-time)."
        rm -f "$cscs_private_key" "$cscs_public_key" "$cscs_cert"
        ssh-keygen -t ed25519 -N '' -C "$my_cscs_username@cscs $(date +%F)" -f "$cscs_private_key" || {
            echor "ssh-keygen failed. Exit."
            return 1
        }
        echog "Generated $cscs_private_key + $cscs_public_key"
    fi

    # 3) Cert freshness: cert is the only thing that rotates daily.
    needs_sign="false"
    if [ ! -e "$cscs_cert" ]; then
        echob "Cert $cscs_cert missing — will sign."
        needs_sign="true"
    elif [ -n "$(find "$cscs_cert" -mmin +1380 -print 2>/dev/null)" ]; then
        echob "Cert $cscs_cert is older than 23h — will re-sign (cert expires at 24h)."
        needs_sign="true"
    else
        echog "Cert $cscs_cert is fresh (<23h) — skipping cscs-key sign."
    fi

    if [ "$needs_sign" = "true" ]; then
        echog "Running: cscs-key sign -f $cscs_private_key"
        echog "(first run today may open a browser for CSCS OIDC SSO)"
        cscs-key sign -f "$cscs_private_key" || {
            echor "cscs-key sign failed. Exit."
            return 1
        }
    fi

    # 4) Sanity: cert must exist and be fresh after the sign step.
    if [ ! -e "$cscs_cert" ]; then
        echor "$cscs_cert does not exist after sign. Exit."
        return 1
    fi
    if [ -n "$(find "$cscs_cert" -mmin +1440 -print 2>/dev/null)" ]; then
        echor "$cscs_cert exists but is older than 24h. Exit."
        return 1
    fi

    # 5) Push cert + key to ela so chained jumps (ela → daint/eiger) work.
    echog "scp $cscs_cert        → $my_cscs_username@ela.cscs.ch:.ssh/cscs-key-cert.pub"
    scp -i "$cscs_private_key" "$cscs_cert"        "$my_cscs_username@ela.cscs.ch:/users/$my_cscs_username/.ssh/cscs-key-cert.pub"
    echog "scp $cscs_private_key → $my_cscs_username@ela.cscs.ch:.ssh/cscs-key"
    scp -i "$cscs_private_key" "$cscs_private_key" "$my_cscs_username@ela.cscs.ch:/users/$my_cscs_username/.ssh/cscs-key"

    echo "#############################################################"
    echo "# Now logging you into ela.                                 #"
    echo "# Once there, jump on with:                                 #"
    echo "#   ssh -i ~/.ssh/cscs-key daint.alps                       #"
    echo "#   ssh -i ~/.ssh/cscs-key eiger                            #"
    echo "#############################################################"
    ssh -i "$cscs_private_key" "$my_cscs_username@ela.cscs.ch"
}

ssh_ela "$1"
