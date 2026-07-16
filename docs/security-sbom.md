# Security and SBOM

MariaDB uses the master template security/SBOM pattern with database-specific smoke tests.

## Local targets

| Target | Tool | Purpose |
|---|---|---|
| `make security-scan` | Trivy | Config scan plus image scan when the image exists locally. |
| `make trivy-scan` / `make scan` | Trivy | Image vulnerability scan. |
| `make sbom` | Syft | Generate a local SPDX JSON SBOM under `sbom/`. |

## MariaDB smoke/security checks

The smoke test must prove more than "the port opened":

- MariaDB starts under s6-overlay.
- Healthcheck succeeds from inside the container.
- The image supports `FILE__MYSQL_PASSWORD` and `FILE__MYSQL_ROOT_PASSWORD`.
- A valid authenticated query succeeds.
- A deliberately wrong password is rejected.
- The long-running MariaDB process runs as `abc`.

## LSIO-specific scanner notes

Trivy rule `DS-0002` recommends a final Dockerfile `USER`. For LSIO/s6 images this is intentionally not used: `/init` and s6 initialization need root, then the final MariaDB process must drop to `abc` with `s6-setuidgid abc`. Treat this as a documented LSIO exception, not permission to run MariaDB as root.

When the local Docker socket requires sudo, image scanners need matching privileges:

```bash
make security-scan DOCKER='sudo docker' TRIVY='sudo trivy'
make sbom DOCKER='sudo docker' SYFT='sudo syft'
```

## Secret policy

- Generate local secrets with `make secrets` or `make secrets-generate`.
- Use 96-character CSPRNG values by default.
- Store generated files mode `0600`.
- Never print secret values to stdout, logs, CI summaries, or README examples.
