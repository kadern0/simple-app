This is the project to deploy the simple-sinatra-app on AWS.

The proposed solution will build a docker container with the
application and then use Cloudformation to create a Continuous
Delivery stack on AWS that will be deploying whenever any change is
pushed to the specified GitHub repository branch.


Prerequisites:
- Local Docker installation and an user with permissions to run containers
- AWS CLI
- GitHub account and a personal token (https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/)
- IAM User with "Enough" permissions (more about this in the end of
  the Readme)

First step is to fork this repo or clone it to your GitHub
account. Once you have the code, within the repository directory, you
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

It runs an ruby:alpine image, pulls the code from the original
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
deploy the CD stack. For this, we will be using the wrapper
"stack_manager.sh". This is a simple bash script that encapsulates
some aws cli commands to make it easier to execute, still you can run
the aws commands directly if you prefer.

You will need to enable execution permissions on the file:
```
chmod +x stack_manager.sh
```

With it you can create, describe and delete the stack. You will need
following values for creating the stack:
- STACK_NAME is the name of your stack, it must be unique
- GITHUB_USER the username of the github repo where you cloned this project
- GITHUB_PROJECT name of your clone of this repo (mine is "simple-app")
- GITHUB_TOKEN personal token with access to this repo
- IMAGE_URI is the repositoryUri value from the ECR creation

Now simply run (in this order and with your own values):

```
./stack_manager.sh create STACK_NAME GITHUB_USER GITHUB_PROJECT GITHUB_TOKEN IMAGE_URI
```

In case you want to use a different branch (by default it's master)
you have to add a 'GitHubBranch' parameter to the previous command.
This should create the stack and deploy the application into Fargate
behind an Elastic Load Balancer. It takes around 7 minutes to
finish. To view the state at any time you can run:

```
./stack_manager.sh describe STACK_NAME
```

Once the stack is created, you can find the URL of the service with
following command:

```
./stack_manager.sh describe STACK_NAME | grep -A 2 ServiceUrl
```

If you open this URL from a browser or curl you should see the "Hello
World!" message.


Now, if you push new code to your repository it will get automatically
deployed. It usually takes around 4 minutes. I've left some code
commented inside the "run.sh" file for an easy and quick test.


Once you have finished testing, delete the stack by running:
```
./stack_manager.sh delete STACK_NAME
```

Note: there will be some components left in AWS, I'll talk about this
issue later.



Architecture decisions:

The main idea I had for this project was creating a docker image with
the application (running as non-root) and use any orchestrator to
deploy a service so it achieves reliability and scalability at the
same time. I also wanted to use some technologies that I hadn't used
before so I could learn during the process. After a quick look, I opted
for using AWS Fargate, Cloudformation and CodePipeline.

The service created will run behind an Application Load Balancer (it will
autoscale to meet traffic demands), that is
listening in the port 80 and will forward the requests to the
containers. 

The containers (2 by default) will be listening in the port 9292 and
will accept traffic only from the Load Balancer (no other traffic).

There are two subnets in two different AZ. And the task definition
ensures there are at least 2 containers running in every moment.



__CAVEATS__:


IAM permissions setup. According to the documentation:

https://aws.amazon.com/blogs/devops/aws-cloudformation-security-best-practices/

"By using a combination of IAM policies, users, and roles, CloudFormation-specific IAM conditions, and stack policies, you can ensure that your CloudFormation stacks are used as intended and minimize accidental resource updates or deletions."

I have been a bit "relaxed" with the IAM permissions as I didn't want
to bee dealing with policies as I saw it as an exercise, still I am
aware that each account and stack should be guaranteed the least
privileges to ensure its correct function without being able to
create any side effects.

Testing: as we all know, testing is a fundamental piece of CD
pipelines. In this case, there is no proper testing in place, if the docker container is up
and returning 2XX values, it will get deployed, still this doesn't
mean the application is returning what is expected to (Hello world! in
this case).


Cloudformation templates must be stored on an Amazon S3 bucket,
therefore I have made them public in one of my buckets. I've included
them in this repo, yet only the main.yaml file would be neccessary.


In order to create a TaskDefinition, you must specify an image,
that's why it was required manually pushing the initial image.

When you delete a stack, not everything gets deleted. Some resources
must be empty before they can be deleted. For example, you must delete
all objects in an Amazon S3 bucket. TaskDefinitions and Container
Repositories will remain in the account and have to be removed manually.



This project was inspired on this example from AWS:

https://github.com/awslabs/ecs-refarch-continuous-deployment

