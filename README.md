**Vault-K3s-AWS**

This repository was forked from the original master branch. My intention with this branch was to include Nginx service for K3s.

Using Terraform, you can deploy two EC2 instances within AWS. The `data.tf` configuration file pulls from Amazon, so you don't need to insert particular details for your instance like AMI type.

Within, you'll find `user_data.tftpl` files for both Vault and Nginx for automated install. 

Before deploying Terraform, please ensure you have created an AWS Key Pair with AWS KMS for the `vault-key.pub` file.

I'll have instructions up and running soon!
