# Wild Rydes Infrastructure - CloudFormation Template

## Overview
This CloudFormation template deploys a complete AWS infrastructure for the Wild Rydes application, converting their monolithic containerized application from ECS to a fully Infrastructure as Code (IaC) solution.

## Architecture Components

### 1. **Networking Layer**
- **VPC**: 10.0.0.0/16 CIDR block with DNS support
- **Public Subnets**: 2 subnets across different AZs for the Application Load Balancer
- **Private Subnets**: 2 subnets across different AZs for ECS Fargate tasks
- **NAT Gateways**: 2 NAT gateways for high availability (one per AZ)
- **Internet Gateway**: For public internet access

### 2. **Load Balancing**
- **Application Load Balancer**: 
  - Deployed across 2 public subnets for high availability
  - HTTP listener on port 80
  - Target group with health checks configured
  - Security group allowing inbound HTTP/HTTPS traffic

### 3. **Container Infrastructure**
- **ECS Cluster**: Fargate-based cluster with Container Insights enabled
- **ECR Repository**: Private Docker image repository with:
  - Automatic image scanning on push
  - Lifecycle policy to retain only last 10 images
- **ECS Service**: 
  - Runs on Fargate (serverless)
  - Load balanced across 2 availability zones
  - Auto-scaling capability (2 tasks by default)
  - Private subnet deployment with ALB integration

### 4. **CI/CD Pipeline**
- **Source Stage**: GitHub integration for source code management
- **Build Stage**: AWS CodeBuild
  - Pulls source from GitHub
  - Builds Docker image
  - Pushes image to ECR with tagging
  - Generates imagedefinitions.json for deployment
- **Deploy Stage**: Automated ECS deployment
  - Updates ECS service with new Docker image
  - Performs rolling updates

### 5. **Monitoring & Alarms**
CloudWatch alarms configured for:
- **Pipeline Failures**: Alerts when CI/CD pipeline fails
- **Build Failures**: Alerts when CodeBuild job fails
- **Deployment Failures**: Alerts when ECS deployment fails
- **High CPU Usage**: Alerts when ECS tasks exceed 80% CPU
- **High Memory Usage**: Alerts when ECS tasks exceed 80% memory
- **Unhealthy Targets**: Alerts when ALB targets fail health checks

## Prerequisites

Before deploying this stack, ensure you have:

1. **AWS Account** with appropriate permissions
2. **GitHub Repository** containing your application code with a Dockerfile
3. **GitHub Personal Access Token** with repo access
4. **AWS CLI** configured with credentials

## Parameters

The template accepts the following parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `GitHubRepo` | GitHub repository name | wild-rydes-app |
| `GitHubOwner` | GitHub account/organization name | your-github-username |
| `GitHubBranch` | Branch to deploy from | main |
| `GitHubToken` | GitHub personal access token | (required) |
| `ContainerPort` | Port your application listens on | 80 |
| `DesiredCount` | Number of ECS tasks to run | 2 |

## Deployment Instructions

### Method 1: AWS Console

1. Navigate to CloudFormation in the AWS Console
2. Click "Create Stack" → "With new resources"
3. Upload the `wild-rydes-infrastructure.yaml` file
4. Fill in the required parameters:
   - GitHubOwner: Your GitHub username
   - GitHubRepo: Your repository name
   - GitHubToken: Your GitHub personal access token
   - Other parameters as needed
5. Review and create the stack

### Method 2: AWS CLI

```powershell
aws cloudformation create-stack `
  --stack-name wild-rydes-infrastructure `
  --template-body file://wild-rydes-infrastructure.yaml `
  --parameters `
    ParameterKey=GitHubOwner,ParameterValue=your-username `
    ParameterKey=GitHubRepo,ParameterValue=your-repo `
    ParameterKey=GitHubToken,ParameterValue=your-token `
    ParameterKey=GitHubBranch,ParameterValue=main `
  --capabilities CAPABILITY_IAM
```

## Stack Outputs

After deployment, the stack provides the following outputs:

- **LoadBalancerURL**: Public URL to access your application
- **ECRRepositoryURI**: Docker image repository URI
- **ECSClusterName**: Name of the ECS cluster
- **PipelineName**: Name of the CodePipeline
- **VPCId**: ID of the created VPC

## Application Requirements

Your GitHub repository should contain:

1. **Dockerfile**: Instructions to build your application container
2. **Application Code**: Your Wild Rydes application
3. **(Optional) buildspec.yml**: Custom CodeBuild configuration (template includes inline buildspec)

### Example Dockerfile Structure
```dockerfile
FROM node:14
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 80
CMD ["npm", "start"]
```

## How the CI/CD Pipeline Works

1. **Code Push**: Developer pushes code to GitHub repository
2. **Source Stage**: CodePipeline detects the change and pulls source code
3. **Build Stage**: 
   - CodeBuild executes the build
   - Logs into ECR
   - Builds Docker image
   - Tags and pushes image to ECR
   - Creates imagedefinitions.json
4. **Deploy Stage**:
   - ECS receives the new image definition
   - Performs rolling update of tasks
   - New containers are deployed
   - Old containers are drained and terminated
5. **Monitoring**: CloudWatch alarms monitor each stage for failures

## Monitoring & Troubleshooting

### View Pipeline Status
```powershell
aws codepipeline get-pipeline-state --name WildRydes-Pipeline
```

### View Build Logs
```powershell
aws codebuild batch-get-builds --ids <build-id>
```

### View ECS Service Status
```powershell
aws ecs describe-services --cluster WildRydes-Cluster --services wild-rydes-service
```

### Check CloudWatch Alarms
```powershell
aws cloudwatch describe-alarms --alarm-name-prefix WildRydes
```

## Cost Considerations

This infrastructure includes:
- 2 NAT Gateways (~$64/month)
- Application Load Balancer (~$20/month)
- ECS Fargate tasks (based on CPU/memory and runtime)
- Data transfer costs
- ECR storage
- CodeBuild minutes (first 100 minutes free per month)

## Security Features

- Private subnets for ECS tasks
- Security groups with least privilege access
- IAM roles with minimal required permissions
- ECR image scanning enabled
- VPC isolation

## Cleanup

To delete all resources:

```powershell
aws cloudformation delete-stack --stack-name wild-rydes-infrastructure
```

**Note**: Empty the S3 artifacts bucket and ECR repository before deleting the stack.

## Support & Additional Information

This template fulfills the requirements for Test #2: Implementing DevOps Solutions by providing:
✅ Complete ECS Fargate infrastructure
✅ Application Load Balancer with two subnets
✅ CI/CD pipeline (GitHub → CodeBuild → ECS)
✅ CloudWatch alarms at each pipeline stage
✅ Infrastructure as Code using AWS CloudFormation
