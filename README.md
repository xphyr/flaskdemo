# flaskdemo

The following repo can be used to test out Jenkins CI/CD pipeline within an OpenShift 4.x cluster. We will leverage a Jenkins install running inside OpenShift but the instructions should work for an external Jenkins server as well, with the [Jenkins Client Plugin](https://github.com/openshift/jenkins-client-plugin) installed.

This is a pseudo-fork of the code from here [Simple Python Flask Program with MongoDB](https://www.codeproject.com/Articles/1255416/Simple-Python-Flask-Program-with-MongoDB). I needed a simple to understand flask application that uses MongoDB for creating a Jenkins/OpenShift pipeline demo. The original code can be found here: https://github.com/sarathlalsaseendran/FlaskWithMongoDB and is licensed under the [CPOL](https://www.codeproject.com/info/cpol10.aspx)

This application also requires a MongoDB database running to store the tasks you add to the application. We will deploy an ephemeral MongoDB server as part of this pipeline, and include the authentication as part of the application deployment.

## Dockerfile

For our Python3 based Flask application, there is no build/compile step for the code itself, but we do need to prepare the container with the requirements for Flask. This can be done by leveraging the requirements.txt file and then copying the application Python files into the container. The Dockerfile builds on the UBI8 base images from Red Hat.

## Setting up the Jenkins Server in OpenShift

To set up for this demo, we will be creating four projects in your cluster:

1. cicd - this will run the Jenkins server
2. flaskdemo - this will be the development project
3. flaskstaging - this will be the integration testing project
4. flaskproduction - this will be the production instance of our app

Run the following commands on your machine to get the environment set up

```
oc login
oc new-project cicd --display-name='CICD Jenkins' --description='CICD Jenkins'
oc new-app jenkins-ephemeral
# use "oc status" to watch the deployment of the jenkins server and wait for it to complete
# use the "oc get route" command to record the URL for jenkins and record this for future use
oc get route
oc new-project flaskdemo --display-name='Flask Demo' --description='Flask Demo'
oc new-project flaskstaging --display-name='Staging' --description='Staging'
oc new-project flaskproduction --display-name='Production' --description='Production'
```

We need to give the Jenkins service account permissions to edit configurations in our target projects:

```
oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins \
    -n flaskdemo
oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins \
    -n flaskstaging
oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins \
    -n flaskproduction
```

## Setting up your development environment

Now that we have Jenkins setup in your cluster, lets start by cloning the following github repo: https://github.com/xphyr/flaskdemo and checkout a copy of the code local to your machine.

In your favorite code editor, update line 2 in the Jenkins file to point to YOUR github repo:

```
def templatePath = 'https://github.com/xphyr/flaskdemo'
```

Also update the URI reference in the flask_pipeline_bc.yaml to point to your github repo as well:

```
    git:
        uri: https://github.com/xphyr/flaskdemo
```

Before moving onto the next steps, commit the changes above to your repo:

```
git commit -am "updating to point to my repo"
git push
```

## Deploying the flask application

Assuming that you have committed your changes as outlined above, we can now deploy the application. There are two ways to configure this application build. The first is to use an OpenShift Jenkins Build strategy. The Jenkins Build Strategy is a way to create a Jenkins job in an OpenShift hosted Jenkins server with some yaml. This is a quick way to create a Jenkins job but as of OpenShift 4.5 is [deprecated](https://docs.openshift.com/container-platform/4.5/builds/build-strategies.html#builds-strategy-pipeline-build_build-strategies) It is documented here for completeness, and does still work. However it is suggested that you follow the instructions labeled "Deploying Using Jenkins Pipeline UI" for long term support.

### Deploying Using Jenkins Build Strategy
  Switch to the cicd project and create the buildconfig from the file you edited earlier:

```
oc project cicd
oc create -f flask_pipeline_bc.yaml
```

Using the Jenkins URI you gathered from the Jenkins Setup instructions, log into Jenkins.  You should find a folder called "cicd", select that and you should now have a pipeline called "cicd/flask-sample-app-pipeline".

### Deploying Using Jenkins Pipeline UI

Using the Jenkins URI you gathered from the Jenkins Setup instructions, log into Jenkins. 
1. Select New Item
2. Enter "FlaskDemo" and select "Pipeline Project" then Click OK
3. Under "Pipeline" select "Pipeline from SCM"
4. Under SCM select "Git"
5. Enter YOUR repository URL (eg: `https://github.com/xphyr/flaskdemo` )
6. Ensure that "Lightweight checkout" is NOT checked
   (in order to properly use scm polling you can not use Lightweight checkout)
7. Click Save

### Building your application

Now that you have created your Jenkins job (either via a build config, or via the Jenkins GUI) we can build the application. Select the build (either cicd/flask-sample-app-pipeline, or FlaskDemo) and click "Build Now".

Once the build completes successfully, we need to get the route to access the application. Run the following command:

```
oc get route -n flaskdemo
```

Now open a web browser using the route from the command above and access your development application, with Mongo Database. Try it out, add some tasks to the application, and mark some of them complete. Leave this page open, we will use it again shortly.

### Update the Pipeline configuration to poll the SCM

1. Log into Jenkins using the URL from the Jenkins setup, and select your pipeline.
2. Select "configure"
3. Under "Build Triggers" select "Poll SCM"
4. Enter the following for the schedule to check every 5 minutes for updates
   `H/5 * * * * `
5. Click Save

### Making changes to your application

Now that we have a build pipeline set up, lets make a small change to the application and watch it build and deploy for us automatically.

In your favorite editor, open app.py and edit line 8. Update the heading variable so that it has your name in it as shown below:

```
heading = "TODO Reminder with Flask and MongoDB - by YourNameHere"
```

Go ahead and commit this change to your repo `git commit -am "updating source" && git push` and then open your jenkins build pipeline and watch. Within 5 minutes a new build should kick off and your application. When the build completes refresh your application web page and see that the message has been updated.

### Bringing it all together

So now we have a pipeline that will watch for code changes and promote those changes in to our Development deployment, but what if we want to take this further? We can make this a multi-stage pipeline, promoting the code into a Staging environment, and finally after human approval, into Production.

Edit your Jenkins file and remove two lines from the file (lines 131 and 285):
* "    /* - we will remove this later"
* "        we will remove this line later */"

this will enable the additional build stages, commit this code to your rep and watch your Jenkins job. Go ahead and commit your changes to the Jenkins file and push to github. Log into Jenkins and follow along as you have two new build stages.  Note that the pipeline will pause at the "Promote to Production" stage, looking for approval from you to push the code to production. Click approve and let the pipeline finish.

As part of the pipeline we create a staging route and a production route, go get each of these routes and open in new windows:

```
oc get route -n flaskstaging
oc get route -n flaskproduction
```

For each route you got above you should now see a web page for "Staging" and one for "Production".  Go ahead and change the message in app.py one more time and commit/push your change and check to see that the change is propagated all the way through your new pipeline.

## Local Setup and Testing - Optional

If you want to do any local testing, the following steps can be used to test locally on a machine with Docker.  Note that this assumes the use of Python3 for setting up a venv.  

```
git clone
cd flaskdemo
python -m venv venv
. venv/bin/activate
pip install -r requirements.txt
docker run -d -p 27017:27017 -v ~/data:/data/db --name mongodb mongo
python app.py
```