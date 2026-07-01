pipeline {
    agent any

     triggers {
        githubPush()
    }


    environment {
                ACCESS_KEY = credentials('ACCESS_KEY')
                SECRET_KEY = credentials('SECRET_KEY')
                ACCOUNT_ID = credentials('ACCOUNT_ID')
                REGION = "eu-central-1"
                INSTANCE_TYPE = credentials('INSTANCE_TYPE')
                AMI = credentials('AMI')
                DB_PASS = credentials('db_password')
                BUCKET = credentials('bucket')

                AWS_ACCESS_KEY_ID = "${ACCESS_KEY}"
                AWS_SECRET_ACCESS_KEY = "${SECRET_KEY}"
                AWS_DEFAULT_REGION = "eu-central-1"

                ANSIBLE_KEY = "/tmp/ansible"
               
                
            }

    stages {

        stage('Create ssh keys') {
            steps {
                sh """
                    rm -rf ${env.ANSIBLE_KEY}

                    ssh-keygen \
                    -q \
                    -t ed25519 \
                    -N "" \
                    -f ${env.ANSIBLE_KEY}

                    chmod 600 ${env.ANSIBLE_KEY}
                    chmod 644 ${env.ANSIBLE_KEY}.pub
                """

                script{
                    env.ANSIBLE_PUBKEY = readFile("${env.ANSIBLE_KEY}.pub").trim()
                }
            }
        }

        stage('Terraform') {
            
            steps {

                export AWS_ACCESS_KEY_ID=${ACCESS_KEY}
                export AWS_SECRET_ACCESS_KEY=${SECRET_KEY}
                export AWS_DEFAULT_REGION=${REGION}
  
                dir("${env.WORKSPACE}/Terraform") {
                sh 'echo "Linting Terraform code..."'
                sh 'terraform fmt'
                sh 'echo "Initialize Terraform plugins and providers..."'
                sh 'terraform init -reconfigure -backend-config="bucket=${BUCKET}" \
                -var="access_key=${ACCESS_KEY}" \
                -var="secret_key=${SECRET_KEY}" \
                -backend-config="encrypt=true"'
                
                sh 'echo "Applying changes..."'
                sh """
                terraform apply -auto-approve \
                -var="region=${REGION}" \
                -var="access_key=${ACCESS_KEY}" \
                -var="secret_key=${SECRET_KEY}" \
                -var="instance_type=${INSTANCE_TYPE}" \
                -var="ami=${AMI}" \
                -var="db_password=${DB_PASS}" \
                -var="ansible_pubkey=${env.ANSIBLE_PUBKEY}" \
                -var="bucket=${BUCKET}"
                """
                script {
                    env.VPC_ID = sh(script: 'terraform output -raw vpc_id', returnStdout: true).trim()
                    env.DB_HOST = sh(script: 'terraform output -raw database_address', returnStdout: true).trim()
                    env.MASTER = sh(script: 'terraform output -raw master_dns', returnStdout: true).trim()
                    env.WORKER = sh(script: 'terraform output -raw worker_dns', returnStdout: true).trim()
                    env.MASTER_INSTANCE_ID = sh(script: "terraform output -raw master_instance_id", returnStdout: true).trim()
                    env.WORKER_INSTANCE_IDS = sh(script: "terraform output -json worker_instance_ids", returnStdout: true).trim()
                    env.PROVIDER_MASTER = "aws:///${REGION}/${env.MASTER_INSTANCE_ID}"
                    def workers = readJSON text: env.WORKER_INSTANCE_IDS
                    env.PROVIDER_WORKERS = workers.collect { id ->
                    "aws:///${REGION}/${id}".replaceAll(" ", "")}.join(" ")
                }

                }
                
            }
        }
        
        stage('Ansible') {
            steps {

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
                    sudo -u ansible rm -f /home/ansible/.ssh/known_hosts
                    sudo -u ansible touch /home/ansible/.ssh/known_hosts
                    sudo -u ansible chmod 600 /home/ansible/.ssh/known_hosts
                    """

                    script {
                        timeout(time: 10, unit: 'MINUTES') {
                            waitUntil {
                                def rc = sh(
                                    script: """
                                        ssh \
                                        -i ${env.ANSIBLE_KEY} \
                                        -o BatchMode=yes \
                                        -o StrictHostKeyChecking=no \
                                        -o UserKnownHostsFile=/dev/null \
                                        -o ConnectTimeout=5 \
                                        ansible@${env.MASTER} 'echo ok'
                                    """,
                                    returnStatus: true
                                )

                                if (rc == 0) {
                                    echo "Master is ready"
                                    return true
                                }

                                echo "Waiting for master..."
                                sleep 10
                                return false
                            }
                        }
                    }

                    script {
                        timeout(time: 10, unit: 'MINUTES') {
                            waitUntil {
                                def rc = sh(
                                    script: """
                                        ssh \
                                        -i ${env.ANSIBLE_KEY} \
                                        -o BatchMode=yes \
                                        -o StrictHostKeyChecking=no \
                                        -o UserKnownHostsFile=/dev/null \
                                        -o ConnectTimeout=5 \
                                        ansible@${env.WORKER} 'echo ok'
                                    """,
                                    returnStatus: true
                                )

                                if (rc == 0) {
                                    echo "Worker is ready"
                                    return true
                                }

                                echo "Waiting for worker..."
                                sleep 10
                                return false
                            }
                        }
                    }
        
                    sh """
                    
                    echo 'Execute the Ansible playbooks in the master node...'
                    ANSIBLE_CONFIG=${WORKSPACE}/Ansible/ansible.cfg /home/jenkins/.local/bin/ansible-playbook  --private-key ${env.ANSIBLE_KEY} ${env.WORKSPACE}/Ansible/playbook-kubeadm_master.yaml
                    
                    echo 'Execute the Ansible playbooks in the worker node...'
                    ANSIBLE_CONFIG=${WORKSPACE}/Ansible/ansible.cfg /home/jenkins/.local/bin/ansible-playbook  --private-key ${env.ANSIBLE_KEY} ${env.WORKSPACE}/Ansible/playbook-kubeadm_node.yaml

                    echo 'Execute the synchronization playbook...'
                    ANSIBLE_CONFIG=${WORKSPACE}/Ansible/ansible.cfg /home/jenkins/.local/bin/ansible-playbook --private-key ${env.ANSIBLE_KEY} ${env.WORKSPACE}/Ansible/playbook-sync.yaml

                    """
                       
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

                echo "Installing the ALB..."
                echo ${VPC_ID}
                ANSIBLE_CONFIG=${WORKSPACE}/Ansible/ansible.cfg /home/jenkins/.local/bin/ansible-playbook --private-key ${env.ANSIBLE_KEY} -e "vpc_id=${VPC_ID}" -e "region=${REGION}"  -e "provider_master=${env.PROVIDER_MASTER}" -e "provider_worker=${env.PROVIDER_WORKERS}" ${env.WORKSPACE}/Ansible/playbook-ALB.yaml
    
                echo "Deploying app"

                echo "Creating secret..."
                ANSIBLE_CONFIG=${WORKSPACE}/Ansible/ansible.cfg /home/jenkins/.local/bin/ansible-playbook  --private-key ${env.ANSIBLE_KEY} -e "db_host=${DB_HOST}" -e "db_pass=${DB_PASS}" ${env.WORKSPACE}/Ansible/playbook-rds-secret.yaml

                echo "Authenticating into ECR..."
                ANSIBLE_CONFIG=${WORKSPACE}/Ansible/ansible.cfg /home/jenkins/.local/bin/ansible-playbook --private-key ${env.ANSIBLE_KEY} -e "region=${REGION}" -e "aws_access_key_id=${AWS_ACCESS_KEY_ID}" -e "aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}" -e "ecr_server=${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com" ${env.WORKSPACE}/Ansible/playbook-ecr-secret.yaml

                echo "Creating deployment and NodePort service..."
                ANSIBLE_CONFIG=${WORKSPACE}/Ansible/ansible.cfg /home/jenkins/.local/bin/ansible-playbook --private-key ${env.ANSIBLE_KEY} -e "ACCOUNT_ID=${ACCOUNT_ID}" -e "db_host=${DB_HOST}" -e "db_pass=${DB_PASS}" -e "REGION=${REGION}" -e "IMAGE_TAG=${BUILD_NUMBER}" ${env.WORKSPACE}/Ansible/playbook-deployment.yaml

                echo "Creating ingress..."
                ANSIBLE_CONFIG=${WORKSPACE}/Ansible/ansible.cfg /home/jenkins/.local/bin/ansible-playbook --private-key ${env.ANSIBLE_KEY} ${env.WORKSPACE}/Ansible/playbook-ingress.yaml
                """
                
            }
        }
        
    }

    post {
        failure {
            echo 'Something went wrong, reverting changes....'
            //sh 'kubectl rollout undo deployment/myapp'
        }
    }
}