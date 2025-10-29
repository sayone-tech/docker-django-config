# Jenkins Pipeline Setup Guide

## Overview

The updated Jenkinsfile_AWS follows modern CI/CD best practices with improved structure, error handling, and flexibility.

## Key Features

### 1. **Config-Only Updates**
- New parameter `UPDATE_CONFIG_ONLY` allows updating environment files and restarting services without rebuilding images
- Useful for quick configuration changes in production

### 2. **Dynamic Environment Configuration**
- Environment-specific settings defined in `Setup Environment` stage
- Easy to add new environments (staging, production, etc.)
- Centralized configuration management

### 3. **Improved Slack Notifications**
- Emoji-based status indicators (🚀, ✅, ❌, 🔧, 🧪, 📊)
- Channel override support (e.g., SonarQube notifications to #sonarqube)
- Consistent notification format across all stages

### 4. **Better Error Handling**
- Timeout protection (20 minutes)
- Proper exception handling in deployment functions
- Automatic cleanup on failure

### 5. **Optimized Docker Builds**
- BuildKit support for faster builds
- Layer caching with `--cache-from`
- Parallel operations where possible

## Required Jenkins Credentials

### Environment Variables (Configure in Jenkins)

Replace `APP_NAME` with your actual application name:

```
APP_NAME_AWS_ACCOUNT_REGION          # e.g., us-east-1
APP_NAME_DEV_AWS_ACCOUNT_ID          # AWS Account ID
APP_NAME_DEV_DOCKER_IMAGE_NAME       # ECR image name
APP_NAME_DEV_DOCKER_IMAGE_TAG        # Image tag (e.g., latest, dev)
APP_NAME_DEV_SECRET_MANAGER          # AWS Secrets Manager secret name
APP_NAME_DEV_SERVER_IP               # EC2 server IP address
```

### AWS Credentials

Create Jenkins credential with ID: `APP_NAME_DEV`
- Type: AWS Credentials
- Access Key ID: Your AWS access key
- Secret Access Key: Your AWS secret key

### SSH Access

Ensure Jenkins has SSH access to EC2 instances:
- Add Jenkins public key to EC2 instance's `~/.ssh/authorized_keys`
- User: `ubuntu`

## Pipeline Stages

### 1. Setup Environment
- Loads environment-specific configuration
- Sets AWS credentials, region, image names, etc.
- Validates configuration exists for the branch

### 2. Update Configs Only (Optional)
- **Trigger**: When `UPDATE_CONFIG_ONLY` parameter is true
- Downloads secrets from AWS Secrets Manager
- Updates `.env` and `docker-compose.yml` on server
- Restarts containers without rebuilding

### 3. Code Quality Analysis (Pull Requests Only)
- **Trigger**: When pull request targets 'develop' branch
- **Sub-stages**:
  - **SonarQube Code Analysis**: Scans code for quality issues
  - **Check SonarQube Quality Gate**: Validates quality standards
- Runs SonarQube scanner on pull request code
- Excludes migrations, tests, and cache files
- Sends results to #sonarqube Slack channel
- Blocks merge if quality gate fails
- Cleans up artifacts after analysis

### 4. Unit Test and Code Coverage
- **Trigger**: When `UPDATE_CONFIG_ONLY` is false and branch is 'develop'
- Builds Docker image
- Runs Django tests with coverage
- Generates coverage XML report
- Cleans up test containers

### 5. SonarQube Analysis (Branch Builds)
- **Trigger**: When `UPDATE_CONFIG_ONLY` is false and branch is 'develop'
- Runs SonarQube scanner with coverage report
- Waits for quality gate result
- Sends results to #sonarqube Slack channel
- Fails pipeline if quality gate fails

### 6. Build and Push Docker Image
- **Trigger**: When `UPDATE_CONFIG_ONLY` is false and branch is 'develop'
- Builds optimized Docker image with BuildKit
- Uses layer caching for faster builds
- Tags and pushes to AWS ECR

### 7. Deploy to Server
- **Trigger**: Branch is 'develop'
- Downloads secrets from AWS Secrets Manager
- Copies docker-compose.yml and .env to server
- Pulls latest image from ECR
- Recreates containers with new image
- Runs database migrations
- Collects static files
- Cleans up old images

## Helper Functions

### `sendSlackNotification(color, message, includeUrl, channel)`
Sends formatted Slack notifications with optional channel override.

**Parameters:**
- `color`: Slack attachment color (#00FF00, #FF0000, etc.)
- `message`: Notification message
- `includeUrl`: Include build URL (default: false)
- `channel`: Override default channel (default: env.SLACK_CHANNEL)

**Examples:**
```groovy
sendSlackNotification('#00FF00', '✅ Deployment successful')
sendSlackNotification('#FF0000', '❌ Build failed', true)
sendSlackNotification('#0099ff', 'SonarQube analysis started', false, '#sonarqube')
```

### `configureEnvironmentAndDockerCompose(server, sourceComposeName)`
Downloads secrets and copies configuration files to server.

### `dockerPush(imageName)`
Authenticates with ECR and pushes Docker image.

### `runOnServer(server, command)`
Executes command on remote server via SSH.

### `updateDockerImageOnServers(server)`
Pulls latest Docker image from ECR on server.

### `restartContainers(server)`
Recreates containers with new configuration/image.

### `deployToServer(server, sourceComposeName)`
Complete deployment workflow with error handling.

## Usage Examples

### Pull Request to Develop Branch
```bash
# Create pull request targeting develop branch triggers:
1. Code Quality Analysis (SonarQube)
   - Scans code for quality issues
   - Checks quality gate
   - Blocks merge if quality gate fails

# This runs ONLY for pull requests, not direct pushes
```

### Normal Deployment (develop branch)
```bash
# Push to develop branch triggers:
1. Setup Environment
2. Unit Test and Code Coverage
3. SonarQube Analysis (with coverage)
4. Build and Push Docker Image
5. Deploy to Server
   - Migrate database
   - Collect static files
```

### Config-Only Update
```bash
# In Jenkins UI:
1. Click "Build with Parameters"
2. Check "UPDATE_CONFIG_ONLY"
3. Click "Build"

# This will:
- Download latest secrets
- Update .env and docker-compose.yml
- Restart containers
- Skip tests, build, and push
```

## Adding New Environments

To add a staging or production environment:

1. **Update Setup Environment stage:**
```groovy
def envConfig = [
    develop: [
        AWS_REGION: "${APP_NAME_AWS_ACCOUNT_REGION}",
        // ... existing config
    ],
    staging: [
        AWS_REGION: "${APP_NAME_AWS_ACCOUNT_REGION}",
        AWS_ACCOUNT_ID: "${APP_NAME_STAGING_AWS_ACCOUNT_ID}",
        DOCKER_IMAGE_NAME: "${APP_NAME_STAGING_DOCKER_IMAGE_NAME}",
        DOCKER_IMAGE_TAG: "${APP_NAME_STAGING_DOCKER_IMAGE_TAG}",
        AWS_SECRET_MANAGER: "${APP_NAME_STAGING_SECRET_MANAGER}",
        SERVER_IP: "${APP_NAME_STAGING_SERVER_IP}",
        AWS_CREDENTIALS: "APP_NAME_STAGING",
        CONFIG_FOLDER: "staging"
    ],
    main: [
        AWS_REGION: "${APP_NAME_AWS_ACCOUNT_REGION}",
        AWS_ACCOUNT_ID: "${APP_NAME_PROD_AWS_ACCOUNT_ID}",
        DOCKER_IMAGE_NAME: "${APP_NAME_PROD_DOCKER_IMAGE_NAME}",
        DOCKER_IMAGE_TAG: "${APP_NAME_PROD_DOCKER_IMAGE_TAG}",
        AWS_SECRET_MANAGER: "${APP_NAME_PROD_SECRET_MANAGER}",
        SERVER_IP: "${APP_NAME_PROD_SERVER_IP}",
        AWS_CREDENTIALS: "APP_NAME_PROD",
        CONFIG_FOLDER: "production"
    ]
][env.BRANCH_NAME]
```

2. **Update when conditions:**
```groovy
when {
    anyOf {
        branch 'develop'
        branch 'staging'
        branch 'main'
    }
}
```

3. **Create corresponding docker-compose files:**
```
.config/docker/docker-compose-staging.yml
.config/docker/docker-compose-production.yml
```

4. **Add Jenkins credentials and environment variables**

## Docker Compose File Naming Convention

The pipeline expects docker-compose files in `.config/docker/` with this naming:
```
docker-compose-{CONFIG_FOLDER}.yml
```

Examples:
- `docker-compose-develop.yml` → develop branch
- `docker-compose-staging.yml` → staging branch
- `docker-compose-production.yml` → main/production branch

## Troubleshooting

### Build Timeout
- Increase timeout in options: `timeout(time: 30, unit: 'MINUTES')`

### SSH Connection Issues
- Verify Jenkins can SSH to server: `ssh ubuntu@SERVER_IP`
- Check SSH key permissions
- Verify security group allows Jenkins IP

### ECR Authentication Issues
- Verify AWS credentials in Jenkins
- Check IAM permissions for ECR push/pull
- Ensure ECR repository exists

### SonarQube Quality Gate Failure
- Review SonarQube dashboard for issues
- Adjust quality gate settings if needed
- Fix code quality issues

### Secrets Manager Issues
- Verify secret exists in AWS Secrets Manager
- Check IAM permissions for secretsmanager:GetSecretValue
- Ensure secret is in correct region

## Code Quality Analysis for Pull Requests

The pipeline includes a dedicated **Code Quality Analysis** stage that runs automatically for pull requests targeting the `develop` branch.

### How It Works

1. **Automatic Trigger**: Runs when you create a pull request to `develop`
2. **Code Scanning**: SonarQube analyzes your code for:
   - Code smells
   - Bugs
   - Security vulnerabilities
   - Code duplication
   - Complexity issues
3. **Quality Gate Check**: Validates code meets quality standards
4. **Merge Blocking**: Pull request cannot be merged if quality gate fails

### SonarQube Configuration

The scanner is configured with:
```groovy
-Dsonar.projectKey=${env.APP_NAME}
-Dsonar.sources=.
-Dsonar.python.version=3.12
-Dsonar.exclusions=**/migrations/**,**/tests/**,**/test_*.py,**/__pycache__/**,**/venv/**,**/env/**
```

**Excluded from analysis:**
- Django migrations (`**/migrations/**`)
- Test files (`**/tests/**`, `**/test_*.py`)
- Python cache (`**/__pycache__/**`)
- Virtual environments (`**/venv/**`, `**/env/**`)

### Viewing Results

1. **Slack Notifications**: Sent to `#sonarqube` channel
2. **SonarQube Dashboard**: Link provided in failure notifications
3. **Jenkins Build Log**: Detailed scan output

### Fixing Quality Gate Failures

If your pull request fails the quality gate:

1. **Check the SonarQube dashboard** (link in Slack notification)
2. **Review identified issues**:
   - Critical bugs (must fix)
   - Security vulnerabilities (must fix)
   - Code smells (should fix)
   - Coverage gaps (improve tests)
3. **Fix the issues** in your branch
4. **Push changes** - Jenkins will re-run the analysis
5. **Verify quality gate passes** before requesting review

## Best Practices

1. **Run SonarQube locally** before creating pull requests
2. **Always test in develop first** before deploying to production
3. **Use config-only updates** for quick fixes that don't require code changes
4. **Monitor Slack notifications** for deployment status
5. **Review SonarQube reports** regularly to maintain code quality
6. **Keep secrets in AWS Secrets Manager**, never in code
7. **Use semantic versioning** for Docker image tags in production
8. **Backup database** before major deployments
9. **Fix quality gate issues immediately** - don't let technical debt accumulate

## Security Notes

- All secrets are stored in AWS Secrets Manager
- Secrets are cleaned up from workspace after build
- Docker images are scanned by ECR (if enabled)
- Containers run as non-root user (appuser)
- SSH connections use key-based authentication

