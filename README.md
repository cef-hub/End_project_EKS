
## 1. Создали файл для запуска основного terraform кода main.tf, содежащего создание объектов облака AWS и EKS кластер Kubernetes (параметризуем переменной necessity_eks=yes/no)

```

provider "aws" {
  region = "us-east-1"
}

locals {
environment = terraform.workspace == "skruhlik.dev" ? "skruhlik.dev" : "skruhlik.prod"
environment_db = terraform.workspace == "skruhlik.dev" ? "skruhlikdev" : "skruhlikprod"
}

resource "aws_vpc" "skruhlik-vpc" {
  cidr_block = var.cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "skruhlik-vpc"
    Environment = local.environment
	ManagedBy = var.managedby
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.skruhlik-vpc.id
  cidr_block = var.cidr_block_pr1
  availability_zone = "us-east-1a"

  tags = {
    Name        = "skruhlik-private-subnet-1"
    Environment = local.environment
    ManagedBy   = var.managedby
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.skruhlik-vpc.id
  cidr_block = var.cidr_block_pr2
  availability_zone = "us-east-1a"

  tags = {
    Name        = "skruhlik-private-subnet-2"
    Environment = local.environment
    ManagedBy   = var.managedby
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.skruhlik-vpc.id
  cidr_block = var.cidr_block_pb1
  availability_zone = "us-east-1a"

  tags = {
    Name        = "skruhlik-public-subnet-1"
    Environment = local.environment
    ManagedBy   = var.managedby
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.skruhlik-vpc.id
  cidr_block = var.cidr_block_pb2
  availability_zone = "us-east-1a"

  tags = {
    Name        = "skruhlik-public-subnet-2"
    Environment = local.environment
    ManagedBy   = var.managedby
  }
}

resource "aws_internet_gateway" "skruhlik-gw" {
  vpc_id = aws_vpc.skruhlik-vpc.id

  tags = {
    Name = "skruhlik-InternetGateway"
    Environment = local.environment
	ManagedBy = var.managedby
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.skruhlik-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.skruhlik-gw.id
  }

  tags = {
    Name = "skruhlik-PublicRouteTable"
    Environment = local.environment
	ManagedBy = var.managedby
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

output "private_subnet_ids" {
  value = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

output "public_subnet_ids" {
  value = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

resource "aws_security_group" "skruhlik-allow-ssh" {
  name        = "skruhlik-allow-ssh"
  description = "allow ssh access"
  vpc_id      = aws_vpc.skruhlik-vpc.id  

  ingress {
    description = "ssh from public subnets"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "skruhlik-allow-ssh"
    Environment = local.environment
	ManagedBy = var.managedby
  }
}


resource "aws_ecr_repository" "skruhlik-ecr-repository" {
  name                  = "skruhlik-ecr-repository"
  image_scanning_configuration {
    scan_on_push        = false
  }
  encryption_configuration {
    encryption_type     = "AES256"
  }
  
  tags = {
    Name      = "skruhlik-ecr-repository"
    ManagedBy = var.managedby
  }
}

/*
resource "aws_dynamodb_table" "skruhlik-lock-table" {
  name           = "skruhlik-lock-table"
  billing_mode   = "PAY_PER_REQUEST"  
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Environment = local.environment
    ManagedBy = var.managedby   
  }
}
*/

/*
resource "aws_s3_bucket" "skruhlik-bucket" {
  bucket = "skruhlik-bucket"
  acl    = "private"

  tags = {
    Environment = local.environment
	ManagedBy = var.managedby
  }
}
*/

terraform {
  backend "s3" {
    bucket = "skruhlik-bucket"
    key    = "terraform.local.environment.tfstate"
    region = "us-east-1"
	dynamodb_table = "skruhlik-lock-table"
  }
}

resource "random_string" "rand_pass" {
  length           = 12
  special          = true
  override_special = "$@"
}

module "ssm_store" {
  source  = "cloudposse/ssm-parameter-store/aws"

  parameter_write = [
    {
      name        = "skruhlik.pass"
      value       = random_string.rand_pass.result
      type        = "SecureString"
      overwrite   = "true"
      description = var.description
    }
  ]

  tags = {
    ManagedBy = var.managedby
  }
}

resource "aws_network_interface" "private_1" {
  subnet_id   = aws_subnet.private_subnet_1.id
  security_groups = [aws_security_group.skruhlik-allow-ssh.id]

  tags = {
    Name = "skruhlik-private-interface"
  }
}

resource "aws_network_interface" "private_2" {
  subnet_id   = aws_subnet.private_subnet_2.id
  security_groups = [aws_security_group.skruhlik-allow-ssh.id]

  tags = {
    Name = "skruhlik-private-interface"
  }
}

resource "aws_network_interface" "public_1" {
  subnet_id   = aws_subnet.public_subnet_1.id
  security_groups = [aws_security_group.skruhlik-allow-ssh.id]

  tags = {
    Name = "skruhlik-public-interface"
  }
}

resource "aws_network_interface" "public_2" {
  subnet_id   = aws_subnet.public_subnet_2.id
  security_groups = [aws_security_group.skruhlik-allow-ssh.id]

  tags = {
    Name = "skruhlik-public-interface"
  }
}

/*
resource "aws_network_interface_attachment" "private_subnet_1" {
  instance_id          = aws_instance.skruhlik-terraform-ec2.id
  network_interface_id = aws_network_interface.private_1.id
  device_index         = 4
}
*/

/*
resource "aws_network_interface_attachment" "public_subnet_1" {
  instance_id          = aws_instance.skruhlik-terraform-ec2.id
  network_interface_id = aws_network_interface.public_1.id
  device_index         = 1
}
*/

resource "aws_network_interface_attachment" "private_subnet_2" {
  instance_id          = aws_instance.skruhlik-terraform-ec2.id
  network_interface_id = aws_network_interface.private_2.id
  device_index         = 2
}

/*
resource "aws_network_interface_attachment" "public_subnet_2" {
  instance_id          = aws_instance.skruhlik-terraform-ec2.id
  network_interface_id = aws_network_interface.public_2.id
  device_index         = 3
}
*/

resource "aws_instance" "skruhlik-terraform-ec2" {
  availability_zone      = "us-east-1a"
  ami                    = "ami-044a3516c1b05985f"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet_1.id 
  vpc_security_group_ids = [aws_security_group.skruhlik-allow-ssh.id]
  key_name               = "devops"
  associate_public_ip_address = true

  tags = {
    Name = "skruhlik-terraform-ec2"
  }
}

resource "aws_db_instance" "skruhlik_pg_instance" {
  count = var.necessity_db == "yes" ? 1 : 0
  
  allocated_storage    = 10
  db_name              = "${local.environment_db}"
  engine               = "postgres"
  engine_version       = "16.2"
  instance_class       = var.instance_class
  username             = "postgres"
  password             = random_string.rand_pass.result
  publicly_accessible  = true
  skip_final_snapshot  = true
}

output "vpc_id" {
  value = aws_vpc.skruhlik-vpc.id
}

output "vpc_public_subnet_ids" {
  value = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "vpc_private_subnet_ids" {
  value = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

output "vpc_vgw_id" {
  value = aws_internet_gateway.skruhlik-gw.id
}

```

