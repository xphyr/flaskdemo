// path of the template to use
def templatePath = 'https://github.com/xphyr/flaskdemo'
// name of the template that will be created
def templateName = 'flaskdemo'
// NOTE, the "pipeline" directive/closure from the declarative pipeline syntax needs to include, or be nested outside,
// and "openshift" directive/closure from the OpenShift Client Plugin for Jenkins.  Otherwise, the declarative pipeline engine
// will not be fully engaged.
pipeline {
    agent none
    options {
        // set a timeout of 20 minutes for this pipeline
        timeout(time: 20, unit: 'MINUTES')
    }

    stages {
        stage('preamble') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject('flaskdemo') {
                            echo "Using project: ${openshift.project()}"
                        }
                    }
                }
            }
        }
        stage('cleanup') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject('flaskdemo') {
                            // delete everything with this template label
                            openshift.selector("all", [ template : templateName ]).delete()
                            // delete any secrets with this template label
                            if (openshift.selector("secrets", templateName).exists()) {
                                openshift.selector("secrets", templateName).delete()
                            }
                        }
                    }
                } // script
            } // steps
        } // stage

        stage('database setup'){
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject('flaskdemo') {
                            if (!openshift.selector("dc", "mongodb").exists()) {
                                openshift.newApp("mongodb-ephemeral", "-p MONGODB_DATABASE=mongodb")
                            }
                        }
                    }
                }  
            }
        }

        stage('create') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject('flaskdemo') {
                            if (openshift.selector("bc", templateName).exists()) {
                                openshift.selector("bc", templateName).startBuild();
                            }
                            else {
                                // create a new application from the templatePath
                                openshift.newApp(templatePath, "--strategy=docker").narrow('svc').expose();
                                // now update the deployment to have the mongodb secrets
                                def deploymentPatch = [
                                        "metadata":[
                                            "name":"flaskdemo",
                                            "namespace":"flaskdemo"
                                        ],
                                        "apiVersion":"apps/v1",
                                        "kind":"Deployment",
                                        "spec":[
                                            "template":[
                                                "metadata":[:],
                                                "spec":[
                                                    "containers":[
                                                        ["name":"flaskdemo",
                                                         "resources":[:],
                                                         "envFrom":[
                                                            ["secretRef": [
                                                                "name": "mongodb"
                                                            ]
                                                            ]
                                                          ]
                                                        ]
                                                    ]
                                                ]
                                            ]
                                        ]
                                    ]
                                openshift.apply(deploymentPatch)
                            }
                        }
                    }
                } // script
            } // steps
        } // stage
        stage('build') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject('flaskdemo') {
                            def builds = openshift.selector("bc", templateName).related('builds')
                            builds.untilEach(1) {
                                return (it.object().status.phase == "Complete")
                            }
                        }
                    }
                } // script
            } // steps
        } // stage
        stage('deploy') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject('flaskdemo') {
                            // def rm = openshift.selector("deploy", templateName).rollout()
                            openshift.selector("pod", [deployment : "${templateName}"]).untilEach(1) {
                                return (it.object().status.phase == "Running")
                            }
                        }
                    }
                } // script
            } // steps
        } // stage
        /* - we will remove this later
        stage('Tag for Staging') {
            steps {
                script {
                    openshift.withCluster() {
                        // openshift.withProject('flaskdemo') {
                            openshift.tag("flaskdemo/${templateName}:latest", "flaskstaging/${templateName}-staging:latest")
                        // }
                    }
                } // script
            } // steps
        } // stage
        stage ('Create Staging Deployment') {
            when {
                expression {
                    openshift.withCluster() {
                        openshift.withProject('flaskstaging') {
                            return !openshift.selector("pod", [deployment : "${templateName}-staging"]).exists()
                        }
                    }
                }
            }
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject('flaskstaging') {
                            openshift.newApp("mongodb-ephemeral", "-p MONGODB_DATABASE=mongodb")
                            openshift.newApp("${templateName}-staging:latest").narrow('svc').expose()
                            def deploymentPatch = [
                                        "metadata":[
                                            "name":"flaskdemo-staging",
                                            "namespace":"flaskstaging"
                                        ],
                                        "apiVersion":"apps/v1",
                                        "kind":"Deployment",
                                        "spec":[
                                            "template":[
                                                "metadata":[:],
                                                "spec":[
                                                    "containers":[
                                                        ["name":"flaskdemo-staging",
                                                         "resources":[:],
                                                         "envFrom":[
                                                            ["secretRef": [
                                                                "name": "mongodb"
                                                            ]
                                                            ]
                                                          ]
                                                        ]
                                                    ]
                                                ]
                                            ]
                                        ]
                                    ]
                                sleep(10)
                            openshift.apply(deploymentPatch)
                        }
                    }
                }
            }
        }
        stage('Validate Staging') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject('flaskstaging') {
                            // def rm = openshift.selector("deploy", templateName).rollout()
                            openshift.selector("pod", [deployment : "${templateName}-staging"]).untilEach(1) {
                                return (it.object().status.phase == "Running")
                            }
                        }
                    }
                } // script
            } // steps
        } // stage
        stage('Promote to Production') {
            steps {
                input "Shall we promote to production?"
            }
        }
        stage('Tag for Promotion') {
            steps {
                script {
                    openshift.withCluster() {
                        // openshift.withProject('flaskdemo') {
                            openshift.tag("flaskdemo/${templateName}:latest", "flaskproduction/${templateName}-production:latest")
                        // }
                    }
                } // script
            } // steps
        } // stage
        stage ('Create Production Deployment') {
            when {
                expression {
                    openshift.withCluster() {
                        openshift.withProject('flaskproduction') {
                            return !openshift.selector("pod", [deployment : "${templateName}-production"]).exists()
                        }
                    }
                }
            }
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject('flaskproduction') {
                            openshift.newApp("mongodb-ephemeral", "-p MONGODB_DATABASE=mongodb")
                            openshift.newApp("${templateName}-production:latest").narrow('svc').expose()
                            def deploymentPatch = [
                                        "metadata":[
                                            "name":"flaskdemo-production",
                                            "namespace":"flaskproduction"
                                        ],
                                        "apiVersion":"apps/v1",
                                        "kind":"Deployment",
                                        "spec":[
                                            "template":[
                                                "metadata":[:],
                                                "spec":[
                                                    "containers":[
                                                        ["name":"flaskdemo-production",
                                                         "resources":[:],
                                                         "envFrom":[
                                                            ["secretRef": [
                                                                "name": "mongodb"
                                                            ]
                                                            ]
                                                          ]
                                                        ]
                                                    ]
                                                ]
                                            ]
                                        ]
                                    ]
                                sleep(10)
                            openshift.apply(deploymentPatch)
                        }
                    }
                }
            }
        }
        stage('Validate Production') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject('flaskproduction') {
                            // def rm = openshift.selector("deploy", templateName).rollout()
                            openshift.selector("pod", [deployment : "${templateName}-production"]).untilEach(1) {
                                return (it.object().status.phase == "Running")
                            }
                        }
                    }
                } // script
            } // steps
        } // stage
        we will remove this line later */
    } // stages
} // pipeline