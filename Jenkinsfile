pipeline {
    agent any

    environment {
                ACCESS_KEY = credentials('ACCESS_KEY')
                SECRET_KEY = credentials('SECRET_KEY')
                ACCOUNT_ID = credentials('ACCOUNT_ID')
                REGION = credentials('REGION')
                INSTANCE_TYPE = credentials('INSTANCE_TYPE')
                AMI = credentials('AMI')
                DB_PASS = credentials('db_password')

                AWS_ACCESS_KEY_ID = "${ACCESS_KEY}"
                AWS_SECRET_ACCESS_KEY = "${SECRET_KEY}"
                AWS_DEFAULT_REGION = "${REGION}"
               
                
            }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform') {
            
            steps {

              //  dir('/home/jenkins/workspace/Project1/Terraform') {
  
                dir("${env.WORKSPACE}/Terraform") {
                sh 'echo "Linting Terraform code..."'
                sh 'terraform fmt'
                sh 'echo "Intialize Terraform plugins and providers..."'
                sh 'terraform init'
                sh '''
                    terraform apply -auto-approve \
                    -var="region=$REGION" \
                    -var="access_key=$ACCESS_KEY" \
                    -var="secret_key=$SECRET_KEY" \
                    -var="instance_type=$INSTANCE_TYPE" \
                    -var="ami=$AMI" \
                    -var="db_password=$DB_PASS"
                '''
                }
                
            }
        }
        
        stage('Ansible') {
            steps {

                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ansible-private-key',
                        keyFileVariable: 'SSH_KEY'
                    )
                ]) {

                    sh '''
                        echo 'Copying the ssh key to execute the playbooks...'
                        cp "$SSH_KEY" /tmp/ansible_key.pem
                        chmod 644 /tmp/ansible_key.pem
                        sudo -u ansible ssh-keygen -f '/home/ansible/.ssh/known_hosts' -R '172.31.1.1' || true
                        sudo -u ansible ssh-keygen -f '/home/ansible/.ssh/known_hosts' -R '172.31.1.2' || true
                        
                        sleep 10
                        
                        sudo -u ansible sh -c "ssh-keyscan -H 172.31.1.1 >> /home/ansible/.ssh/known_hosts"
                        sudo -u ansible sh -c "ssh-keyscan -H 172.31.1.2 >> /home/ansible/.ssh/known_hosts"
                        
                        sleep 60

                        echo 'Execute the Ansible playbooks in the master node...'
                        sudo -u ansible /home/ansible/.local/bin/ansible-playbook -i /home/jenkins/workspace/Project1/Ansible/hosts.ini --private-key /tmp/ansible_key.pem /home/jenkins/workspace/Project1/Ansible/kubeadm_master.yaml
                        
                        sleep 30
                        
                        echo 'Execute the Ansible playbooks in the worker node...'
                        sudo -u ansible /home/ansible/.local/bin/ansible-playbook -i /home/jenkins/workspace/Project1/Ansible/hosts.ini --private-key /tmp/ansible_key.pem /home/jenkins/workspace/Project1/Ansible/kubeadm_node.yaml
                    '''
                    }
                       
            }
        }
        
        stage('Build') {

            steps {
       
                sh '''
                echo "Logging into AWS ECR..."
                aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/my-project
                
                echo "Build, tag and push image..."
                docker build -t $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/my-project:${BUILD_NUMBER} -t $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/my-project:latest demo-app/
                
                docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/my-project:${BUILD_NUMBER}
                docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/my-project:latest
                '''
            }
        }

        stage('Get Terraform Outputs') {
    
            steps {
                script {
                    dir("${env.WORKSPACE}/Terraform") {
                        env.VPC_ID = sh(
                            script: 'terraform output -raw vpc_id',
                            returnStdout: true
                        ).trim()

                        env.DB_HOST = sh(
                            script: 'terraform output -raw database_address',
                            returnStdout: true
                        ).trim()
                    }
                }
            }
        }

        stage('K8s') {
            
            steps {

                sh '''
                echo "Installing Kubernetes objects..."
                sudo -u ansible /home/ansible/.local/bin/ansible-playbook -i /home/jenkins/workspace/Project1/Ansible/hosts.ini --private-key /tmp/ansible_key.pem -e "vpc_id=$VPC_ID" -e "region=$REGION" /home/jenkins/workspace/Project1/Ansible/ALB.yaml
    
                echo "Deploying app"

                echo "Creating secret..."
                sudo -u ansible /home/ansible/.local/bin/ansible-playbook -i /home/jenkins/workspace/Project1/Ansible/hosts.ini --private-key /tmp/ansible_key.pem -e "db_host=$DB_HOST" -e "db_pass=$DB_PASS" /home/jenkins/workspace/Project1/Ansible/playbook-rds-secret.yaml

                echo "Authenticating into ECR..."
                sudo -u ansible /home/ansible/.local/bin/ansible-playbook -i /home/jenkins/workspace/Project1/Ansible/hosts.ini --private-key /tmp/ansible_key.pem -e "region=$REGION" -e "aws_access_key_id=$AWS_ACCESS_KEY_ID" -e "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" -e "ecr_server=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com" /home/jenkins/workspace/Project1/Ansible/playbook-ecr-secret.yaml

                echo "Creating deployment..."
                sudo -u ansible /home/ansible/.local/bin/ansible-playbook -i /home/jenkins/workspace/Project1/Ansible/hosts.ini --private-key /tmp/ansible_key.pem -e "ACCOUNT_ID=$ACCOUNT_ID" -e "db_host=$DB_HOST" -e "db_pass=$DB_PASS" -e "REGION=$REGION" -e "IMAGE_TAG=$BUILD_NUMBER" /home/jenkins/workspace/Project1/Ansible/playbook-deployment.yaml
                '''

            //    sh 'echo "DB_HOST=$DB_HOST"'
                
            }
        }
    }

    post {
        failure {
            echo 'Something went wrong, reverting changes...'
            //sh 'kubectl rollout undo deployment/myapp'
            //docker tag demo-app:${BUILD_NUMBER} $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/my-project:${BUILD_NUMBER}
        }
    }
}