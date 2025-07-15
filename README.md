# WordPress Deployment Repository

This repository contains WordPress files and automated deployment scripts for the Neuefische AWS Capstone Project. It works in conjunction with the Terraform infrastructure to deploy WordPress to EC2 instances via GitHub Actions.

## 📁 Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions deployment workflow
├── scripts/
│   └── deploy.sh              # Server-side deployment script
├── wordpress/
│   ├── wordpress-files.tar.gz # WordPress application files
│   └── wordpress-files01.tar.gz # Backup WordPress files
├── .env                       # Environment variables template
├── .gitignore                # Git ignore rules
├── deploy_template.py        # Python script to generate deployment template
├── wordpress.sql             # WordPress database dump
├── wordpress_01.sql          # Backup database dump
└── README.md                 # This file
```

## 🚀 Deployment Process

### Automated Deployment (GitHub Actions)

The deployment is triggered automatically when:
- Code is pushed to the `main` branch
- Pull requests are created/updated
- Manual workflow dispatch

### Deployment Flow

1. **Checkout Repository**: Downloads the latest code
2. **Setup SSH Key**: Configures SSH access using secrets
3. **Deploy to App Servers**: 
   - Connects to each app server via bastion host
   - Copies WordPress files and database dump
   - Executes deployment script on each server

## 🔧 Configuration

### Required GitHub Secrets

Set these secrets in your GitHub repository settings:

| Secret | Description | Example |
|--------|-------------|---------|
| `DEPLOY_KEY` | SSH private key for server access | `-----BEGIN RSA PRIVATE KEY-----...` |
| `BASTION_IP` | Public IP of bastion/web server | `54.123.45.67` |
| `BASTION_USER` | SSH user for bastion host | `ec2-user` |
| `APP_SERVER_IPS` | Comma-separated private IPs of app servers | `10.0.0.32,10.0.0.48` |
| `DEPLOY_USER` | SSH user for app servers | `ec2-user` |
| `DB_NAME` | RDS database name | `wordpress` |
| `DB_USER` | RDS database username | `root` |
| `DB_PASSWORD` | RDS database password | `your-secure-password` |
| `DB_ADDRESS` | RDS endpoint | `wordpress-db.xyz.rds.amazonaws.com` |

### WordPress Files Preparation

1. **Create WordPress Archive**:
   ```bash
   # On your local machine with WordPress installation
   tar -czf wordpress-files.tar.gz -C /path/to/wordpress .
   ```

2. **Export Database**:
   ```bash
   # Export your WordPress database
   mysqldump -u username -p database_name > wordpress.sql
   ```

3. **Update Repository**:
   ```bash
   # Place files in the wordpress/ directory
   cp wordpress-files.tar.gz wordpress/
   cp wordpress.sql .
   git add .
   git commit -m "Update WordPress files and database"
   git push origin main
   ```

## 🛠️ Manual Deployment

If you need to deploy manually:

```bash
# 1. SSH to bastion host
ssh -i your-key.pem ec2-user@BASTION-IP

# 2. Copy files to app server
scp wordpress-files.tar.gz ec2-user@APP-SERVER-IP:/tmp/
scp wordpress.sql ec2-user@APP-SERVER-IP:/tmp/
scp deploy.sh ec2-user@APP-SERVER-IP:/tmp/

# 3. SSH to app server and deploy
ssh ec2-user@APP-SERVER-IP
DB_NAME='wordpress' DB_USER='root' DB_PASSWORD='password' DB_ADDRESS='rds-endpoint' bash /tmp/deploy.sh
```

## 📋 Deployment Script Features

The `deploy.sh` script performs:

- ✅ **Service Management**: Stops/starts Apache gracefully
- 📦 **File Deployment**: Extracts WordPress files to web root
- 🔐 **Permissions**: Sets proper Apache ownership and permissions
- 📄 **Configuration**: Creates `.env` file with database credentials
- 🛢️ **Database Import**: Imports WordPress database to RDS
- 🔄 **URL Updates**: Updates WordPress site URLs for new domain
- 🧹 **Cleanup**: Removes temporary files after deployment

## 🔄 WordPress URL Management

The deployment script automatically updates WordPress URLs:

```sql
-- Updates site URL and home URL
UPDATE wp_options SET option_value = 'new-domain.com' WHERE option_name IN ('siteurl', 'home');

-- Updates post content and GUIDs
UPDATE wp_posts SET guid = REPLACE(guid, 'old-url', 'new-url');
UPDATE wp_posts SET post_content = REPLACE(post_content, 'old-url', 'new-url');
```

## 🚨 Troubleshooting

### Common Issues

1. **SSH Connection Failed**:
   - Verify bastion host IP and app server IPs
   - Check SSH key permissions (should be 400)
   - Ensure security groups allow SSH access

2. **File Copy Failed**:
   - Check if files exist in repository
   - Verify file permissions and sizes
   - Ensure sufficient disk space on target servers

3. **Database Import Failed**:
   - Verify RDS credentials and endpoint
   - Check database connectivity from app servers
   - Ensure database exists and user has proper permissions

4. **WordPress Not Loading**:
   - Check Apache service status: `sudo systemctl status httpd`
   - Verify file permissions: `ls -la /var/www/html/`
   - Check WordPress configuration in `.env` file

### Debug Commands

```bash
# Check deployment logs
tail -f /var/log/httpd/error_log

# Test database connection
mysql -h RDS-ENDPOINT -u USERNAME -p

# Verify WordPress files
ls -la /var/www/html/

# Check Apache configuration
sudo httpd -t
```

## 🔒 Security Considerations

- **SSH Keys**: Store private keys securely in GitHub Secrets
- **Database Credentials**: Never commit credentials to repository
- **File Permissions**: Ensure proper Apache ownership (apache:apache)
- **Network Access**: Use bastion host for secure access to private servers
- **Environment Variables**: Use `.env` files for sensitive configuration

## 🔗 Related Infrastructure

This deployment repository works with:
- **Terraform Infrastructure**: [neuefische-aws-capstone-project](../neuefische-aws-capstone-project/)
- **AWS Resources**: VPC, EC2, RDS, ALB, Auto Scaling Group
- **GitHub Actions**: Automated CI/CD pipeline

## 📝 Development Workflow

1. **Local Development**: Develop WordPress locally
2. **Export**: Create tar.gz and SQL dump
3. **Commit**: Push files to this repository
4. **Deploy**: GitHub Actions automatically deploys to AWS
5. **Verify**: Check deployment via ALB DNS name

## 🎯 Next Steps

- Add SSL/TLS certificate configuration
- Implement blue-green deployment strategy
- Add automated testing before deployment
- Configure WordPress caching and optimization
- Set up monitoring and alerting

---

**Note**: This is part of the Neuefische AWS Capstone Project demonstrating Infrastructure as Code, CI/CD, and cloud-native WordPress deployment.