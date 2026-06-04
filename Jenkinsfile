pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform') {
            environment {
                ACCESS_KEY = credentials('ACCESS_KEY')
                SECRET_KEY = credentials('SECRET_KEY')
                REGION = credentials('REGION')
                INSTANCE_TYPE = credentials('INSTANCE_TYPE')
                AMI = credentials('AMI')
                
            }
            steps {
                //Check variable values
            /*    sh '''
                    echo "REGION=$REGION"
                    echo "INSTANCE_TYPE=$INSTANCE_TYPE"
                    echo "AMI=$AMI"
                '''
                sh '''
                    [ -n "$ACCESS_KEY" ] && echo "ACCESS_KEY is set"
                    [ -n "$SECRET_KEY" ] && echo "SECRET_KEY is set"
                '''*/
                dir('/home/jenkins/workspace/Project1/Terraform') {
                sh 'terraform fmt'
                sh 'terraform init'
                sh '''
                    terraform apply -auto-approve \
                    -var="region=$REGION" \
                    -var="access_key=$ACCESS_KEY" \
                    -var="secret_key=$SECRET_KEY" \
                    -var="instance_type=$INSTANCE_TYPE" \
                    -var="ami=$AMI"
                '''
                }
                
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