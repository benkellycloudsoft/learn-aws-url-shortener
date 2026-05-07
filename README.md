# Task 1: URL Shortener

[A url shortener exercise (be aware there are simpler ways to do this in AWS!)](https://cloudsoftcorp.slack.com/archives/C09KCQRNJRG/p1759927803030539):
build a react (for example) website with a form that contains an input and a button
host that website in an s3 bucket
when clicking the button we call an endpoint (api gateway), that triggers a lambda that inserts the original link and shortened link into a ddb.
calling a different endpoint passing in the shortened url, triggers a lambda that reads the long url from the database and redirects the user to it.


You can try to build this directly on the AWS console to start with, and later build it using CFN, SAM, CDK, or any other IaC tool of your choice, or just go all in from the start with an IaC tool

## Learning 

### Create the React App and host as an AWS S3 Bucket

- [Create a React App with Vite and Upload it to an S3 Bucket](https://youtu.be/2Hx7Wo0lXW8?si=O7pnSbeq4eGtE6JW)

### Commands
#### From within the terraform folder (`cd terraform`):
`terraform init`

`terraform apply --auto-approve`

*Note: if you've previously had to detatch iam roles (due to permission issues) you might have to run the following before running terraform apply:*
`terraform import aws_iam_role.lambda_role lambda-url-shortener-role`



`terraform destroy` = tears everything down

*Note: before running terraform destroy, run:*
```bash
terraform state rm aws_iam_role.lambda_role
terraform state rm aws_iam_role_policy_attachment.lambda_basic_execution
terraform state rm aws_iam_role_policy.lambda_dynamodb
```
*This removes these from state so destroy won't try to delete them (TrainingDeveloper lacks iam:DeleteRolePolicy permission)*


#### From within the project folder (`cd ./url-shortener`):
`npm run build` = builds the react app

`AWS_PROFILE=TrainingDeveloper aws s3 sync ./url-shortener/dist s3://bens-url-shortener-bucket` = Upload the react dist files to the bens-cloudsoft-url-shortener-bucket AWS S3 bucket

To update the S3 after making changes:
```shell
cd url-shortener && npm run build
AWS_PROFILE=TrainingDeveloper aws s3 sync ./dist s3://bens-cloudsoft-url-shortener-bucket
```

`AWS_PROFILE=TrainingDeveloper aws s3 rm s3://bens-url-shortener-bucket --recursive` = Remove the files from the S3 bucket (--recursive specifies everything)

One extra step with CloudFront — it caches files, so after uploading you'll also need to invalidate the cache to see changes immediately:
```bash
AWS_PROFILE=TrainingDeveloper aws cloudfront create-invalidation --distribution-id <DISTRIBUTION_ID> --paths "/*" --profile TrainingDeveloper
```
You can get the distribution ID from terraform output or add it as an output. Without the invalidation, CloudFront may serve stale files for up to 24 hours.

### Setup AWS Lambda, Api Gateway and DynamoDB

[Mini Project Blog](https://dev.to/aws-builders/mini-project-serverless-url-shortener-using-aws-lambda-api-gateway-and-dynamodb-233o)

#### Creating the DynamoDB Table

[Creating DynamoDB using Terraform](https://www.geeksforgeeks.org/devops/creating-aws-dynamodb-table-using-terraform/)

#### Creating a lambda function
[Creating a basic lambda](https://medium.com/@haissamhammoudfawaz/create-a-aws-lambda-function-using-terraform-and-python-4e0c2816753a) *Beware spelling mistakes*

I have set up a Cloudfront so that all the urls (S3, Lambda, DynamoDB etc) have the same url at the start, this means I can dynamically add it into the react script:
```javascript
const response = await fetch('/api/shorten', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ long_url: longURL })
    })
```
