# Monitor CloudFormation Stack Creation

# Check stack status
aws cloudformation describe-stacks `
  --stack-name wild-rydes-infrastructure `
  --query 'Stacks[0].StackStatus' `
  --output text

# Watch stack events (live updates)
aws cloudformation describe-stack-events `
  --stack-name wild-rydes-infrastructure `
  --max-items 20 `
  --query 'StackEvents[*].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId]' `
  --output table

# Wait for stack creation to complete (this will block until done)
# aws cloudformation wait stack-create-complete --stack-name wild-rydes-infrastructure

# Once complete, get the outputs
# aws cloudformation describe-stacks `
#   --stack-name wild-rydes-infrastructure `
#   --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' `
#   --output table
