resource "random_string" "vault_pass" {
  length  = 12
  special = false
}

#Create AWS Public key pair
resource "aws_key_pair" "vault_key" {
  key_name   = "vault-key"
  public_key = var.public_key
}

#Create VPC and subnets for EC2 instances
module "vault-demo-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "vault-demo-vpc"
  cidr = var.cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets  = ["10.1.11.0/24", "10.1.12.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
}

#Create Security Group for Vault instance
module "vault-security-group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "vault-server-access"
  description = "Allow connection to Vault API"
  vpc_id      = module.vault-demo-vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "ssh-tcp"]

  ingress_with_cidr_blocks = [
    {
      from_port   = 8200
      to_port     = 8200
      protocol    = "tcp"
      description = "Connect to Vault UI/API"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Connect to Vault server (HTTPS)"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      description = "Kubernetes NodePort range"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Allow SSH"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      description = "Allow egress to everything within VPC"
      cidr_blocks = module.vault-demo-vpc.vpc_cidr_block
    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["https-443-tcp", "http-80-tcp"]
}

#Create Security Group for Nginx instance
resource "aws_security_group" "nginx-sg" {
  name        = "nginx-server-access"
  description = "Allow connection to Nginx server"
  vpc_id      = module.vault-demo-vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "Connect to Nginx server (HTTP)"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "Connect to Nginx server (HTTPS)"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    description = "Kubernetes NodePort range"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "Allow SSH"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow egress to everything within VPC"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create Vault server EC2 instance with AWS Linux AMI
resource "aws_instance" "vault-server" {
  ami           = data.aws_ami.aws_linux_hvm2.id
  instance_type = "t4g.micro"

  key_name                    = aws_key_pair.vault_key.key_name
  monitoring                  = true
  subnet_id                   = module.vault-demo-vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.vault-security-group.security_group_id]
  user_data                   = templatefile("${path.module}/vault_user_data.tftpl", { vaultpass = random_string.vault_pass.id })
  tags = {
    Name = "vault-demo"
  }
}

#Create Nginx server EC2 instance with AWS Linux AMI
resource "aws_instance" "nginx-server" {
  ami           = var.ami_type
  instance_type = "t4g.large"

  key_name                    = aws_key_pair.vault_key.key_name
  monitoring                  = true
  subnet_id                   = module.vault-demo-vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.nginx-sg.id]
  user_data                   = templatefile("${path.module}/nginx_user_data.tftpl", {})
  tags = {
    Name = "nginx-demo"
  }
}
