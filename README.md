# Jenkins-Terraform-Ansible-K8s
This repository contains the code to create a Jenkins pipeline using a Docker container in an AWS EC2 instance that uses a Jenkins agent to create another instance with Terraform, provision it with an Ansible module to create a Kubernetes cluster with Kubeadm and serve a simple web page with Nginx. The idea is to show a conceptual proof of all these technologies.

Technologies used:
- AWS for the virtual machines that serve as Jenkins master, Jenkins agent and K8s cluster control-plane/worker node
- Docker to deploy the Jenkins master node
- Jenkins to create and run the pipeline
- Terraform to create the K8s node
- Ansible to provision the Kubernetes node
- Kubeadm to build the K8s cluster
- Nginx to server a static website



STEPS:

1) Create a Github repository
2) Create an AWS EC2 instance. Recommended settings:

- AMI: Ubuntu Server 24.04 LTS
- Architecture: 64-bit
- Instance type: t3.small (free-tier)
- Create a new RSA key-pair with .pem format
- Default VPC and default subnet are fine as long as they have an Internet Gateway to access the outside world
- Use or create a security group with the following ingress rules:
  Port 22 open to your public IP. (Optionally, open it to the IP address of Instant connect too)
  Port 8080 open to 0.0.0.0/0 so the webhook can reach it
- Default 8 GIB gp3 storage disk
- No special filesystem
- User data: upload the startup-script.sh file to provision the server

Test that Docker is installed and Jenkins is running by connecting to the Public IP address of the instance on port 8080, like this:
xxx.xxx.xxx.xxx:8080

If the initial Jenkins screen to input the admin password shows up, then the provisioning was correct. Otherwise connect via ssh to the instance like this:
ssh -i your-key-pair.pem ubuntu@xxx.xxx.xxx.xxx
and check that docker and Jenkins are running with: docker ps
-
3) Get the Jenkins admin password by login into the server via ssh and executing the following command: docker exec -ti jenkins sh -c "cat /var/jenkins_home/secrets/initialAdminPassword" Then, install the suggested plugins and create an admin user and password to log in.

4) Create a new EC2 instance (the jenkins agent) with the same settings but with only port 22 open. Upload as user-script to provision the machine the file: "startup-scrip-jenkins-agent.sh". This will install Terraform, Python3 and Ansible

5) Log into the Jenkins master node and create a new pair of ssh keys:
  - ssh-keygen -t rsa -b 4096 -f jenkins_agent_key
  - Copy the public key you just created: cat jenkins_agent_key.pub
  - Paste it in  the authorized_keys file of the agent:
    sudo su - jenkins
    mkdir -p ~/.ssh
    nano ~/.ssh/authorized_keys
  - Fix the permissions:
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys

6) Log into the public IP of the Jenkins master via port 8080 and add credentials for the new node:
  - Manage Jenkins --> Credentials --> SSH Username with private key --> Username: jenkins Private key: Enter directly --> Paste the contents of "jenkins_agent_key" --> Create

7) Create a new agent:
  - New node --> Node name --> Permanent agent --> Adjust the number of executors --> Remote root directory: /home/jenkins -- > Launch method: Launch agents via SSH --> Host: IP address of the agent --> Credentials: Select the credentials created in the previous step --> Host Key Verification Strategy: Known hosts file verification strategy
  - Check that the agent is synced and online

8) 