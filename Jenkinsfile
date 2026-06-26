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
                sh 'echo "Initialize Terraform plugins and providers..."'
                sh 'terraform init -reconfigure'
                
                sh 'echo "Applying changes..."'
                sh """
                terraform apply -auto-approve \
                -var="region=${REGION}" \
                -var="access_key=${ACCESS_KEY}" \
                -var="secret_key=${SECRET_KEY}" \
                -var="instance_type=${INSTANCE_TYPE}" \
                -var="ami=${AMI}" \
                -var="db_password=${DB_PASS}"
                """
                script {
                    env.VPC_ID = sh(script: 'terraform output -raw vpc_id', returnStdout: true).trim()
                    env.DB_HOST = sh(script: 'terraform output -raw database_address', returnStdout: true).trim()
                    env.MASTER = sh(script: 'terraform output -raw master_dns', returnStdout: true).trim()
                    env.WORKER = sh(script: 'terraform output -raw worker_dns', returnStdout: true).trim()
                }

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

                script {
                    def hostsFile = "${env.WORKSPACE}/Ansible/hosts.ini"

                     writeFile file: hostsFile, text: """
                    [master]
                    ${env.MASTER} ansible_python_interpreter=python3

                    [node]
                    ${env.WORKER} ansible_python_interpreter=python3

                    [kube_cluster:children]
                    master
                    node
                    """
                }

                    sh """
                    echo 'Copying the ssh key to execute the playbooks...'
                    cp "$SSH_KEY" /tmp/ansible_key.pem
                    chmod 644 /tmp/ansible_key.pem
                    
                    sudo -u ansible ssh-keygen -f '/home/ansible/.ssh/known_hosts' -R '${MASTER}' || true
                    sudo -u ansible ssh-keygen -f '/home/ansible/.ssh/known_hosts' -R '${WORKER}' || true
                    
                    for i in {1..30}; do
                        if sudo -u ansible sh -c 'ssh-keyscan -H ${MASTER} >> /home/ansible/.ssh/known_hosts' 2>/dev/null; then
                            echo "SSH ready on ${MASTER}"
                            break
                        fi

                        echo "waiting for ssh on ${MASTER}..."
                        sleep 20
                    done

                    for i in {1..30}; do
                        if sudo -u ansible sh -c 'ssh-keyscan -H ${WORKER} >> /home/ansible/.ssh/known_hosts' 2>/dev/null; then
                            echo "SSH ready on ${WORKER}"
                            break
                        fi

                        echo "waiting for ssh on ${WORKER}..."
                        sleep 20
                    done
        

                    echo 'Execute the Ansible playbooks in the master node...'
                    sudo -u ansible /home/ansible/.local/bin/ansible-playbook -i ${env.WORKSPACE}/Ansible/hosts.ini --private-key /tmp/ansible_key.pem ${env.WORKSPACE}/Ansible/playbook-kubeadm_master.yaml
                    
                    echo 'Execute the Ansible playbooks in the worker node...'
                    sudo -u ansible /home/ansible/.local/bin/ansible-playbook -i ${env.WORKSPACE}/Ansible/hosts.ini --private-key /tmp/ansible_key.pem ${env.WORKSPACE}/Ansible/playbook-kubeadm_node.yaml

                    echo 'Execute the synchronization playbook...'
                    sudo -u ansible /home/ansible/.local/bin/ansible-playbook -i ${env.WORKSPACE}/Ansible/hosts.ini --private-key /tmp/ansible_key.pem ${env.WORKSPACE}/Ansible/playbook-sync.yaml

                    """
                }
                       
            }
        }
        
        stage('Build') {

            steps {
       
                sh """
                echo "Logging into AWS ECR..."
                aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/my-project
                
                echo "Build, tag and push image..."
                docker build -t ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/my-project:${BUILD_NUMBER} -t ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/my-project:latest demo-app/
                
                docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/my-project:${BUILD_NUMBER}
                docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/my-project:latest
                """
            }
        }


        stage('K8s') {
            
            steps {

                sh """
                echo "Installing Kubernetes objects..."
                sudo -u ansible /home/ansible/.local/bin/ansible-playbook -i ${env.WORKSPACE}/Ansible/hosts.ini --private-key /tmp/ansible_key.pem -e "vpc_id=${VPC_ID}" -e "region=${REGION}" ${env.WORKSPACE}/Ansible/playbook-ALB.yaml
    
                echo "Deploying app"

                echo "Creating secret..."
                sudo -u ansible /home/ansible/.local/bin/ansible-playbook -i ${env.WORKSPACE}/Ansible/hosts.ini --private-key /tmp/ansible_key.pem -e "db_host=${DB_HOST}" -e "db_pass=${DB_PASS}" ${env.WORKSPACE}/Ansible/playbook-rds-secret.yaml

                echo "Authenticating into ECR..."
                sudo -u ansible /home/ansible/.local/bin/ansible-playbook -i ${env.WORKSPACE}/Ansible/hosts.ini --private-key /tmp/ansible_key.pem -e "region=${REGION}" -e "aws_access_key_id=${AWS_ACCESS_KEY_ID}" -e "aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}" -e "ecr_server=${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com" ${env.WORKSPACE}/Ansible/playbook-ecr-secret.yaml

                echo "Creating deployment and ClusterIP service..."
                sudo -u ansible /home/ansible/.local/bin/ansible-playbook -i ${env.WORKSPACE}/Ansible/hosts.ini --private-key /tmp/ansible_key.pem -e "ACCOUNT_ID=${ACCOUNT_ID}" -e "db_host=${DB_HOST}" -e "db_pass=${DB_PASS}" -e "REGION=${REGION}" -e "IMAGE_TAG=${BUILD_NUMBER}" ${env.WORKSPACE}/Ansible/playbook-deployment.yaml

                echo "Creating ingress..."
                sudo -u ansible /home/ansible/.local/bin/ansible-playbook -i ${env.WORKSPACE}/Ansible/hosts.ini --private-key /tmp/ansible_key.pem ${env.WORKSPACE}/Ansible/playbook-ingress.yaml
                """
                
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