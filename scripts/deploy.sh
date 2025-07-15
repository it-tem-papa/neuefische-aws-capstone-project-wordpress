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

echo "🔁 Updating WordPress site URL..."

NEW_URL="app-lb-457439893.us-west-2.elb.amazonaws.com"  # Change this to your current domain

# Update wp_options table
mysql -h "${DB_ADDRESS}" -u "${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" <<SQL
UPDATE wp_options SET option_value = '${NEW_URL}' WHERE option_name IN ('siteurl', 'home');
SQL

# This does a search and replace in post/page content and GUIDs
mysql -h "${DB_ADDRESS}" -u "${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" <<SQL
UPDATE wp_posts SET guid = REPLACE(guid, 'http://oldurl.local', '${NEW_URL}');
UPDATE wp_posts SET post_content = REPLACE(post_content, 'http://oldurl.local', '${NEW_URL}');
SQL

echo "✅ Restarting HTTPD"
sudo systemctl start httpd

echo "🧹 Cleaning up temp files..."
rm -f /tmp/wordpress-files.tar.gz /tmp/wordpress.sql
echo "🎉 Deployment complete! Visit your WordPress site."