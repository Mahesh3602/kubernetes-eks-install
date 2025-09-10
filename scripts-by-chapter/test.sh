./scripts-by-chapter/chapter-1.sh
./scripts-by-chapter/chapter-2.sh
./scripts-by-chapter/chapter-3.sh

echo "***************************************************"
echo "********* CHAPTER 5 - STARTED AT $(date) **********"
echo "***************************************************"
echo "--- This could take around 20 minutes"

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text | xargs)

# Create the CodeCommit Repository for each app
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name renting-api-codecommit-repo \
            --template-file cicd-1-codecommit.yaml \
            --parameter-overrides \
                AppName=renting-api ) & 
    
    wait

# Get the CodeCommit credentials for the "cloud_user" IAM user
    codecommit_creds=$(aws iam create-service-specific-credential --user-name cloud_user --service-name codecommit.amazonaws.com)
    codecommit_username=`echo $codecommit_creds | jq -r ".ServiceSpecificCredential.ServiceUserName" | xargs`
    codecommit_password=`echo $codecommit_creds | jq -r ".ServiceSpecificCredential.ServicePassword" | xargs`

# Get the Repositories URLs
    renting_api_repo_url=$(aws cloudformation describe-stacks --stack renting-api-codecommit-repo --query "Stacks[*].Outputs[?OutputKey=='CloneUrlHttp'].OutputValue" --output text | xargs)
    
# Init Git config
    git config --global credential.helper '!aws codecommit credential-helper $@'
    git config --global init.defaultBranch master
    git config --global user.email "cloud-user@eks-acg.com"
    git config --global user.name "cloud_user"

    

    base_codecommit_url=$(echo $renting_api_repo_url | grep -Eo '^https?://[^/]+' | xargs)
    codecommit_username_encoded=$(echo -n ${codecommit_username} | jq -sRr @uri)
    codecommit_password_encoded=$(echo -n ${codecommit_password} | jq -sRr @uri)

    echo ${base_codecommit_url/"https://"/"https://${codecommit_username_encoded}:${codecommit_password_encoded}@"} >> ~/.git-credentials
    

# Initial Push to the Git Repositories
    ( cd ./renting-api && \
        git init && \
        git remote add origin ${renting_api_repo_url} && \
        git add . && \
        git commit -m "Initial Commit" && \
        git push origin master )
    

# Install ECR and CodeBuild jobs

    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name renting-api-codecommit-repo \
            --template-file cicd-2-ecr-and-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=renting-api ) & 
    
    wait
        
# # Automatic Building

    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name renting-api-codecommit-repo \
            --template-file cicd-3-automatic-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=renting-api ) & 
    
    wait

# Add the IAM Role to the aws-auth Config Map
    renting_api_codebuild_iam_role_name=$(aws cloudformation describe-stack-resources --stack renting-api-codecommit-repo --query "StackResources[?LogicalResourceId=='IamServiceRole'].PhysicalResourceId" --output text | xargs)
    
    renting_api_codebuild_iam_role_arn="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${renting_api_codebuild_iam_role_name}"
    
    kubectl get cm -n kube-system aws-auth -o yaml

    eksctl create iamidentitymapping --cluster eks-acg --arn ${renting_api_codebuild_iam_role_arn} --username renting-api-deployment --group system:masters
    
    kubectl get cm -n kube-system aws-auth -o yaml

# Automatic Deployment to Development Environment

    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name renting-api-codecommit-repo \
            --template-file cicd-4-deploy-development.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=renting-api )  &

    wait

# Updating Development
    ( cd ./clients-api && \
        sed -i 's/helm-v4/helm-v5/' infra/codebuild/deployment/buildspec.yml && \
        git add . && \
        git commit -m "From Helm V4 to Helm V5" && \
        git push origin master
    ) &

    wait


#  Create the Production DynamoDB Tables
    ( cd ./renting-api/infra/cloudformation && ./create-dynamodb-table.sh production ) & 
   
    wait


# Create IAM Policies of Bookstore Microservices
    ( cd renting-api/infra/cloudformation && ./create-iam-policy.sh production ) &

    wait

# Create IAM Service Accounts
    renting_iam_policy=$(aws cloudformation describe-stacks --stack production-iam-policy-renting-api --query "Stacks[0].Outputs[0]" | jq .OutputValue | tr -d '"')
    
    
    eksctl create iamserviceaccount --name renting-api-iam-service-account \
        --namespace production \
        --cluster eks-acg \
        --attach-policy-arn ${renting_iam_policy} --approve
    
# Installing the Production applications

    sleep 300 # wait until everything has images. More or less, 5 minutes

    renting_api_image_tag=$(aws ecr list-images --repository-name bookstore.renting-api --query "imageIds[0].imageTag" --output text | xargs)
    
    ( cd ./renting-api/infra/helm-v5 && ./create.sh production ${renting_api_image_tag} ) & 

    wait

# Automatic Deployment to Production Environment

    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name renting-api-codecommit-repo \
            --template-file cicd-5-deploy-prod.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=renting-api )&

    wait


echo "*************************************************************"
echo "********* READY FOR CHAPTER 6 - FINISHED AT $(date) *********"
echo "*************************************************************"