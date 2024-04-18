pipeline {
    agent any

	environment {
        AWS_DEFAULT_REGION = 'us-east-1' 
        AWS_ACCOUNT_ID = '097084951758' 
        ECR_REPOSITORY_NAME = 'skruhlik-ecr-repository'
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

					sh 'aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com'
					sh 'docker pull $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:latest'

					sh 'kubectl apply -f deployment-skruhlik-app.yml'
				}
    }
}
    }
}
