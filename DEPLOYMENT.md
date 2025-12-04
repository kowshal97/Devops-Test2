# Wild Rydes - Complete Deployment Guide

## 🎯 Project Overview
This repository contains the complete Infrastructure as Code (IaC) solution for Wild Rydes, converting a monolithic containerized application to AWS ECS Fargate with a fully automated CI/CD pipeline.

## 📁 Repository Structure
```
Devops-Test2/
├── app/
│   ├── server.js              # Node.js Express application
│   ├── package.json           # NPM dependencies
│   └── public/
│       └── index.html         # Frontend UI
├── Dockerfile                 # Container image definition
├── buildspec.yml              # CodeBuild build specification
├── wild-rydes-infrastructure.yaml  # CloudFormation template
├── .dockerignore              # Docker ignore rules
├── .gitignore                 # Git ignore rules
└── DEPLOYMENT.md              # This file
```

## 🏗️ Architecture

### Infrastructure Components:
- **VPC**: Custom VPC with public and private subnets across 2 AZs
- **Application Load Balancer**: Distributes traffic across ECS tasks
- **ECS Fargate**: Runs containerized application (serverless)
- **ECR**: Private Docker registry
- **CI/CD Pipeline**: GitHub → CodeBuild → ECR → ECS
- **CloudWatch**: Monitoring and alarms

### CI/CD Pipeline Flow:
1. Push code to GitHub
2. CodePipeline triggers automatically
3. CodeBuild pulls source, builds Docker image
4. Image pushed to ECR with tagging
5. ECS service updated with new image
6. CloudWatch alarms monitor each stage

## 📋 Prerequisites

### 1. AWS Account Setup
- Active AWS account with admin access
- AWS CLI installed and configured
```powershell
aws configure
```

### 2. GitHub Setup
- GitHub account (yours: `kowshal97`)
- Repository created: `Devops-Test2`
- Personal Access Token with `repo` permissions
  - Go to: Settings → Developer settings → Personal access tokens → Tokens (classic)
  - Generate new token with `repo` scope
  - Save the token securely

### 3. Local Tools
- Git installed
- Docker installed (for local testing)
- Text editor (VS Code recommended)

## 🚀 Step-by-Step Deployment

### Step 1: Push Code to GitHub

```powershell
# Navigate to project directory
cd C:\Users\kowsh\Desktop\Test2

# Initialize git repository
git init

# Add all files
git add .

# Commit files
git commit -m "Initial commit: Wild Rydes application with CloudFormation IaC"

# Add remote repository
git remote add origin https://github.com/kowshal97/Devops-Test2.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### Step 2: Deploy CloudFormation Stack

#### Option A: Using AWS Console

1. **Login to AWS Console**
   - Navigate to CloudFormation service
   - Select your preferred region (e.g., `us-east-1`)

2. **Create Stack**
   - Click "Create stack" → "With new resources (standard)"
   - Choose "Upload a template file"
   - Upload `wild-rydes-infrastructure.yaml`
   - Click "Next"

3. **Specify Stack Details**
   - **Stack name**: `wild-rydes-infrastructure`
   - **Parameters**:
     - `GitHubOwner`: `kowshal97`
     - `GitHubRepo`: `Devops-Test2`
     - `GitHubBranch`: `main`
     - `GitHubToken`: `<your-github-token>`
     - `ContainerPort`: `80`
     - `DesiredCount`: `2`
   - Click "Next"

4. **Configure Stack Options**
   - Add tags if needed (optional)
   - Click "Next"

5. **Review and Create**
   - Check "I acknowledge that AWS CloudFormation might create IAM resources"
   - Click "Submit"

6. **Wait for Completion**
   - Stack creation takes ~15-20 minutes
   - Monitor the "Events" tab for progress
   - Wait for status: `CREATE_COMPLETE`

#### Option B: Using AWS CLI

```powershell
# Set your GitHub token
$GITHUB_TOKEN = "your_github_personal_access_token_here"

# Create the stack
aws cloudformation create-stack `
  --stack-name wild-rydes-infrastructure `
  --template-body file://wild-rydes-infrastructure.yaml `
  --parameters `
    ParameterKey=GitHubOwner,ParameterValue=kowshal97 `
    ParameterKey=GitHubRepo,ParameterValue=Devops-Test2 `
    ParameterKey=GitHubBranch,ParameterValue=main `
    ParameterKey=GitHubToken,ParameterValue=$GITHUB_TOKEN `
    ParameterKey=ContainerPort,ParameterValue=80 `
    ParameterKey=DesiredCount,ParameterValue=2 `
  --capabilities CAPABILITY_IAM `
  --region us-east-1

# Monitor stack creation
aws cloudformation wait stack-create-complete `
  --stack-name wild-rydes-infrastructure `
  --region us-east-1

# Get stack outputs
aws cloudformation describe-stacks `
  --stack-name wild-rydes-infrastructure `
  --query 'Stacks[0].Outputs' `
  --region us-east-1
```

### Step 3: Verify Deployment

#### Check Stack Outputs
```powershell
# Get Load Balancer URL
aws cloudformation describe-stacks `
  --stack-name wild-rydes-infrastructure `
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' `
  --output text
```

#### Access the Application
1. Copy the Load Balancer URL from outputs
2. Open in web browser
3. You should see the Wild Rydes homepage

#### Verify Pipeline
```powershell
# Check pipeline status
aws codepipeline get-pipeline-state --name WildRydes-Pipeline