## 2. Создали файл конфигурации Jenkins для получения Webhooks от GitHub по событию push в репозиторий Git. Разворачивается инфраструктура AWS, собирается образ Docker из Dockerfile и пушиться в ECR репозиторий AWS. На основании образа в инфраструктуре EKS создается POD c развернутым приложением skruhlik-app, доступным из Internet

```

pipeline {
    agent any

	environment {
        AWS_DEFAULT_REGION = 'us-east-1' 
        AWS_ACCOUNT_ID = '097084951758' 
        ECR_REPOSITORY_NAME = 'skruhlik-ecr-repository'
		PATH = '/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/ec2-user/.local/bin/kubectl'		
    }
	
    stages {
        stage('Checkout') {
            steps {
			dir('/var/lib/jenkins/End_project_EKS') {
                git branch: 'main', url: 'https://github.com/cef-hub/End_project_EKS.git'
            }
			}
        }

        stage('Terraform install and Dcoker build with ECR push') {
            steps {
			dir('/var/lib/jenkins/End_project_EKS') {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: '37957038-ae46-4a37-9761-2f0aba65316a']]) {
					sh 'terraform init'
                    sh 'terraform apply -var-file=dev.tfvars -auto-approve'
					sh 'docker build -t skruhlik-app:latest -f /var/lib/jenkins/End_project_EKS/docker/Dockerfile /var/lib/jenkins/End_project_EKS/docker'
                    sh 'docker tag skruhlik-app:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:latest'
                    sh 'aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com'
                    sh 'docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:latest'
                }
            }
			}
        }
		stage('Deploy to Kubernetes') {
			steps {
				script {
					def clusterUrl = sh(script: 'terraform output -json kubeconfig_url | jq -r .value', returnStdout: true).trim()
					def kubeconfigToken = sh(script: 'terraform output -json kubeconfig_token | jq -r .value', returnStdout: true).trim()

					sh 'kubectl config set-cluster cluster --server=${clusterUrl} --insecure-skip-tls-verify=true'
					sh 'kubectl config set-credentials user --token=${kubeconfigToken}'
					sh 'kubectl config set-context context --cluster=cluster --user=user'
					sh 'kubectl config use-context context'

					withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: '37957038-ae46-4a37-9761-2f0aba65316a']]) {
						sh 'aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com'
						sh 'docker pull $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:latest'
						sh 'aws eks update-kubeconfig --name skruhlik-eks-cluster'
						sh 'kubectl apply -f deployment-skruhlik-app.yml'
					}

					
				}
    }
}
    }
}


```

