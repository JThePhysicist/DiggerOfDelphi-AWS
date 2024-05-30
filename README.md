# DiggerOfDelphi-AWS v 0.0.1


Sets up labeling pipeline on AWS using Terraform. Uses Google Gemini Pro Vision at the moment

To setup:
First build docker container:

May need to pull base container using "docker pull hashicorp/terraform:latest"

Ensure you're in base git repo directory.

Then build using "docker build -t terraform-label-app ."

Docker container can be run using 

docker run -it --rm \
  -v $(pwd):/terraform \
  -e AWS_ACCESS_KEY_ID=(YOUR AWS ACCESS KEY) \
  -e AWS_SECRET_ACCESS_KEY=(YOUR AWS SECRET KEY) \
  -e AWS_DEFAULT_REGION=us-west-1 \
  terraform-label-app

Inside docker shell execute:
terraform init
terraform plan
terraform apply

To tear down infrastructure execute:
terraform destroy

To use you'll need a google gemini api key. There is a free tier and you can sign up at https://ai.google.dev/
