# AppInCloud
**Application in Cloud** - Creates a managed infrastructure on AWS (Amazon Web Services) to host your application, so you can focus on Application development.

------------
Cloudformation Stacks
------------

**Network:** Dedicated VPC, Private/Public Subnets.  
**Database:** Aurora MySQL Database, Metrics and Alarms, Daily Snapshots.  
**Application:** Metric based autoscaling, rolling deployments, application versioning.  
**Bastion:** Security focused, single access point into the network.  
**Continuous Deployment:**  Code pipeline, Commit, Test, Build and Deploy automaticaly.  

------------
Deployment
------------

Install and configure [aws-cli](https://github.com/aws/aws-cli) on a linux instance with AWSAdministrator access.  
[Clone](https://github.com/bryanlabs/appincloud.git) or [download](https://github.com/bryanlabs/appincloud/archive/master.zip) this repository to your instance.  
Modify deployment variables in deploy.sh  
* **APPNAME:** unique name to identify APP and all AWS resources associated with it.  
* **STACKTYPE:** The web application platform (node, rails, spring, python, python3).  
* **S3BUCKET:** a globally unique bucketprefix name for storing deployment configurations.  
* **EC2KeyPairName:** the name of an EC2 Keypair pre-existing in your environment.  
* **DBPASSWORD:** Password for the database, alphanumerical.  


------------
Post Deployment
------------
 
* Once deployed the Environment URL and SSHCloneURL will be displayed.  
* Configure your iam user [access to codecommit](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_ssh-keys.html).  
* Clone your new environment and modify buidspec.yml to build and test your application. 
* Any change commited will be ran though buildspec, and deployed to elastic beanstalk. 
* Once built and deployed, you can access your application from the Environment URL.

