# Quick fix: Push initial Docker image to ECR
# This allows ECS service to start, then the pipeline will update it

$REGION = "us-east-1"
$ACCOUNT_ID = "434600758347"
$REPO_NAME = "wild-rydes"
$ECR_URI = "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME"

Write-Host "Step 1: Logging into ECR..." -ForegroundColor Cyan
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

Write-Host "`nStep 2: Building Docker image..." -ForegroundColor Cyan
docker build -t $REPO_NAME:latest .

Write-Host "`nStep 3: Tagging image for ECR..." -ForegroundColor Cyan
docker tag "$REPO_NAME:latest" "$ECR_URI:latest"

Write-Host "`nStep 4: Pushing image to ECR..." -ForegroundColor Cyan
docker push "$ECR_URI:latest"

Write-Host "`nDone! Image pushed successfully." -ForegroundColor Green
Write-Host "ECS service should start deploying tasks now." -ForegroundColor Green
Write-Host "`nWait 2-3 minutes, then check ECS service status:" -ForegroundColor Yellow
Write-Host "aws ecs describe-services --cluster WildRydes-Cluster --services wild-rydes-service --query 'services[0].runningCount'" -ForegroundColor Gray
