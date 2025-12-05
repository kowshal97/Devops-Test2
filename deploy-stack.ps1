# Wild Rydes Infrastructure Deployment Script
# Run this after the old stack is fully deleted

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken
)

$StackName = "wild-rydes-infrastructure"
$Region = "us-east-1"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Wild Rydes Infrastructure Deployment" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if old stack is deleted
Write-Host "Step 1: Checking if old stack exists..." -ForegroundColor Yellow
$stackExists = aws cloudformation describe-stacks --stack-name $StackName 2>&1
if ($stackExists -notlike "*does not exist*" -and $stackExists -notlike "*ValidationError*") {
    Write-Host "ERROR: Stack still exists. Please wait for deletion to complete." -ForegroundColor Red
    Write-Host "Run: aws cloudformation describe-stacks --stack-name $StackName --query 'Stacks[0].StackStatus'" -ForegroundColor Gray
    exit 1
}
Write-Host "  Old stack deleted. Proceeding..." -ForegroundColor Green

# Step 2: Build and push Docker image
Write-Host ""
Write-Host "Step 2: Building and pushing Docker image..." -ForegroundColor Yellow
$AccountId = (aws sts get-caller-identity --query 'Account' --output text)
$EcrUri = "$AccountId.dkr.ecr.$Region.amazonaws.com/wild-rydes"

# Login to ECR
aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin "$AccountId.dkr.ecr.$Region.amazonaws.com"

# Note: ECR repo will be created by CloudFormation, so we skip pushing for now
Write-Host "  Docker login successful. Image will be built by CodePipeline." -ForegroundColor Green

# Step 3: Create CloudFormation stack
Write-Host ""
Write-Host "Step 3: Creating CloudFormation stack..." -ForegroundColor Yellow
aws cloudformation create-stack `
    --stack-name $StackName `
    --template-body file://wild-rydes-infrastructure.yaml `
    --parameters `
        ParameterKey=GitHubToken,ParameterValue=$GitHubToken `
        ParameterKey=ContainerPort,ParameterValue=3000 `
    --capabilities CAPABILITY_IAM `
    --region $Region

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to create stack" -ForegroundColor Red
    exit 1
}

Write-Host "  Stack creation initiated!" -ForegroundColor Green

# Step 4: Wait for stack creation
Write-Host ""
Write-Host "Step 4: Waiting for stack creation (this takes 15-20 minutes)..." -ForegroundColor Yellow
Write-Host "  You can also monitor in AWS Console: CloudFormation > Stacks" -ForegroundColor Gray
Write-Host ""

$startTime = Get-Date
do {
    Start-Sleep -Seconds 30
    $status = aws cloudformation describe-stacks --stack-name $StackName --query 'Stacks[0].StackStatus' --output text 2>&1
    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
    Write-Host "  [$elapsed min] Status: $status" -ForegroundColor Gray
} while ($status -eq "CREATE_IN_PROGRESS")

if ($status -eq "CREATE_COMPLETE") {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  Stack Created Successfully!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    
    # Get outputs
    Write-Host ""
    Write-Host "Stack Outputs:" -ForegroundColor Cyan
    aws cloudformation describe-stacks --stack-name $StackName --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' --output table
    
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Wait 5-10 minutes for the CodePipeline to complete first run" -ForegroundColor White
    Write-Host "2. Check pipeline: aws codepipeline get-pipeline-state --name WildRydes-Pipeline" -ForegroundColor Gray
    Write-Host "3. Once pipeline completes, access your app at the LoadBalancerURL above" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "Stack creation failed with status: $status" -ForegroundColor Red
    Write-Host "Check events: aws cloudformation describe-stack-events --stack-name $StackName" -ForegroundColor Gray
    exit 1
}
