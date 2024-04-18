pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
			dir('/var/lib/jenkins/End_project_EKS') {
                git branch: 'main', url: 'https://github.com/cef-hub/End_project_EKS.git'
            }
			}
        }

        stage('Creds') {
            steps {
			dir('/var/lib/jenkins/End_project_EKS') {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: '37957038-ae46-4a37-9761-2f0aba65316a']]) {
					sh 'terraform init'
                    sh 'terraform apply -var-file=dev.tfvars -auto-approve'
                }
            }
			}
        }
    }
}
