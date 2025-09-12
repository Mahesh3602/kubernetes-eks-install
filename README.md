# configure AWS account
aws configure

# original git repo 
https://github.com/pluralsight-cloud/hands-on-with-amazon-eks

# First script installtion 
   ## creates cluster:eks-acg, nodegroup:eks-node-group & VPC
   ## t3.medium nodes are created
./scripts-by-chapter/chapter-1.sh

# Second script installtion
./scripts-by-chapter/chapter-2.sh
  ## Getting NodeGroup IAM Role from Kubernetes Cluster
  ## Installing Load Balancer Controller
  ## Create SSL Certfiicate in ACM
  ## Create the DynamoDB Tables
  ## Adding DynamoDB Permissions to the node
  ## Installing the sample applications
  ## Create the VPC CNI Addon

# Third script installation
./scripts-by-chapter/chapter-3.sh
  ## Create OIDC Provider and connect it with EKS
  ## Create IAM Policies for each of Bookstore Microservices
  ## Getting NodeGroup IAM Role from Kubernetes Cluster
  ## Removing DynamoDB Permissions to the node if exists
  ## Create IAM Service Accounts
  ## Upgrading the applications, Basically installing helm2
  ## Updating IRSA for AWS Load Balancer Controller
  ## Updating IRSA for External DNS
  ## Updating IRSA for VPC CNI

# Fourth script installation
./scripts-by-chapter/chapter-4.sh
  ## Create Spot Instances nodegroup
  ## Delete previous nodegroup
  ## Termination Handler- To cordon/uncordon node for moving pods before termination

# Fifth script installation
./scripts-by-chapter/chapter-5.sh
  ## export AWS_ACCOUNT_ID
  ## Create the CodeCommit Repository for each app
  ## Get the CodeCommit credentials for the "cloud_user" IAM user
  ## Get the Repositories' URLs
  ## Init Git config - for 1 app check test.sh
  ## Initial Push to the Git Repositories
  ## Install ECR and CodeBuild jobs
  ## Install Automatic Building job
  ## Add the IAM Role to the aws-auth Config Map
  ## Automatic Deployment to Development Environment
  ## Updating Development
  
  ##  Create the Production DynamoDB Tables
  ## Create IAM Policies of Bookstore Microservices
  ## Create IAM Service Accounts
  ## Installing the Production applications
  ## Automatic Deployment to Production Environment
