# Jenkins-Django-AWS

+ Add the environment varaibles in the jenkins console and update the corresponding variable name in the pipeline. Variables should be project specific.

```
APP_NAME_AWS_SECRET_MANAGER : AWS secrets manager ARN
APP_NAME_AWS_REGION : AWS region
APP_NAME_AWS_IMAGE_NAME : AWS ECR IMAGE ARN
APP_NAME_AWS_IMAGE_TAG : AWS ECR IMAGE TAG NAME
APP_NAME_AWS_ACCOUNT_ID : AWS ACCOUNT ID
APP_NAME_SERVER : Server IP/Domain name
AWS_CREDENTIALS_ID : Name of the AWS credential ID added in the jenkins console.
```

+ Variables used in the pipeline should be updated based on the usuage, use separate variable in case multi branch configuration is needed. 

### Stage 1: Unit test and code coverage
+ Stage for unit test cases should only be used if its setup in the code by the developers. 

+ In that case move the env file creation from secrets manager to another stage(stage 4).

+ Builds the docker image and uses the image with dev server docker compose file to run the test cases.

+ Db created 

### Stage 2: SonarQube analysis
+ Sonarqube analysis stage is mandatory for staging/dev server. Not needed for other branches.

+ Run analysis with sonar scannar and update the result in the sonarqube server.


### Stage 3: Update docker image

+ Push docker image to AWS ECR.

### Stage 4: Update server configs

+ Copy env file to the server.

+ Copy docker compose file to the server.

### Stage 5: Update server

+ SSH to the server and rebuild the containers with new docker image.

+ Run management commmands migrate and collectstatic.

+ Clear old images from the server.

+ Clear old images from the jenkins server.

+ Send build status to the slack channel.


