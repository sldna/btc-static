#!/bin/bash

CHECK_INTERVAL=60

while true; do
  sleep $CHECK_INTERVAL
  if ! bitcoin-cli -datadir=/data getblockchaininfo >/dev/null 2>&1; then
    echo "[!] bitcoind not responding. Restarting..."
    pkill -9 bitcoind
  fi
done
