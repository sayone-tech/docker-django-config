# GitHub Actions Setup Guide

This guide explains how to set up the GitHub Actions workflow for deploying your Django application to AWS.

## Overview

The workflow consists of 5 jobs that run sequentially:

1. **Unit Test and Coverage** - Runs Django tests and generates coverage reports
2. **SonarQube Analysis** - Performs code quality analysis using sonar-scanner
3. **Push to ECR** - Builds and pushes Docker image to AWS ECR
4. **Update Server Configs** - Copies configuration files to EC2 server
5. **Deploy to Server** - Deploys the application with migrations and static files

## Required GitHub Secrets

You need to configure the following secrets in your GitHub repository:

### AWS Credentials
- `AWS_ACCESS_KEY_ID` - Your AWS access key
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret key
- `AWS_REGION` - AWS region (e.g., us-east-1)
- `AWS_ACCOUNT_ID` - Your AWS account ID

### Application Configuration
- `APP_NAME` - Your application name (used for container naming)
- `DOCKER_IMAGE_NAME` - Docker image name for ECR
- `DOCKER_IMAGE_TAG` - Docker image tag (e.g., latest, v1.0.0)
- `SERVER_NAME` - EC2 instance public IP or domain name
- `AWS_SECRET_MANAGER` - AWS Secrets Manager secret ID for environment variables

### SonarQube Configuration
- `SONAR_TOKEN` - SonarQube authentication token
- `SONAR_PROJECT_KEY` - SonarQube project key
- `SONAR_HOST_URL` - SonarQube server URL

### SSH Access
- `EC2_SSH_KEY` - Private SSH key for EC2 instance access

## Setting up GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret listed above

## Workflow Triggers

The workflow is triggered on:
- Push to the `develop` branch

## Job Dependencies

Jobs run in the following order:
```
unit-test-and-coverage → sonarqube-analysis → push-to-ecr → update-server-configs → deploy-to-server
```

## Key Features

### Container Naming
- The workflow uses `${APP_NAME}-unit-test` for the test container (matching Jenkins pipeline)
- Environment variables are properly secured using `${{ secrets.* }}` syntax

### SonarQube Integration
- Uses sonar-scanner CLI (same as Jenkins)
- Downloads and configures sonar-scanner automatically
- Waits for quality gate results

### File Management
- Environment file is created once in the first job and shared as an artifact
- Eliminates duplicate AWS Secrets Manager calls
- Uses `appleboy/scp-action` for consistent SSH key handling

### Security
- All sensitive data uses GitHub secrets
- SSH keys handled consistently across jobs
- No hardcoded credentials

## Prerequisites

### AWS Setup
1. Create an ECR repository for your Docker images
2. Create an EC2 instance with Docker and Docker Compose installed
3. Set up AWS Secrets Manager with your environment variables
4. Configure IAM roles and permissions

### SonarQube Setup
1. Set up a SonarQube server
2. Create a project in SonarQube
3. Generate an authentication token

### EC2 Instance Setup
1. Install Docker and Docker Compose
2. Create the application directory: `/home/ubuntu/{APP_NAME}/`
3. Configure SSH access with the provided key

## Environment Variables

The workflow uses the following environment variables:
- `APP_NAME` - Application name (from secrets)
- `AWS_REGION` - AWS region (from secrets)
- `DOCKER_IMAGE_NAME` - Docker image name (from secrets)
- `DOCKER_IMAGE_TAG` - Docker image tag (from secrets)
- `AWS_ACCOUNT_ID` - AWS account ID (from secrets)
- `SERVER_NAME` - EC2 server hostname/IP (from secrets)
- `AWS_SECRET_MANAGER` - Secrets Manager secret ID (from secrets)

## Troubleshooting

### Common Issues

1. **Container Name Mismatch**
   - Verify `APP_NAME` secret matches your docker-compose configuration
   - Check that the container name `${APP_NAME}-unit-test` exists

2. **AWS Credentials Error**
   - Verify AWS access keys are correct
   - Check IAM permissions for ECR and Secrets Manager

3. **SSH Connection Failed**
   - Verify EC2_SSH_KEY secret is correct
   - Check security group allows SSH access
   - Ensure the key is in the correct format

4. **SonarQube Analysis Failed**
   - Verify SONAR_TOKEN is valid
   - Check SONAR_HOST_URL is accessible
   - Ensure SONAR_PROJECT_KEY exists

5. **Docker Build Failed**
   - Check Dockerfile syntax
   - Verify all required files are present
   - Check requirements.txt for valid packages

### Debugging

To debug workflow issues:
1. Check the Actions tab in GitHub for detailed logs
2. Verify all secrets are properly configured
3. Test individual steps locally if possible
4. Check AWS CloudWatch logs for ECR and Secrets Manager access

## Security Considerations

1. **Secrets Management**
   - Never commit secrets to the repository
   - Use GitHub secrets for all sensitive data
   - Rotate AWS access keys regularly

2. **Network Security**
   - Use VPC and security groups to restrict access
   - Consider using AWS Systems Manager for server access
   - Implement proper firewall rules

3. **Container Security**
   - Use minimal base images
   - Scan images for vulnerabilities
   - Keep dependencies updated

## Customization

You can customize the workflow by:
1. Modifying environment variables
2. Adding additional testing stages
3. Changing deployment strategies
4. Adding notification steps (Slack, email, etc.)
5. Implementing blue-green deployments

## Support

For issues or questions:
1. Check the GitHub Actions documentation
2. Review AWS service documentation
3. Consult SonarQube documentation
4. Check Docker and Docker Compose documentation 