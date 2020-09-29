# Using an Operator to Deploy and Manage MongoDB

The primary instructions found in the README.md file use OpenShift Templates to instantiate a ephemeral MongoDB. But what if you are looking to do something a little more production like. One way to achieve this is to use an Operator to manage your MongoDB instances.

## Installing the Operator

We will use the [Percona Server MongoDB Operator](https://www.percona.com/software/percona-kubernetes-operators) for this demo, and will use the built in Operator Hub within your OpenShift cluster to install it.

1. Log into your OpenShift cluster as a Cluster Admin.
2. Select Operators->Operator Hub
3. Using the search tool look for "Percona" and select the Community version of "Percona Server MongoDB Operator"
4. Select "Install" and ensure that "All namespaces on the cluster" is selected and click Install

At this point the Operator will be installed on your cluster and made ready for use.

