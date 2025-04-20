#!/bin/bash
set -e

CONFIG_FILE="/data/bitcoin.conf"
RPC_USER="rpcuser"

# Default values
RPC_PORT="${RPC_PORT:-8332}"
RPC_AUTH_SCRIPT="/opt/bitcoin/rpcauth.py"

# Generate config if not exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "[i] No config found. Generating default config..."
  PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
  AUTH_LINE=$(python3 "$RPC_AUTH_SCRIPT" "$RPC_USER" | tail -n 1)

  cat > "$CONFIG_FILE" <<EOF
server=1
daemon=0
txindex=1
proxy=tor-proxy:9050
onlynet=onion
rpcbind=0.0.0.0
rpcallowip=0.0.0.0/0
rpcport=$RPC_PORT
rpcuser=$RPC_USER
rpcpassword=$AUTH_LINE
EOF

  echo "[i] New rpc password: $PASSWORD"
else
  echo "[i] Using existing config."
fi

# Start watchdog in background
/watchdog.sh &

# Start bitcoind
exec bitcoind -datadir=/data -conf="$CONFIG_FILE"
