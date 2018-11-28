#!/bin/bash


if [ $# -ge 1 ];then

    case $1 in
        "create")
            if [ $# -ne 6 ];then

                echo "ERROR: Missing parameters!"
                echo "Syntax: ${0} create STACK_NAME GITHUB_USER GITHUB_TOKEN GITHUB_REPO IMAGE_URI"
                exit 1
                
            fi
            echo "CREATING STACK"
            $(which aws) cloudformation create-stack --stack-name $2 --template-body \
                         file://cloudformation/main.yaml  --parameters \
                         ParameterKey=GitHubUser,ParameterValue=$3 \
                         ParameterKey=GitHubToken,ParameterValue=$4 \
                         ParameterKey=GitHubRepo,ParameterValue=$5 \
                         ParameterKey=ImageUrl,ParameterValue=$6 \
                         --capabilities CAPABILITY_IAM

            ;;
        "delete")
            if [ $# -ne 2 ];then

                echo "ERROR: Missing parameters!"
                echo "Syntax: ${0} delete STACK_NAME"
                exit 1
                
            fi
            
            echo "DELETING STACK"
            $(which aws) cloudformation delete-stack --stack-name $2
            ;;
        "describe")
            if [ $# -ne 2 ];then

                echo "ERROR: Missing parameters!"
                echo "Syntax: ${0} describe STACK_NAME "
                exit 1
                
            fi
            $(which aws) cloudformation describe-stacks --stack-name $2
            ;;
        *)
            echo "Syntax: $0 [create|delete|describe] <PARAMS> "
            ;;
    esac
else
    echo "Syntax: $0 [create|delete|describe] <PARAMS>"
fi
