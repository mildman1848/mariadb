#!/usr/bin/env bash
set -euo pipefail

image="${1:?Usage: smoke-test.sh IMAGE}"
name="mariadb-smoke-$$"
tmpdir="$(mktemp -d)"
app_pw="app-change-me"
root_pw="root-change-me"
trap '${DOCKER:-docker} rm -f "$name" >/dev/null 2>&1 || true; rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/config"
printf '%s' "$app_pw" > "$tmpdir/mysql_password"
printf '%s' "$root_pw" > "$tmpdir/mysql_root_password"

${DOCKER:-docker} run -d --name "$name"   -e PUID="$(id -u)"   -e PGID="$(id -g)"   -e MYSQL_DATABASE=smoke   -e MYSQL_USER=smoke   -e FILE__MYSQL_PASSWORD=/run/secrets/mysql_password   -e FILE__MYSQL_ROOT_PASSWORD=/run/secrets/mysql_root_password   -v "$tmpdir/config:/config"   -v "$tmpdir/mysql_password:/run/secrets/mysql_password:ro"   -v "$tmpdir/mysql_root_password:/run/secrets/mysql_root_password:ro"   "$image"

for _ in {1..90}; do
  if ${DOCKER:-docker} exec "$name" sh -lc "MYSQL_PWD='$app_pw' mariadb -h127.0.0.1 -P3306 -usmoke smoke -e 'SELECT 1;'" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

${DOCKER:-docker} exec "$name" sh -lc "MYSQL_PWD='$app_pw' mariadb -h127.0.0.1 -P3306 -usmoke smoke -e 'SELECT 1;'" >/dev/null

if ${DOCKER:-docker} exec "$name" sh -lc "MYSQL_PWD='definitely-wrong' mariadb -h127.0.0.1 -P3306 -usmoke smoke -e 'SELECT 1;'" >/dev/null 2>&1; then
  echo "MariaDB smoke test failed: invalid password accepted" >&2
  exit 1
fi

echo "MariaDB smoke test passed"
