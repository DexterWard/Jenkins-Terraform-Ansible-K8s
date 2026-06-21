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
                    -var="ami=$AMI"
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
  
                //Clone the kubeadm-ansible repo
            /*    sh '''
                    if [ -d kubeadm-ansible/.git ]; then
                        cd kubeadm-ansible
                        git fetch
                    else
                        git clone https://github.com/kairen/kubeadm-ansible.git
                        cd kubeadm-ansible
                    fi
                '''*/
        
              /*  withEnv([
                    "ANSIBLE_CONFIG=${WORKSPACE}/Project1/kubeadm-ansible/ansible.cfg",
                    "ANSIBLE_HOST_KEY_CHECKING=False"
                ]) {*/
                    sh '''
                        echo 'Copying the ssh key to execute the playbooks...'
                        cp "$SSH_KEY" /tmp/ansible_key.pem
                        chmod 644 /tmp/ansible_key.pem
                        sudo -u ansible ssh-keygen -f '/home/ansible/.ssh/known_hosts' -R '172.31.1.1' || true
                        sudo -u ansible ssh-keygen -f '/home/ansible/.ssh/known_hosts' -R '172.31.1.2' || true
                        sleep 10
                        sudo -u ansible sh -c "ssh-keyscan -H 172.31.1.1 >> /home/ansible/.ssh/known_hosts"
                        sudo -u ansible sh -c "ssh-keyscan -H 172.31.1.2 >> /home/ansible/.ssh/known_hosts"
                        sleep 20
                    '''

                    //sudo -u ansible /home/ansible/.local/bin/ansible-playbook -i /home/jenkins/workspace/Project1/Ansible/hosts.ini --private-key /tmp/ansible_key.pem /home/jenkins/workspace/Project1/kubeadm-ansible/site.yaml
                    //sudo -u ansible /home/ansible/.local/bin/ansible -i hosts.ini --private-key /tmp/ansible_key.pem all -m ping
                //}

                    sh '''
                        echo 'Execute the Ansible playbooks in the master node...'
                        sudo -u ansible /home/ansible/.local/bin/ansible-playbook -i /home/jenkins/workspace/Project1/Ansible/hosts.ini --private-key /tmp/ansible_key.pem /home/jenkins/workspace/Project1/Ansible/kubeadm_master.yaml
                        sleep 10
                        echo 'Execute the Ansible playbooks in the worker node...'
                        sudo -u ansible /home/ansible/.local/bin/ansible-playbook -i /home/jenkins/workspace/Project1/Ansible/hosts.ini --private-key /tmp/ansible_key.pem /home/jenkins/workspace/Project1/Ansible/kubeadm_node.yaml
                    '''
                    }
                       
            }
        }
        
        stage('Build') {
            environment {
                REGION = credentials('REGION')
                ACCOUNT_ID = credentials('ACCOUNT_ID')
                PROFILE = credentials('PROFILE')
                ACCESS_KEY = credentials('ACCESS_KEY')
                SECRET_KEY = credentials('SECRET_KEY')
            }

            steps {
                sh '''
                echo "Configure AWS profile"
                aws configure set profile.jenkins.aws_access_key_id $ACCESS_KEY
                aws configure set profile.jenkins.aws_secret_access_key $SECRET_KEY
                aws configure set profile.jenkins.region $REGION

                echo "Logging into AWS ECR..."
                aws ecr get-login-password --region $REGION --profile $PROFILE | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/my-project
                docker build -t demo-app:${BUILD_NUMBER} demo-app/  
                docker tag demo-app:${BUILD_NUMBER} $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/my-project:${BUILD_NUMBER}
                docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/my-project:${BUILD_NUMBER}   
                '''
            }
        }

        stage('K8s') {
            steps {
                sh 'echo "Here we will have the Kubernetes steps..."'
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