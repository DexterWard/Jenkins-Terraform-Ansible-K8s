# Jenkins-Terraform-Ansible-K8s
This repository contains the code to create a Jenkins pipeline using a Docker container in an AWS EC2 instance that uses an agent to create another instance with Terraform, provision it with an Ansible module to create a Kubernetes cluster with Kubeadm and serve a simple web page with Nginx. The idea is to show a conceptual proof of all these technologies.

Technologies used:
- AWS for the virtual machines that serve as Jenkins master, Jenkins agent and K8s cluster control-plane/worker node
- Docker to deploy the Jenkins master node
- Jenkins to create and run the pipeline
- Terraform to create the K8s node
- Ansible to provision the Kubernetes node
- Kubeadm to build the K8s cluster
- Nginx to server a static website
