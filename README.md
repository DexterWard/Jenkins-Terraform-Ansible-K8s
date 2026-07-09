# Kubeadm infrastructure creator

This repository contains code intended to run a Jenkins pipeline inside a Docker container in an AWS EC2 instance provisioned with startup-script-jenkins-master.sh, that when executed, creates 2 machines using Terraform, provision them with Ansible to create a Kubernetes cluster with Kubeadm, and serve a simple web page that connects to an RDS database, accessible via an Application Load Balancer. It is also monitored with a Prometheus/Grafana stack operator. 

The idea is to show a conceptual proof of all these technologies:

- AWS EC2 for the underlying infrastructure
- Jenkins as CI/CD tool to run the pipeline
- Terraform to create the K8s nodes
- Ansible to provision the Kubernetes nodes
- Kubeadm to build the K8s cluster
- Python and flask to serve a web app on K8s
- RDS as the database connected to the app to read and write data
- Prometheus/Grafana to monitor the infrastructure
- S3 bucket to act as remote backend for Terraform




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

After initialization, test that Docker is installed and Jenkins is running by connecting to the Public IP address of the instance on port using http, like this: http://publicIP:8080.

If the initial Jenkins screen to input the admin password shows up, then the provisioning was correct. Otherwise connect via ssh to the instance like this:
ssh -i your-key-pair.pem ubuntu@publicIP
and check that docker and Jenkins are running with: docker ps

3) Get the Jenkins admin password by login into the server via ssh and executing the following command: docker exec -ti jenkins sh -c "cat /var/jenkins_home/secrets/initialAdminPassword" Then, install the suggested plugins + Pipeline Utility Steps and create an admin user and password to log in.

4) Create a new EC2 instance (the jenkins agent) with the same settings but with only port 22 open (both to your public IP and to the Jenkins controller). Provision the machine with the file: "startup-scrip-jenkins-agent.sh". This will install the required dependencies.

5) Copy the public key found in /home/jenkins/.ssh/jenkins-agent in the master into /home/jenkins/.ssh/authorized_keys in the agent.

6) Log into the public IP of the Jenkins master via port 8080 and add credentials for the new node:
  - Manage Jenkins --> Credentials --> SSH Username with private key --> Username: jenkins Private key: Enter directly --> Paste the contents of the private ssh key --> Create

7) Create a new agent:
  - New node --> Node name --> Permanent agent --> Adjust the number of executors --> Remote root directory: /home/jenkins -- > Launch method: Launch agents via SSH --> Host: IP address of the agent --> Credentials: Select the credentials created in the previous step --> Host Key Verification Strategy: Non verifying verification strategy
  - Check that the agent is synced and online

8) Create a new S3 bucket in AWS to use as remote backend for the Terraform state file.

9) Create the following credentials in the Jenkins web interface so they can be injected as environment variables in the pipeline:

- REGION - AWS region to deploy the infrastructure (the s3 bucket for the remote state file should be in this region)
- INSTANCE_TYPE - Type of instances needed for the Kubernetes nodes (recommended: c7i-flex.large)
- AMI - Machine image for the kubernetes nodes (recommended: ami-051eaec1417c5d4ae)
- ACCOUNT_ID - Your AWS account ID
- PROFILE - AWS profile configured in .aws/credentials if needed
- ACCESS_KEY - AWS access key for a privileged user able to create infrastructure
- SECRET_ACCESS_KEY - AWS secret access key for a privileged user able to create infrastructure
- GITHUB - Github token to connect with your code repository
- db_password - Assign a password to your RDS database
- bucket - S3 bucket to use as remote backend for the Terraform state file
- node - Private ssh key for a Jenkins node to use as agent. You need to add a different one per each Jenkins agent (see step 6)


10) Create a pipeline job in Jenkins of type Pipeline script from SCM and fill out the gitbhub repository url and the github credentials. Specify the main branch, Jenkinsfile as the Script path and mark GitHub hook trigger for GITScm polling to use Webhooks that trigger the pipeline dynamically.

11) Run the pipeline. It will search for the Jenkinsfile in Github and execute the stages. In the end you will see 2 URLs, one for the application itself and another one to access Grafana and the monitoring stack.

12) Obtain the grafana admin password by executing the following in the kubeadm-master node: kubectl --namespace default get secrets prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo

13) In case that you want to copy the Jenkins credentials from one server to another use these commands:

- docker stop jenkins
- sudo rsync -av old:/var/jenkins_home/secrets/ /path/to/jenkins_home/secrets/
- sudo rsync -av old:/var/jenkins_home/credentials.xml /path/to/jenkins_home/credentials.xml
- sudo chown -R 1000:1000 /path/to/jenkins_home/secrets /path/to/jenkins_home/credentials.xml
- docker start jenkins

