#!/bin/bash
set -e

echo "📦 Unpacking WordPress..."
sudo systemctl stop httpd || true
sudo rm -rf /var/www/html/*
sudo mkdir -p /var/www/html
sudo tar -xzf /tmp/wordpress-files.tar.gz -C /var/www/html/
sudo chown -R apache:apache /var/www/html/

echo "📄 Writing .env file..."
sudo bash -c "cat > /var/www/html/.env" <<EOT
DB_NAME='${DB_NAME}'
DB_USER='${DB_USER}'
DB_PASSWORD='${DB_PASSWORD}'
DB_ADDRESS='${DB_ADDRESS}'
EOT
sudo chown apache:apache /var/www/html/.env
sudo chmod 640 /var/www/html/.env

echo "🛢️ Importing database..."
mysql -h "${DB_ADDRESS}" -u "${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" < /tmp/wordpress.sql

echo "✅ Restarting HTTPD"
sudo systemctl start httpd

echo "🧹 Cleaning up temp files..."
rm -f /tmp/wordpress-files.tar.gz /tmp/wordpress.sql
echo "🎉 Deployment complete! Visit your WordPress site."