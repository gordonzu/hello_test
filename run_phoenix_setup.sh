#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

cleanup() {
  docker compose down -v --remove-orphans >/dev/null 2>&1 || true
}

cleanup

docker compose build
docker compose up -d postgres phoenix

docker compose exec -T phoenix bash -lc '
set -euo pipefail

if ! mix local.hex --force; then
  mix archive.install github hexpm/hex branch latest --force
fi
mix archive.install hex phx_new --force

mkdir -p environment
cd environment
rm -rf hello_test
mix phx.new hello_test --database postgres --no-install

cd hello_test
mix deps.get
sed -i "s/hostname: \"localhost\"/hostname: \"postgres\"/" config/dev.exs

mix ecto.create
timeout 30s mix phx.server
'

cleanup
