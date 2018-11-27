This is the project (1 out of 2) to deploy the simple-sinatra-app.

The proposed solution will build a docker container with the
application and then use Cloudformation to create a Continuous
Delivery stack on AWS that will be deploying whenever any change is
pushed to the specified GitHub repository branch.


Prerequisites:
- Local Docker installation and an user with permissions to run containers
- AWS CLI
- GitHub account and a personal token (https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/)
- IAM User with permissions to: push and pull images from ECR

First step is to fork this repo or clone it to your GitHub
account. Once you have the code, within the repository directoy, you
can perform a quick test of the container by building it and running
it:

```
docker build . -t rea
docker run -d -p80:9292 --name rea rea
1ffded91f5ceb7872d8370b471e1c5e8dea7f9598bdc8ab9500f3cead4976e1b
```

We can verify it's running with the following command:
```
pabloc@mac$ curl localhost
Hello World!
```
Finally we can stop the container:

```
docker stop rea
```


Quick details about this container:

It runs an ruby:alpine image (, pulls the code from the original
simple-sinatra-app repo and runs the code as user frank in the port
9292.

Once the whole stack is running, every time new code gets into the
master branch (though any other branch can be specified) will be
released into AWS Fargate.



Now we have to push this docker image to the AWS container registry
(for the initial task creation). For this, you have to create an ecr
repository to store the images (give it the name you want instead of hello-world):
```
aws ecr create-repository --repository-name hello-world
```

Output (you will need the repositoryUri value for later):
```
{
    "repository": {
        "registryId": "aws_account_id",
        "repositoryName": "hello-world",
        "repositoryArn": "arn:aws:ecr:us-east-1:aws_account_id:repository/hello-world",
        "createdAt": 1505337806.0,
        "repositoryUri": "aws_account_id.dkr.ecr.REGION.amazonaws.com/hello-world"
    }
}
```
Tag the simple-app  docker image with the repositoryUri value from the
previous step.

```
docker tag rea aws_account_id.dkr.ecr.us-east-1.amazonaws.com/hello-world
```

Login to the registry by running:
```
eval $(aws ecr get-login --no-include-email)
```

You should see:
```
Login Succededed
```

Push the image to Amazon ECR with the repositoryUri value from the earlier step.
```
docker push aws_account_id.dkr.ecr.REGION.amazonaws.com/hello-world

```

Now that we have the image available in our repository we are going to
deploy the CD stack. For this, we will be using the second repository:

https://github.com/kadern0/fargate-stack

In this repository reside all the Cloudformation templates that will
create the neccessary resources for this project. Clone this
repository and cd into it. From here you will only have to create the
stack from the main.yaml file, but for this to work, you have to set
some variables first. Run the folling by replacing the 'xxx' with your
own values:


```
# This is the name of your stack, it must be unique
STACK_NAME=xxx
# Your GitHub username
GITHUB_USER=xxx
# Repository where you cloned the simple-app repo
GITHUB_REPO=xxx
# Personal GitHub token
GITHUB_TOKEN=xxx
# This is the repositoryUri value from the ECR creation
IMAGE_URI=xxx

```

Now simply run

```
aws cloudformation create-stack --stack-name $STACK_NAME --template-body \
file://main.yaml  --parameters \
ParameterKey=GitHubUser,ParameterValue=$GITHUB_USER \
ParameterKey=GitHubToken,ParameterValue=$GITHUB_TOKEN \
ParameterKey=GitHubRepo,ParameterValue=$GITHUB_REPO \
ParameterKey=ImageUrl,ParameterValue=$IMAGE_URI \
--capabilities CAPABILITY_IAM
```

This should create the stack and deploy the application into Fargate
behind an Elastic Load Balancer. It takes around 7 minutes to
finish. After this time, you can run:

```
aws cloudformation describe-stacks --stack-name $STACK_NAME 
```

To view the state. From there you can find the URL of the service with
following command:

```
aws cloudformation describe-stacks --stack-name $STACK_NAME | grep -A 2 ServiceUrl
```

If you open this URL from a browser or curl you should see the "Hello
World!" message.


Now, if you push new code to your repository it will get automatically
deployed. It usually takes around 4 minutes. I've left some code
commented inside the run.sh file for an easy and quick test.


Once you have finished testing, delete the stack by running:
```
aws cloudformation delete-stack --stack-name $STACK_NAME
```

Note: there will be some components left in AWS, I'll talk about this
issue later.



Architecture decisions:

The main idea I had for this project was creating a docker image with
the application (running as non-root) and use any orchestrator to
deploy a service so it achieves reliability and scalability at the
same time. I also wanted to use some technologies that I hadn't used
before so I could learn during the process. After a quick look, I opted
for using AWS Fargate, Cloudformation, CodePipeline (if you know what they are
skip the next 4 paragraphs).

AWS Fargate is a compute engine for Amazon ECS that allows you to run containers without having to manage servers or clusters. With AWS Fargate, you no longer have to provision, configure, and scale clusters of virtual machines to run containers. This removes the need to choose server types, decide when to scale your clusters, or optimize cluster packing. AWS Fargate removes the need for you to interact with or think about servers or clusters. Fargate lets you focus on designing and building your applications instead of managing the infrastructure that runs them.

AWS CloudFormation provides a common language for you to describe and
provision all the infrastructure resources in your cloud
environment. CloudFormation allows you to use a simple text file to
model and provision, in an automated and secure manner, all the
resources needed for your applications across all regions and
accounts. This file serves as the single source of truth for your
cloud environment.

AWS CodePipeline is a continuous delivery service you can use to
model, visualize, and automate the steps required to release your
software. You can quickly model and configure the different stages of
a software release process. AWS CodePipeline automates the steps
required to release your software changes continuously. 

The service created will run behind an Application Load Balancer (it will
autoscale to meet traffic demands), that is
listening in the port 80 and will forward the requests to the
containers. 

The containers (2 by default) will be listening in the port 9292 and
will accept traffic only from the Load Balancer (no other traffic).

There are two subnets in two different AZ. And the task definition
ensures there are at least 2 containers running in every moment.



CAVEATS:

I have been a bit "relaxed" with the IAM permissions as I didn't want
to bee dealing with policies as I saw it as an exercise. In addition to AWS CloudFormation permissions, you must be
allowed to use the underlying services, such as Amazon S3 and others. 

Cloudformation templates must be stored on an Amazon S3 bucket,
therefore I have made them public in one of my buckets.


I was getting this error when starting the container:
```
CannotStartContainerError: API error (400): OCI runtime create failed: container_linux.go:348: starting container process caused "exec: \"/run.sh\": permission denied": unknown 
```

Random stackoverflow guy happened to have the same problem and he
fixed it by putting this inside the Dockerfile entrypoint:
```
ENTRYPOINT ["/bin/ash","-c","chmod a+x /run.sh && /run.sh"]
```


When you delete a stack, not everything gets deleted. Some resources
must be empty before they can be deleted. For example, you must delete
all objects in an Amazon S3 bucket. TaskDefinitions and Container
Repositories will remain in the account and have to be removed manually.



This project was inspired on this example from AWS:

https://github.com/awslabs/ecs-refarch-continuous-deployment

