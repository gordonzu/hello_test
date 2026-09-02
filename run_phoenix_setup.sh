#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

cleanup() {
  docker compose down -v --remove-orphans >/dev/null 2>&1 || true
}

trap cleanup EXIT
cleanup

docker compose build
docker compose up -d postgres phoenix

PHOENIX_CONTAINER_ID="$(docker compose ps -q phoenix)"
if [[ -n "${NODE_EXTRA_CA_CERTS:-}" && -f "${NODE_EXTRA_CA_CERTS}" ]]; then
  docker cp "${NODE_EXTRA_CA_CERTS}" "${PHOENIX_CONTAINER_ID}:/usr/local/share/ca-certificates/copilot-rootCA.crt"
  docker compose exec -T phoenix update-ca-certificates
fi

docker compose exec -T phoenix bash -lc '
set -euo pipefail

cat > /tmp/erl_inetrc <<EOF
{inet6,false}.
EOF
export ERL_INETRC=/tmp/erl_inetrc

if ! mix local.hex --force; then
  mix archive.install github hexpm/hex branch latest --force
fi
if ! mix archive.install hex phx_new --force; then
  mix archive.install github phoenixframework/phoenix tag v1.7.14 --sparse installer --force
fi

mkdir -p environment
cd environment
rm -rf hello_test
mix phx.new hello_test --database postgres --no-install

cd hello_test
mix deps.get
sed -i "s/hostname: \"localhost\"/hostname: \"postgres\"/" config/dev.exs

mix ecto.create
set +e
timeout 30s mix phx.server
server_status=$?
set -e
if [ "$server_status" -ne 0 ] && [ "$server_status" -ne 124 ]; then
  exit "$server_status"
fi
'
