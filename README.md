# wordpress-app

Containerized WordPress build that complements the `wordpress-iac` infrastructure repo. The image uses the official `wordpress:php8.2-apache` base, adds a health probe, and renders `wp-config.php` from SSM-provided environment variables so EC2 Auto Scaling instances stay stateless (no shared FS/EFS needed).

## Runtime expectations
- Required environment variables: `WORDPRESS_DB_HOST`, `WORDPRESS_DB_NAME`, `WORDPRESS_DB_USER`, `WORDPRESS_DB_PASSWORD`, `WP_HOME`, `WP_SITEURL`, and the WordPress salts (`WP_AUTH_KEY`, etc.).
- Health endpoint: `/healthz.php` returns HTTP 200 for ALB checks.
- WordPress content lives in `/var/www/html`; user data in `wordpress-iac` pulls configs from SSM and restarts the container.

## CI/CD
- Workflow: `.github/workflows/ci-cd.yml`
- Jobs:
  1. **Security scan** – `aquasecurity/trivy-action` runs in filesystem mode (HIGH/CRITICAL) and uploads SARIF results so Code Scanning shows the same findings as the build.
  2. **Build & deploy** – sets up QEMU + Buildx, builds a **multi-arch** image (`linux/amd64, linux/arm64`) so Graviton instances can pull it, pushes `latest` + commit SHA tags to ECR, then triggers an Auto Scaling instance refresh (`wpdemo-dev-wp-asg`).
- Auth: GitHub OIDC role (`wpdemo-dev-github-oidc`) configured in the IaC repo.
- Update the ECR repo/role names in `envs/dev` if you fork this project.

## Local build
```bash
docker build -t wordpress-app:dev .
docker run --rm -p 8080:80 \
  -e WORDPRESS_DB_HOST=db.example \
  -e WORDPRESS_DB_NAME=wordpress \
  -e WORDPRESS_DB_USER=wpuser \
  -e WORDPRESS_DB_PASSWORD=secret \
  -e WP_HOME=http://localhost:8080 \
  -e WP_SITEURL=http://localhost:8080 \
  wordpress-app:dev
```

> Docker Compose is not required for the cloud deployment because WordPress runs inside the Auto Scaling Group and relies on RDS. For local tinkering you can pair this image with a throwaway MySQL container, but it’s intentionally omitted to keep the repo focused on the production deployment path.
