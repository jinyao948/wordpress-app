FROM wordpress:php8.2-apache

ENV WORDPRESS_DATA_DIR=/var/www/html \
    WP_CONFIG_TEMPLATE=/usr/src/app/wp-config.php.template

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends gettext-base curl; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p /usr/src/app /docker-entrypoint-initwp.d

COPY wp-config.php.template ${WP_CONFIG_TEMPLATE}
COPY healthz.php /usr/src/wordpress/healthz.php

RUN cat <<'SCRIPT' > /docker-entrypoint-initwp.d/10-render-wp-config.sh && \
    chmod +x /docker-entrypoint-initwp.d/10-render-wp-config.sh
#!/bin/bash
set -euo pipefail
if [ -f "$WORDPRESS_DATA_DIR/wp-config.php" ]; then
  echo "wp-config.php already present; skipping template render."
  exit 0
fi
required_vars=(WORDPRESS_DB_HOST WORDPRESS_DB_NAME WORDPRESS_DB_USER WORDPRESS_DB_PASSWORD WP_HOME WP_SITEURL)
for var in "${required_vars[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "Missing required env var: $var" >&2
    exit 1
  fi
fi
envsubst < "$WP_CONFIG_TEMPLATE" > "$WORDPRESS_DATA_DIR/wp-config.php"
SCRIPT

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD curl -fsS http://127.0.0.1/healthz.php || exit 1
