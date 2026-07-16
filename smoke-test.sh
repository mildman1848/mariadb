#!/usr/bin/env bash
set -euo pipefail

image="${1:?Usage: smoke-test.sh IMAGE}"
name="mariadb-smoke-$$"
tmpdir="$(mktemp -d)"
DOCKER_BIN="${DOCKER:-docker}"
app_pw="app-change-me-$RANDOM-$$"
root_pw="root-change-me-$RANDOM-$$"

cleanup() {
  ${DOCKER_BIN} rm -f "$name" >/dev/null 2>&1 || true
  rm -rf "$tmpdir"
}
trap cleanup EXIT

mkdir -p "$tmpdir/config"
printf '%s' "$app_pw" > "$tmpdir/mysql_password"
printf '%s' "$root_pw" > "$tmpdir/mysql_root_password"
chmod 600 "$tmpdir/mysql_password" "$tmpdir/mysql_root_password"

${DOCKER_BIN} run -d --name "$name" \
  -e PUID="$(id -u)" \
  -e PGID="$(id -g)" \
  -e MYSQL_DATABASE=smoke \
  -e MYSQL_USER=smoke \
  -e FILE__MYSQL_PASSWORD=/run/secrets/mysql_password \
  -e FILE__MYSQL_ROOT_PASSWORD=/run/secrets/mysql_root_password \
  -v "$tmpdir/config:/config" \
  -v "$tmpdir/mysql_password:/run/secrets/mysql_password:ro" \
  -v "$tmpdir/mysql_root_password:/run/secrets/mysql_root_password:ro" \
  "$image"

for _ in {1..90}; do
  if ${DOCKER_BIN} exec "$name" /usr/local/bin/healthcheck >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

${DOCKER_BIN} exec "$name" /usr/local/bin/healthcheck >/dev/null

${DOCKER_BIN} exec "$name" sh -lc "MYSQL_PWD='$app_pw' mariadb -h127.0.0.1 -P3306 -usmoke smoke -N -B -e 'SELECT 1;'" | grep -qx '1'

if ${DOCKER_BIN} exec "$name" sh -lc "MYSQL_PWD='definitely-wrong-password' mariadb -h127.0.0.1 -P3306 -usmoke smoke -e 'SELECT 1;'" >/dev/null 2>&1; then
  echo 'ERROR: MariaDB accepted a deliberately wrong password' >&2
  exit 1
fi

process_users="$(${DOCKER_BIN} exec "$name" sh -lc "ps aux | awk '\$11 ~ /mariadbd/ {print \$1}' | sort -u")"
if [[ -z "$process_users" ]]; then
  echo 'ERROR: no MariaDB process found' >&2
  ${DOCKER_BIN} logs "$name" >&2 || true
  exit 1
fi
if grep -qx 'root' <<<"$process_users"; then
  echo 'ERROR: MariaDB process is running as root' >&2
  exit 1
fi
if ! grep -qx 'abc' <<<"$process_users"; then
  echo "ERROR: MariaDB process did not run as abc; observed: $process_users" >&2
  exit 1
fi

logs="$(${DOCKER_BIN} logs "$name" 2>&1 || true)"
if grep -F "$app_pw" <<<"$logs" >/dev/null || grep -F "$root_pw" <<<"$logs" >/dev/null; then
  echo 'ERROR: generated MariaDB secret leaked into container logs' >&2
  exit 1
fi

echo 'MariaDB smoke test passed: health, auth, wrong-password rejection, abc process user, no secret leak'
