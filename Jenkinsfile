pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
			dir('/home/ec2-user/End_project_EKS') {
                git branch: 'main', url: 'https://github.com/cef-hub/End_project_EKS.git'
            }
			}
        }

        stage('Terraform Init') {
            steps {
                dir('/home/ec2-user/End_project_EKS') {
                script {
                        sh 'terraform init'
                }
            }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('/home/ec2-user/End_project_EKS') {
                script {
                        sh 'terraform apply -var-file=dev.tfvars'
                }
            }
            }
        }
    }
}
