# Using an External Jenkins Server

The primary README file in this repo leverages a Jenkins server hosted inside OpenShift. It is also possible to use an external Jeknins server to run these labs. If you have an existing Jenkins server follow these steps to properly configure your server.

## OpenShift Configuration

In order to allow your Jenkins server to interact with your OpenShift cluster, you will need to create a Service Account (SA) and grant it the proper permissions on your cluster, or on individual projects. Follow the steps below to configure the Service Account:

1) Log into your OpenShift Cluster with Cluster Admin permissions
`oc login <cluster api address>`
2) Create a new project to contain the Service Account
`oc new-project jenkinsremote`
3) Create a new service account
`oc create sa jenkinsremote`
4) List the service account details  
`oc describe serviceaccount jenkinsremote`
5) Using the information from step 4, get one of the account tokens from the secret
`oc describe secret jenkinsremote-token-<random letters here>`
Be sure to copy the entire "token" listed in the above output. We will require this later

We now need to make a decision, do you want Jenkins to have full control of your entire cluster, or do you want to limit it to specific Project namespaces? Limiting the Jenkins server to specific Projects allows more control of the cluster but will require additional configuration each time a new Project is created that you want Jenkins to have control of.

### Cluster wide permissions

It is possible to give your remote Jenkins server the ability to create and destroy Projects within your cluster. In order to do this we will give the Jenkins SA account the "self-provisioner" role. This will allow Jenkins to create projects on its own, and will assign ownership of those projects to the Jenkins SA account.

```
oc policy add-role-to-user self-provisioner system:serviceaccount:jenkinsremote:jenkinsremote
```

### Project specific permissions

We now need to give the "jenkinsremote" service account permissions on the specific projects you wish to use. Assuming you are following the lab listed in this repo's README you will need to run the following commands:

```
oc policy add-role-to-user edit system:serviceaccount:jenkinsremote:jenkinsremote \
    -n flaskdemo
oc policy add-role-to-user edit system:serviceaccount:jenkinsremote:jenkinsremote \
    -n flaskstaging
oc policy add-role-to-user edit system:serviceaccount:jenkinsremote:jenkinsremote \
    -n flaskproduction
```

## Jenkins Configuration

Now that we have properly configured our OpenShift cluster for a remote Jenkins server we now need to configure the Jenkins server.  We will start with installing the OpenShift plugin, and then configure the plugin for remote use.

1. Log into Jenkins as an Admin user
2. Select "Manage Jenkins"
3. Select "Manage Plugins"
4. Select the "Available Plugins" tab
5. Enter "OpenShift Client" in the search area and hit Enter
6. Select the "OpenShift Client Jenkins Plugin" and click "Install after Restart"
7. Follow the prompts, and restart Jenkins to complete the install
8. Log back into Jenkins as an Admin
9. Select "Manage Jenkins"
10. Select "Configure System"
11. Find the "OpenShift" configuration section
12. Enter a name for your cluster (eg. "CICDDemo" )
13. Enter the API Server URL (eg. "https://api.mycluster.demo.net:6443" )
14. Select "Add" for your credentials
    1.  Using the dropdown, select the "OpenShift Token for OpenShift Client Plugin" _Kind_
    2.  Enter the token for the jenkinsremote SA account we created above
    3.  Give your token an ID and description 
    4.  Click **Add**
15. Ensure that the token you just created is selected
16. If your cluster is using a self signed certificate, be sure to check "Disable TLS Verify"
17. Click Save

Your Jenkins server is now configured to use the OpenShift Client plugin. Be sure that the "oc" command is available on your Jenkins workers or the plugin will fail to run.

## Using a remote Jenkins Server

We will use the files in this repo as a test run. The Jenkinsfile will need slight modification as we must now call out the name of the OpenShift cluster we want to connect to. The command below will assume you called your OpenShift cluster "CICDDemo". Update the Jenkinsfile replacing all instances of 'openshift.withCluster()' with 'openshift.withCluster("CICDDemo")' and commit this updated Jenkinsfile to your repo.

Now in Jenkins lets create a new job.
1. Log into Jenkins and select "New Item"
2. Enter "FlaskDemo" and select "Pipeline Project" then Click OK
3. Under "Pipeline" select "Pipeline from SCM"
4. Under SCM select "Git"
5. Enter YOUR repository URL (eg: `https://github.com/xphyr/flaskdemo` )
6. Ensure that "Lightweight checkout" is NOT checked
   (in order to properly use scm polling you can not use Lightweight checkout)
7. Click Save

You should now be able to run a build by selecting "Build Now"
