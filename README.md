# wordpress-app

Containerized WordPress build that complements the `wordpress-iac` infrastructure repo. The image uses the official `wordpress:php8.2-apache` base, adds a health probe, and renders `wp-config.php` from SSM-provided environment variables so EC2 Auto Scaling instances stay stateless.

## Runtime expectations
- Required environment variables: `WORDPRESS_DB_HOST`, `WORDPRESS_DB_NAME`, `WORDPRESS_DB_USER`, `WORDPRESS_DB_PASSWORD`, `WP_HOME`, `WP_SITEURL`, and the WordPress salts (`WP_AUTH_KEY`, etc.).
- Health endpoint: `/healthz.php` returns HTTP 200 for ALB checks.
- WordPress content lives in `/var/www/html`; user data in `wordpress-iac` pulls configs from SSM and restarts the container.

## CI/CD
A GitHub Actions workflow builds this image on every push to `main`, logs into Amazon ECR via OIDC, pushes `latest` and commit-SHA tags, then triggers an Auto Scaling instance refresh (`wpdemo-dev-wp-asg`). Update the IAM role and repository settings in `wordpress-iac` to match your AWS account.

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
