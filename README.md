# DevOps Challenge

Deploying Node App in kubernetes using CD/CI for IaC and deployments to EKS clusters
in AWS Cloud.

## Environments

- dev
- prod

## Folder Structure & Global Content
```
├── LICENSE
├── README.md
├── app
│   ├── config
│   │   ├── app.json
│   │   ├── db.json
│   │   └── localisation.json
├── infrastructure
│   ├── backend.tf
│   ├── data.tf
│   ├── dev
│   │   ├── backend
│   │   ├── data.tf -> ../data.tf
│   │   ├── main.tf -> ../main.tf
│   │   ├── outputs.tf -> ../outputs.tf
│   │   ├── providers.tf -> ../providers.tf
│   │   ├── vars.tf
│   │   └── vars.tfvars
│   ├── main.tf
│   ├── outputs.tf
│   ├── prod
│   │   ├── backend
│   │   ├── data.tf -> ../data.tf
│   │   ├── main.tf -> ../main.tf
│   │   ├── outputs.tf -> ../outputs.tf
│   │   ├── providers.tf -> ../providers.tf
│   │   ├── vars.tf
│   │   └── vars.tfvars
│   ├── providers.tf
├── k8s
│   └── dev
│   ├── deployment.yml
│   ├── service.yml
│   └── topsecrets.yaml
│   └── prod
│   ├── deployment.yml
│   ├── service.yml
│   └── topsecrets.yaml
```
Note: The main files are in the main path of each environment folder in order to use the same files to deploy the same way on each environment:
```
│   │   ├── data.tf -> ../data.tf
│   │   ├── main.tf -> ../main.tf
│   │   ├── outputs.tf -> ../outputs.tf
│   │   ├── providers.tf -> ../providers.tf
```
And those files must be change by environment:
```
│   │   ├── backend
│   │   ├── vars.tf
│   │   └── vars.tfvars
```
You need to configure the terraform backend using S3 bucket for the states:

Change the variables on backend file to use your bucket and your state location

```
bucket = "my-bucket-states"
region = "us-east-1"
key = "myapp-env"
```

## Resources to be Deployed

### Networking

- AWS VPC
- Security Groups for Worker Nodes, RDS and web traffic.
- AWS Private and Public Subnets (us-east-1b) (us-east-1b) (us-east-1c)
- AWS NAT Gateway
- AWS Route Table

### Compute

- AWS EKS
- AWS EKS Managed Node Groups
- AWS ECR registries
- AWS EKS Load Balancer controller
- AWS ALB Ingress

### Database

- AWS RDS Aurora MySql and Replica
- Secret in Secret Manager With DB credentials

### CI/CD Using Github Actions

We are having 2 CD/CI workflows; one to deploy infrastructure with terraform code, and another to build, test, and deploy the Node App to kubernetes on EKS.

```
.github
└── workflows
    ├── ci-timeoff-managment.yaml
    └── terraform-deploy.yaml
```

The Github Actions pipeline will be triggered On the following escenarios:

- When merge a commit on main branch will run the Build and Deploy steps.
- When create a PUll REQUEST will run only a BUILD or execute a terraform plan.

The following steps will be executed:

- Configure AWS Credentials from github secrets
- Configure AWS ECR credentials
- Build and Push to ECR the Docker image, I use as tag the sha commit.
- Configure EKS token credentials (set the name of the cluster in the workflow )
- Perform an Apply with kubectl over the k8s manifests

You can set the credentials in the credentilas step on the workflows in this block:

```
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_KEY }}
          aws-region: us-east-1
          role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
          role-external-id: ${{ secrets.AWS_ROLE_EXTERNAL_ID }}
          role-duration-seconds: 1200
          role-session-name: "ci-${{ github.actor }}"
```
For this you will need to create a ci/ci user in your AWS account and a new role that will be assume be the user created:

1. Create a IAM user (ci-githubactions)
2. Create a new Role: add the policies to deploy and create resources on AWS permissions (the more limited).

Set the secrets on Github Actions Secrets in the repository or across Organization:

Ref: https://github.com/Azure/actions-workflow-samples/blob/master/assets/create-secrets-for-GitHub-workflows.md

```
          secret = AWS_ACCESS_KEY = user ci-githubactions secret
          secret = AWS_SECRET_KEY =  user ci-githubactions secret
          secret = AWS_ROLE_TO_ASSUME =  role arn create in the previeous step
          secret = AWS_ROLE_EXTERNAL_ID = an External Id for the assume Role
```

### Folder Content

#### .github

The .github folder contains the Github Actions pipelines to build and deploy the timeoff-management application from the las realease 1.1.0

git clone --depth 1 --branch 1.1.1 https://github.com/timeoff-management/timeoff-management-application.git

#### Infrastructure

This folder contains the terraform code to the deploy the infrastructure for this Demo

To add more environments you can clone the folder from the previous folder created:

for example clone prod folder and rename it with your new environment prefix stg, qa, test and so on...

```
├── infrastructure
│   ├── backend.tf
│   ├── data.tf
│   ├── dev
│   │   ├── backend
│   │   ├── data.tf -> ../data.tf
│   │   ├── main.tf -> ../main.tf
│   │   ├── outputs.tf -> ../outputs.tf
│   │   ├── providers.tf -> ../providers.tf
│   │   ├── vars.tf
│   │   └── vars.tfvars
│   ├── main.tf
│   ├── outputs.tf
│   ├── prod
│   │   ├── backend
│   │   ├── data.tf -> ../data.tf
│   │   ├── main.tf -> ../main.tf
│   │   ├── outputs.tf -> ../outputs.tf
│   │   ├── providers.tf -> ../providers.tf
│   │   ├── vars.tf
│   │   └── vars.tfvars
│   ├── providers.tf
```
#### k8s

This folder contains the folder dev and prod to deploy to EKS the application

```
├── k8s
│   └── dev
│   ├── deployment.yml
│   ├── service.yml
│   └── topsecrets.yaml (kubectl create secret generic topsecrets --from-file=app/config)
│   └── prod
│   ├── deployment.yml
│   ├── service.yml
│   └── topsecrets.yaml (kubectl create secret generic topsecrets --from-file=app/config)
```

# Set Database Credentials

The data base config must be set at app/config/db.json, follow those steps to set your database credentials:

1. Reveal the value of the secret in AWS Secret Manager for the RDS created by terraform, search for "rdsCredentials"

2. Get the value and decode the string to see the json config

echo "my_secret_manager_string_value" | base64 -d

3. Put the config in your file app/config/db.json

```
kubectl create secret generic topsecrets --from-file=app/config

```

## Web App Url:
```
prod: https://prod-devops-challenge.gbanchs.com/
dev:  https://dev-devops-challenge.gbanchs.com/

```






## Web Application Architecture on AWS

![image](https://gbanchs.com/devops/devops-challengeV2.png)