## 3. Создали Dockerfile для приложения на Python (мониторинг системы)

```

FROM alpine:latest

ADD google.crt /usr/local/share/ca-certificates/
ADD github.crt /usr/local/share/ca-certificates/
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.18/main ca-certificates
RUN update-ca-certificates
RUN apk update && apk add git gcc python3-dev linux-headers libffi-dev libc-dev musl-dev python3 py3-pip python3-dev

ENV PYTHONUNBUFFERED=1
ENV TZ=Europe/Minsk
RUN ln -sf python3 /usr/bin/python
RUN python3 -m venv /root/python/.venv
ENV PATH="/root/python/.venv/bin:$PATH"
RUN mkdir -p /home/AI/comp
WORKDIR /home/AI/comp
RUN pip install --upgrade pip setuptools wheel cython
RUN git clone https://github.com/pypa/setuptools.git /home/AI/comp && cd /home/AI/comp && python3 -m pip install -e /home/AI/comp
RUN pip3 install psutil

COPY requirements.txt /home/AI/comp
COPY Ussage.py /home/AI/comp

RUN pip3 install -r /home/AI/comp/requirements.txt

ENV PATH=/root/.local:$PATH

CMD [ "python3", "-u", "/home/AI/comp/Ussage.py" ]

EXPOSE 5555

```


## 4. Создали файл deployment-skruhlik-app.yml для разворачивания приложения skruhlik-app в инфраструктуре AWS из репозитория ECR AWS

```

apiVersion: apps/v1
kind: Deployment
metadata:
  name: skruhlik-app
  labels:
    app: skruhlik-app
spec:
  replicas: 1  
  selector:
    matchLabels:
      app: skruhlik-app
  template:
    metadata:
      labels:
        app: skruhlik-app
    spec:
      containers:
      - name: skruhlik-app
        image: 097084951758.dkr.ecr.us-east-1.amazonaws.com/skruhlik-ecr-repository:latest 
        ports:
        - containerPort: 5555  
---
apiVersion: v1
kind: Service
metadata:
  name: skruhlik-app-service
spec:
  selector:
    app: skruhlik-app
  ports:
    - protocol: TCP
      port: 3333  
      targetPort: 5555  
  type: LoadBalancer  
   
		  
```

##  Создали и настроили Webhooks в GitHub


![Webhoks](https://github.com/cef-hub/End_project_EKS/blob/main/image/Webhook1.png?raw=true)

![Webhoks2](https://github.com/cef-hub/End_project_EKS/blob/main/image/Webhook2.png?raw=true)


##  Создали и настроили Jenkins на отдельно выденной ноде AWS EC2


![Jenkins](https://github.com/cef-hub/End_project_EKS/blob/main/image/Jenkins0.png?raw=true)

![Jenkins2 собрали с 16-го раза](https://github.com/cef-hub/End_project_EKS/blob/main/image/Jenkins.png?raw=true)


##  Подключились в приложении Lens  к кластеру EKS AWS


![Lens](https://github.com/cef-hub/End_project_EKS/blob/main/image/Lens.png?raw=true)

##  Вызвали API-сервиса задеплоенного в нашем кластере из образа скачанного с ECR репозитория AWS


![Postman](https://github.com/cef-hub/End_project_EKS/blob/main/image/Postman.png?raw=true)

