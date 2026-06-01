pipeline {
    agent any

    stages {

        stage('Create environment') {
            steps {
                sh 'cd /home/Jenkins/'
                sh 'git clone https://github.com/DexterWard/Jenkins-Terraform-Ansible-K8s.git'
                git branch: main, url:"https://github.com/DexterWard/Jenkins-Terraform-Ansible-K8s.git"
                sh 'cd Jenkins-Terraform-Ansible-K8s/'
            }
        }

        stage('Terraform') {
            environment {
                REGION = credentials('REGION')
                PROFILE = credentials('PROFILE')
                ACCESS_KEY = credentials('ACCESS_KEY')
                SECRET_KEY = credentials('SECRET_KEY')
            }
            steps {
                sh 'cd Terraform'
                sh 'terraform init'
                sh 'terraform apply -auto-approve -var "region=${REGION},profile=${PROFILE},access_key=${ACCESS_KEY},secret_key=${SECRET_KEY}"'
            }
        }

        stage('Ansible') {
            steps {
                sh 'echo "Here we will have the Ansible steps"'
            }
        }

        stage('K8s') {
            steps {
                sh 'echo "Here we will have the Kubernetes steps"'
            }
        }
    }

    post {
        failure {
            echo 'Something went wrong, reverting changes...'
            //sh 'kubectl rollout undo deployment/myapp'
        }
    }
}