# List pipeline executions
aws codepipeline list-pipeline-executions --pipeline-name WildRydes-Pipeline
```

#### Check ECS Service
```powershell
# Describe ECS service
aws ecs describe-services `
  --cluster WildRydes-Cluster `
  --services wild-rydes-service

# List running tasks
aws ecs list-tasks --cluster WildRydes-Cluster --service-name wild-rydes-service
```

## 🔄 Testing the CI/CD Pipeline

### Make a Code Change
```powershell
# Edit the app/public/index.html file (change something visible)
# For example, change the tagline

# Commit and push
git add .
git commit -m "Update homepage tagline"
git push origin main
```

### Monitor Pipeline Execution
1. Go to AWS Console → CodePipeline
2. Click on `WildRydes-Pipeline`
3. Watch the three stages execute:
   - **Source**: Pulls from GitHub
   - **Build**: Builds and pushes Docker image
   - **Deploy**: Updates ECS service

### Verify Update
- Wait for pipeline to complete (~5-10 minutes)
- Refresh the Load Balancer URL in your browser
- Verify your changes are live

## 📊 Monitoring & Troubleshooting

### View CloudWatch Alarms
```powershell
# List all alarms
aws cloudwatch describe-alarms --alarm-name-prefix WildRydes

# Get alarm history
aws cloudwatch describe-alarm-history --alarm-name WildRydes-Pipeline-Failed
```

### View Build Logs
```powershell
# Get recent builds
aws codebuild list-builds-for-project --project-name WildRydes-Build

# View build logs in CloudWatch
# Navigate to CloudWatch → Log groups → /aws/codebuild/WildRydes-Build
```

### View Application Logs
```powershell
# Navigate to CloudWatch → Log groups → /ecs/wild-rydes
# Or use CLI:
aws logs tail /ecs/wild-rydes --follow
```

### Common Issues

#### Pipeline Fails at Source Stage
- **Issue**: GitHub token invalid or expired
- **Solution**: Generate new token and update stack parameters

#### Build Fails
- **Issue**: Dockerfile errors or buildspec.yml issues
- **Solution**: Check CodeBuild logs in CloudWatch

#### Deployment Fails
- **Issue**: Health checks failing
- **Solution**: Check ECS task logs and ensure app runs on port 80

#### Can't Access Application
- **Issue**: Security groups or target group misconfigured
- **Solution**: Verify ALB security group allows inbound HTTP (port 80)

## 💰 Cost Estimation

Monthly costs (approximate):
- **NAT Gateways**: $32/month each × 2 = $64/month
- **Application Load Balancer**: ~$20/month
- **ECS Fargate**: ~$30/month (2 tasks, 0.25 vCPU, 0.5 GB each)
- **ECR Storage**: ~$1/month (10 images)
- **Data Transfer**: Variable
- **CodeBuild**: Free tier (100 minutes/month)

**Total**: ~$115-125/month

### Cost Optimization Tips
- Use 1 NAT Gateway instead of 2 (reduces HA)
- Reduce ECS task count to 1
- Enable ECR lifecycle policies (already configured)
- Use AWS Cost Explorer to monitor actual costs

## 🧹 Cleanup

### Delete All Resources
```powershell
# Empty S3 bucket first
$BUCKET_NAME = (aws cloudformation describe-stack-resources `
  --stack-name wild-rydes-infrastructure `
  --query 'StackResources[?ResourceType==`AWS::S3::Bucket`].PhysicalResourceId' `
  --output text)

aws s3 rm s3://$BUCKET_NAME --recursive

# Delete ECR images
$REPO_NAME = "wild-rydes"
aws ecr batch-delete-image `
  --repository-name $REPO_NAME `
  --image-ids imageTag=latest

# Delete CloudFormation stack
aws cloudformation delete-stack --stack-name wild-rydes-infrastructure

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete --stack-name wild-rydes-infrastructure
```

## 🧪 Local Testing

### Test Application Locally
```powershell
# Install dependencies
cd app
npm install

# Run application
npm start

# Open browser to http://localhost:80
```

### Test Docker Build Locally
```powershell
# Build image
docker build -t wild-rydes:local .

# Run container
docker run -p 80:80 wild-rydes:local

# Test in browser: http://localhost:80
```

## 📝 Test Completion Checklist

✅ Complete CloudFormation template created  
✅ VPC with public/private subnets across 2 AZs  
✅ Application Load Balancer configured  
✅ ECS Fargate cluster and service deployed  
✅ ECR repository with lifecycle policies  
✅ CI/CD pipeline (GitHub → CodeBuild → ECS)  
✅ CloudWatch alarms for monitoring  
✅ Sample application with Dockerfile  
✅ Comprehensive documentation  

## 📞 Support & Resources

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)

## 🎓 What You've Built

This solution demonstrates:
- **Infrastructure as Code**: Entire infrastructure defined in CloudFormation
- **Containerization**: Application packaged in Docker
- **CI/CD**: Automated pipeline from code to production
- **High Availability**: Multi-AZ deployment with load balancing
- **Monitoring**: CloudWatch alarms for proactive issue detection
- **Security**: Private subnets, IAM roles, security groups
- **Scalability**: Auto-scaling ECS service

**Congratulations!** You've successfully implemented a production-ready DevOps solution! 🎉
