# Kubeadm infrastructure creator

This repository contains code intended to create a Jenkins pipeline inside a Docker container in an AWS EC2 instance (startup-script-jenkins-master.sh), that when executed, creates 2 machines using Terraform, provision them with Ansible to create a Kubernetes cluster with Kubeadm, and serve a simple web page that connects to an RDS database, accessible via an Application Load Balancer. It is also monitored with a Prometheus/Grafana stack operator. 

The idea is to show a conceptual proof of all these technologies:

- AWS for all the EC2 instances
- Docker to deploy Jenkins inside
- Jenkins to create and run the pipeline
- Terraform to create the K8s nodes
- Ansible to provision the Kubernetes nodes
- Kubeadm to build the K8s cluster
- Python and flask to serve a web app
- RDS as the database connected to the app
- Prometheus/Grafana to monitor the infrastructure



STEPS:

1) Create a Github repository
2) Create an AWS EC2 instance. Recommended settings:

- AMI: Ubuntu Server 26.04 LTS
- Architecture: 64-bit
- Instance type: t3.small (free-tier)
- Create a new RSA key-pair with .pem format
- Default VPC and default subnet are fine as long as they have an Internet Gateway to access the outside world
- Use or create a security group with the following ingress rules:
  Port 22 open to your public IP. (Optionally, open it to the IP address of Instant connect too)
  Port 8080 open to 0.0.0.0/0 so the webhook can reach it
- Default 8 GIB gp3 storage disk
- No special filesystem
- User data: upload the startup-script-jenkins-master.sh file to provision the server

After initialization, test that Docker is installed and Jenkins is running by connecting to the Public IP address of the instance on port 8080, like this:
xxx.xxx.xxx.xxx:8080

If the initial Jenkins screen to input the admin password shows up, then the provisioning was correct. Otherwise connect via ssh to the instance like this:
ssh -i your-key-pair.pem ubuntu@xxx.xxx.xxx.xxx
and check that docker and Jenkins are running with: docker ps
-
3) Get the Jenkins admin password by login into the server via ssh and executing the following command: docker exec -ti jenkins sh -c "cat /var/jenkins_home/secrets/initialAdminPassword" Then, install the suggested plugins and create an admin user and password to log in.

4) Create a new EC2 instance (the jenkins agent) with the same settings but with only port 22 open (both to your public IP and to the Jenkins controller). Provision the machine with the file: "startup-scrip-jenkins-agent.sh". This will install the required dependencies.

5) Create a new ssh key-pair to connect Jenkins master and Jenkins agent:
 ssh-keygen -t ed25519 -N "" -f jenkins-agent
 - Copy the public key into /home/jenkins/.ssh/authorized_keys in the agent.

6) Log into the public IP of the Jenkins master via port 8080 and add credentials for the new node:
  - Manage Jenkins --> Credentials --> SSH Username with private key --> Username: jenkins Private key: Enter directly --> Paste the contents of the private ssh key --> Create

7) Create a new agent:
  - New node --> Node name --> Permanent agent --> Adjust the number of executors --> Remote root directory: /home/jenkins -- > Launch method: Launch agents via SSH --> Host: IP address of the agent --> Credentials: Select the credentials created in the previous step --> Host Key Verification Strategy: Non verifying verification strategy
  - Check that the agent is synced and online

8) Create credentials of type "secret text" in the Jenkins web interface so they can be injected as environment variables in the pipeline.

9) Create a pipeline job in Jenkins of type SCM and fill out the gitbhub repository and the github credentials.

10) Run the pipeline. It will search for the Jenkinsfile in Github and execute the stages.