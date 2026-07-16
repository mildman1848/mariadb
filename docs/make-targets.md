# Make Targets

MariaDB follows the master Docker image template Makefile pattern with MariaDB-specific smoke/start behavior.

## Common local workflow

```bash
make env-setup
make validate
make build DOCKER='sudo docker'
make smoke DOCKER='sudo docker'
make security-scan DOCKER='sudo docker' TRIVY='sudo trivy'
make sbom DOCKER='sudo docker' SYFT='sudo syft'
make start DOCKER='sudo docker'
make status DOCKER='sudo docker'
make logs DOCKER='sudo docker'
```

## Core targets

| Target | Purpose |
|---|---|
| `make info` | Print image metadata and effective refs. |
| `make version` | Print `11.8.8-mldm2`. |
| `make env-setup` | Create local `.env` from `.env.example`. |
| `make env-validate` | Validate version/revision metadata. |
| `make lint` | Static repo checks, s6 checks, private-term scan, Hadolint. |
| `make validate` | `lint` + env validation + Actionlint. |
| `make test` | `validate` + MariaDB smoke test. |
| `make build` | Build local single-platform image with Buildx `--load`. |
| `make smoke` | Start temporary container and run authenticated MariaDB query checks. |
| `make labels` | Inspect OCI labels of the built image. |
| `make security-scan` | Trivy config scan plus image scan if built. |
| `make sbom` | Generate SPDX JSON SBOM in `sbom/`. |
| `make start` | Start a persistent local dev MariaDB container. |
| `make stop` | Stop/remove the dev container. |
| `make logs` | Show dev container logs. |
| `make shell` | Open debug shell in image. |
| `make check-upstream` | Show LSIO base and Alpine package signal. |
| `make release-dry-run` | Print intended publish refs without pushing. |

## Secrets

`make secrets` and `make secrets-generate` create:

```text
secrets/mysql_password.txt
secrets/mysql_root_password.txt
```

Both are generated with 96 CSPRNG characters, mode `0600`, and never printed to stdout.

## Important local Docker note

On systems where the current user cannot access `/var/run/docker.sock`, use matching privileges for Docker-backed tools:

```bash
make build DOCKER='sudo docker'
make security-scan DOCKER='sudo docker' TRIVY='sudo trivy'
make sbom DOCKER='sudo docker' SYFT='sudo syft'
```

Using `DOCKER='sudo docker'` alone is not enough for Trivy/Syft, because those tools also need Docker socket access.
