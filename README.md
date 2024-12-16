# helm-chart-ocp-cluster-roles

demo Suisse requires to create additional roles to control OpenShift accesses more granularly.
This helm chart configures all cluster roles that are required to manage cluster access levels.

## ClusterRoles

| ClusterRole | clusterRoleSelectors |
| ------------ | ----------- |
| ocp-cluster-maintenance | `rbac.authorization.k8s.io/aggregate-to-ocp-cluster-maintenance: 'true'` |
| ocp-cluster-monitoring | `rbac.authorization.k8s.io/aggregate-to-ocp-cluster-monitoring: 'true'` |
| ocp-edit | `rbac.authorization.k8s.io/aggregate-to-ocp-edit: 'true'` |
| ocp-edit-restricted | `rbac.authorization.k8s.io/aggregate-to-ocp-edit-restricted: 'true'` |
| ocp-view | `rbac.authorization.k8s.io/aggregate-to-ocp-view: 'true'` |
| ocp-view-restricted | `rbac.authorization.k8s.io/aggregate-to-ocp-view-restricted: 'true'` |


## Custom role creation process

This chapter contains an overview of the custom role creation process.

### Create a role using `oc create`

The `oc create clusterrole` allows you to create a custom role by providing verbs(Action) and resources(Object). You may find some simple examples by `oc create clusterrole -h`. The following example creates a role named `podviewonly` which will only allow a user to get list of pods.

```
$ oc create clusterrole podviewonly --verb=get --resource=pod

$ oc get clusterrole podviewonly -o yaml

apiVersion: authorization.openshift.io/v1
kind: ClusterRole
metadata:
  name: podviewonly
  resourceVersion: "358441"
  selfLink: /apis/authorization.openshift.io/v1/clusterroles/podviewonly
  uid: 3cfb3013-bdc7-11e9-8884-005056bf1bc7
rules:
- apiGroups:
  - ""
  attributeRestrictions: null
  resources:
  - pods
  verbs:
  - get
```

You may specify multiple verbs and resources. The following example creates a ClusterRole named "foo" with API Group specified

```
oc create clusterrole foo --verb=get,list,watch --resource=rs.extensions
```

You may also use subresources:

```
$ oc create clusterrole foo --verb=get,list,watch --resource=pods,pods/status

$  oc get clusterrole foo -o yaml
apiVersion: authorization.openshift.io/v1
kind: ClusterRole
metadata:
  name: foo
  resourceVersion: "358645"
  selfLink: /apis/authorization.openshift.io/v1/clusterroles/foo
  uid: 65295980-bdc7-11e9-8884-005056bf1bc7
rules:
- apiGroups:
  - ""
  attributeRestrictions: null
  resources:
  - pods
  - pods/status
  verbs:
  - get
  - list
  - watch
```

### Using `oc --loglevel`

You need to know actions/resources to create a custom role. `oc --loglevel` may allow you to identify both resource and actions(verbs). The following example shows all pods in the current project. The debug information contains resoure and verb required for role creation.

```
oc --loglevel 6 get pod

OMITTED

I0813 08:30:59.126869  108253 round_trippers.go:405] GET https://usld3001270.am.hedani.net:443/api/v1/namespaces/kube-system/pods?limit=500 200 OK in 21 milliseconds

OMITTED
```

So the example above tries to access resource type "pods" by "get" action.

The following example requires get and log actions on the pods resources.

```
oc --loglevel 6 logs router-1-7xv4f

OMITTED

I0813 08:34:02.924478  112250 round_trippers.go:405] GET https://usld3001270.am.hedani.net:443/api/v1/namespaces/default/pods/router-1-7xv4f 200 OK in 26 milliseconds

OMITTED

I0813 08:34:03.119218  112250 round_trippers.go:405] GET https://usld3001270.am.hedani.net:443/api/v1/namespaces/default/pods/router-1-7xv4f/log 200 OK in 163 milliseconds
```

### Create a role using an existing role

Despite it is possible to create a new role from scratch, it is recommended to create custom roles from existing OpenShift roles. There is a number of standard roles like 'view','edit', etc.
If you need to create a custom role using existing roles you may perform the following steps:

- Export existing role to a file.

```
$ oc export clusterrole view > view.yml
$ cp view.yml newrole.yml

$ cat newrole.yml

aggregationRule:
  clusterRoleSelectors:
  - matchLabels:
      rbac.authorization.k8s.io/aggregate-to-view: "true"
apiVersion: authorization.openshift.io/v1
kind: ClusterRole
metadata:
  annotations:
    openshift.io/description: A user who can view but not edit any resources within
      the project. They can not view secrets or membership.
    openshift.io/reconcile-protect: "false"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: view
rules:
- apiGroups:
  - ""
  attributeRestrictions: null
  resources:
  - configmaps
  - endpoints
  - persistentvolumeclaims
  - pods
  - replicationcontrollers
  - replicationcontrollers/scale
  - serviceaccounts
  - services
  verbs:
  - get
  - list
  - watch


OMITTED
```

- Remove all Runtime information
The runtime information is specific to particular cluster and needs to be remove in in role template file. This includes metadata.resourceVersion, metadata.creationTimestamp, metadata.selfLink, metadata.uid. In the following examples all changes are commented out by "#" to help you to identify lines to remove.

```
aggregationRule:
  clusterRoleSelectors:
  - matchLabels:
      rbac.authorization.k8s.io/aggregate-to-view: "true"
apiVersion: authorization.openshift.io/v1
kind: ClusterRole
metadata:
  annotations:
    openshift.io/description: A user who can view but not edit any resources within
      the project. They can not view secrets or membership.
    openshift.io/reconcile-protect: "false"
#  creationTimestamp: null
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: view
rules:

OMITTED
```

- Remove aggregationRule

In most cases you do not need to use aggregationRule. You may find additional information on [K8S documenation portal](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)

```
#aggregationRule:
#  clusterRoleSelectors:
#  - matchLabels:
#      rbac.authorization.k8s.io/aggregate-to-view: "true"
apiVersion: authorization.openshift.io/v1
kind: ClusterRole
metadata:
  annotations:
    openshift.io/description: A user who can view but not edit any resources within
      the project. They can not view secrets or membership.
    openshift.io/reconcile-protect: "false"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: view
rules:

OMITTED
```

- Modify role name at metadata.name and role description at metadata.annotations.openshift.io/description

```
apiVersion: authorization.openshift.io/v1
kind: ClusterRole
metadata:
  annotations:
    openshift.io/description: A user who can view but not edit any resources within
      the project. They can not view secrets or membership.
    openshift.io/reconcile-protect: "false"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: newrole
rules:

OMITTED
```

- Update role's access permissions in rules. You need to add/modify/delete resources/verbs

```
OMITTED

rules:
- apiGroups:
  - ""
  attributeRestrictions: null
  resources:
  - configmaps
  - endpoints
  - persistentvolumeclaims
  - pods
  - replicationcontrollers
  - replicationcontrollers/scale
  - serviceaccounts
  - services
  verbs:
  - get
  - list
  - watch

OMITTED
```
