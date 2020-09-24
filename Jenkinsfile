// path of the template to use
def templatePath = 'https://github.com/xphyr/flaskdemo'
// name of the template that will be created
def templateName = 'flaskdemo-app'
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
                        openshift.withProject('flask') {
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
                        openshift.withProject('flask') {
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

        stage('create') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject('flask') {
                            if (openshift.selector("bc", templateName).exists()) {
                                openshift.selector("bc", templateName).startBuild();
                            }
                            else {
                                // create a new application from the templatePath
                                openshift.newApp(templatePath, "--strategy=docker").narrow('svc').expose();
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
                        openshift.withProject('flask') {
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
                        openshift.withProject('development') {
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
                        // openshift.withProject('development') {
                            openshift.tag("development/${templateName}:latest", "testing/${templateName}-staging:latest")
                        // }
                    }
                } // script
            } // steps
        } // stage
        stage ('Create Testing Deployment') {
            when {
                expression {
                    openshift.withCluster() {
                        openshift.withProject('testing') {
                            return !openshift.selector("pod", [deployment : "${templateName}-staging"]).exists()
                        }
                    }
                }
            }
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject('testing') {
                            openshift.newApp("${templateName}-staging:latest").narrow('svc').expose()
                        }
                    }
                }
            }
        }
        stage('Validate Staging') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject('testing') {
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
                input "Shal we promote to production"
            }
        }
        stage('Tag for Promotion') {
            steps {
                script {
                    openshift.withCluster() {
                        // openshift.withProject('development') {
                            openshift.tag("development/${templateName}:latest", "production/${templateName}-production:latest")
                        // }
                    }
                } // script
            } // steps
        } // stage
        stage ('Create Production Deployment') {
            when {
                expression {
                    openshift.withCluster() {
                        openshift.withProject('production') {
                            return !openshift.selector("pod", [deployment : "${templateName}-production"]).exists()
                        }
                    }
                }
            }
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject('production') {
                            openshift.newApp("${templateName}-production:latest").narrow('svc').expose()
                        }
                    }
                }
            }
        }
        stage('Validate Production') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject('production') {
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