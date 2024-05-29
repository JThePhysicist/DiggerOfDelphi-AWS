FROM hashicorp/terraform:latest

# Install AWS CLI using apk
RUN apk add --no-cache python3 py3-pip aws-cli

WORKDIR /terraform

COPY . /terraform

