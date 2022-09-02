#!/bin/sh
set -e

echoerr() { echo "$@" 1>&2; }

# Split out host and port from DB_HOST env variable
DB_HOST_NAME=$(echo "$DB_HOST" | cut -d ":" -f 1)
DB_PORT_TMP=$(echo "$DB_HOST" | cut -sd ":" -f 2)
if [ -z $DB_PORT_TMP ]; then 
  DB_PORT=${DB_PORT:-3306};
else
  DB_PORT=$DB_PORT_TMP;
fi

if [ ! -f "$BOOKSTACK_HOME/.env" ]; then
  # shellcheck disable=SC2039
  if [[ "${DB_HOST}" ]]; then
  cat > "$BOOKSTACK_HOME/.env" <<EOF
      # Environment
      APP_ENV=production
      APP_DEBUG=${APP_DEBUG:-false}
      APP_KEY=${APP_KEY:-SomeRandomStringWith32Characters}
      APP_LANG=${APP_LANG:-en}

      # The below url has to be set if using social auth options
      # or if you are not using BookStack at the root path of your domain.
      APP_URL=${APP_URL:-null}

      APP_VIEWS_BOOKS=${APP_VIEWS_BOOKS:-grid}
      # Database details
      DB_HOST=${DB_HOST:-localhost}
      DB_PORT=${DB_PORT}
      DB_DATABASE=${DB_DATABASE:-bookstack}
      DB_USERNAME=${DB_USERNAME:-bookstack}
      DB_PASSWORD=${DB_PASSWORD:-password}

      # Cache and session
      CACHE_DRIVER=file
      SESSION_DRIVER=file
      # If using Memcached, comment the above and uncomment these
      #CACHE_DRIVER=memcached
      #SESSION_DRIVER=memcached
      QUEUE_DRIVER=sync

      # Memcached settings
      # If using a UNIX socket path for the host, set the port to 0
      # This follows the following format: HOST:PORT:WEIGHT
      # For multiple servers separate with a comma
      MEMCACHED_SERVERS=127.0.0.1:11211:100

      # Storage
      STORAGE_TYPE=${STORAGE_TYPE:-local}
      # Amazon S3 Config
      STORAGE_S3_KEY=${STORAGE_S3_KEY:-false}
      STORAGE_S3_SECRET=${STORAGE_S3_SECRET:-false}
      STORAGE_S3_REGION=${STORAGE_S3_REGION:-false}
      STORAGE_S3_BUCKET=${STORAGE_S3_BUCKET:-false}
      # Storage URL
      # Used to prefix image urls for when using custom domains/cdns
      STORAGE_URL=${STORAGE_URL:-false}

      # General auth
      AUTH_METHOD=${AUTH_METHOD:-standard}

      SAML2_NAME=${SAML2_NAME:-null}
      SAML2_EMAIL_ATTRIBUTE=${SAML2_EMAIL_ATTRIBUTE:-null}
      SAML2_EXTERNAL_ID_ATTRIBUTE=${SAML2_EXTERNAL_ID_ATTRIBUTE:-null} # not sure if this correct, keycloak may be overriding with force name id format set to ON
      SAML2_DISPLAY_NAME_ATTRIBUTES=${SAML2_DISPLAY_NAME_ATTRIBUTES:-null}
      SAML2_IDP_ENTITYID=${SAML2_IDP_ENTITYID:-null}
      SAML2_AUTOLOAD_METADATA=${SAML2_AUTOLOAD_METADATA:-false}

      OIDC_NAME=${OIDC_NAME:-null}
      OIDC_DISPLAY_NAME_CLAIMS=${OIDC_DISPLAY_NAME_CLAIMS:-null}
      OIDC_CLIENT_ID=${OIDC_CLIENT_ID:-null}
      OIDC_CLIENT_SECRET=${OIDC_CLIENT_SECRET:-null}
      OIDC_ISSUER=${OIDC_ISSUER:-null}
      OIDC_ISSUER_DISCOVER=${OIDC_ISSUER_DISCOVER:-false}

      # Social Authentication information. Defaults as off.
      GITHUB_APP_ID=${GITHUB_APP_ID:-false}
      GITHUB_APP_SECRET=${GITHUB_APP_SECRET:-false}
      GOOGLE_APP_ID=${GOOGLE_APP_ID:-false}
      GOOGLE_APP_SECRET=${GOOGLE_APP_SECRET:-false}

      # External services such as Gravatar
      DISABLE_EXTERNAL_SERVICES=${DISABLE_EXTERNAL_SERVICES:-false}

      # LDAP Settings
      LDAP_SERVER=${LDAP_SERVER:-false}
      LDAP_BASE_DN=${LDAP_BASE_DN:-false}
      LDAP_DN=${LDAP_DN:-false}
      LDAP_PASS=${LDAP_PASS:-false}
      LDAP_USER_FILTER=${LDAP_USER_FILTER:-false}
      LDAP_VERSION=${LDAP_VERSION:-false}

      # Mail settings
      MAIL_DRIVER=${MAIL_DRIVER:-smtp}
      MAIL_HOST=${MAIL_HOST:-localhost}
      MAIL_PORT=${MAIL_PORT:-1025}
      MAIL_USERNAME=${MAIL_USERNAME:-null}
      MAIL_PASSWORD=${MAIL_PASSWORD:-null}
      MAIL_ENCRYPTION=${MAIL_ENCRYPTION:-null}
      # URL used for social login redirects, NO TRAILING SLASH

      WKHTMLTOPDF=${WKHTMLTOPDF:-false}
EOF

cat $BOOKSTACK_HOME/.env
sed -ie "s/single/errorlog/g" "$BOOKSTACK_HOME/app/Config/app.php"
    else
        echo >&2 'error: missing DB_HOST environment variable'
        exit 1
    fi
fi

echoerr "wait-for-db: waiting for ${DB_HOST_NAME}:${DB_PORT}"

dockerize -wait tcp://${DB_HOST_NAME}:${DB_PORT} -timeout 15s

RESULT=$?

if [ $RESULT -eq 0 ]; then
  # sleep another second for so that we don't get a "the database system is starting up" error
  sleep 1
  echoerr "wait-for-db: done"
else
  echoerr "wait-for-db: timeout out after 15 seconds waiting for ${DB_HOST_NAME}:${DB_PORT}"
fi

php artisan key:generate --force

php artisan migrate --database=mysql --force

echo "Setting folder permissions for uploads"
chown -R www-data:www-data public/uploads && chmod -R 775 public/uploads
chown -R www-data:www-data storage/uploads && chmod -R 775 storage/uploads

php artisan cache:clear

php artisan view:clear

exec "$@"
