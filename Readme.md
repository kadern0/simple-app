CannotStartContainerError: API error (400): OCI runtime create failed: container_linux.go:348: starting container process caused "exec: \"/run.sh\": permission denied": unknown 
dd
aaaa
$ aws ecr get-login — no-include-email

$ docker login -u AWS -p ...
Login Succeeded




$ cd $VOTEAPP_ROOT/src/worker
$ docker build -t worker .
$ docker tag worker 654814900965.dkr.ecr.us-east-1.amazonaws.com/worker
$ docker push 654814900965.dkr.ecr.us-east-1.amazonaws.com/worker




AWS Fargate is a technology that you can use with Amazon ECS to run containers without having to manage servers or clusters of Amazon EC2 instances. With AWS Fargate, you no longer have to provision, configure, or scale clusters of virtual machines to run containers. This removes the need to choose server types, decide when to scale your clusters, or optimize cluster packing.

When you run your tasks and services with the Fargate launch type, you package your application in containers, specify the CPU and memory requirements, define networking and IAM policies, and launch the application. Each Fargate task has it's own isolation boundary and does not share the underlying kernel, CPU resources, memory resources, or elastic network interface with another task. 



Service-Linked role for ECS
The IAM entity that is creating the cluster must have the appropriate IAM permissions to create the service-linked role and apply a policy to it. Otherwise, the automatic creation fails. 
