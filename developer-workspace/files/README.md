# Application On-boarding into TAP 

<!-- TOC -->
* [Application On-boarding into TAP](#application-on-boarding-into-tap)
  * [1. `workload.yaml`](#1-workloadyaml)
    * [1. Copy `config/workload.yaml` to source code repo](#1-copy-configworkloadyaml-to-source-code-repo)
    * [2. Change configuration](#2-change-configuration)
  * [2. `catalog-info.yaml`](#2-catalog-infoyaml)
    * [1. Copy `catalog/catalog-info.yaml` to source code repo](#1-copy-catalogcatalog-infoyaml-to-source-code-repo)
    * [2. Change configuration](#2-change-configuration)
  * [3. `Tiltfile`](#3-tiltfile)
    * [1. Copy `Tiltfile` to source code repo](#1-copy-tiltfile-to-source-code-repo)
    * [2. Change configuration](#2-change-configuration)
<!-- TOC -->

To migrate an existing application into `Tanzu Application Platform` requires a set of 3 YAML files to be added to your source-code repository.

## 1. `workload.yaml`
In the `Tanzu Application Platform`, the `workload.yaml` file is used to define and deploy workloads, which are collections of containers and **associated resources that run as a single application**. 

The file contains configuration information that describes the desired state of the workload and its associated resources.

It serves as a declarative specification for how the application should be deployed and managed on the platform. 

Developers can use this file to define the required resources and dependencies of their application, including the number of replicas of each container, resource limits and requests, environment variables, and more.

### 1. Copy `config/workload.yaml` to source code repo

`config/workload.yaml`
```yaml
apiVersion: carto.run/v1alpha1
kind: Workload
metadata:
  name: ${MICROSERVICE_NAME}                          #! TODO: CHANGE
  labels:
    apps.tanzu.vmware.com/workload-type: web
    app.kubernetes.io/part-of: ${MICROSERVICE_NAME}   #! TODO: CHANGE
#!    apps.tanzu.vmware.com/auto-configure-actuators: "false"
spec:
  env:
    #! Set Java tool options
    - name: JAVA_TOOL_OPTIONS                         #! TODO: OPTIONAL CHANGE
      value: -Dmanagement.server.port=8081 -Dserver.port=8081 -Dmanagement.health.probes.enabled="false"
    #! Set Spring active profile                      
    - name: SPRING_PROFILES_ACTIVE                    #! TODO: OPTIONAL CHANGE
      value: qa0,disabledjobs
    #! Additional environment variables               #! TODO: OPTIONAL CHANGE
    #!- name: SERVER_PORT
    #!  value: 8081
  source:
    git:
      url: ${GIT_REPO_URL}                            #! TODO: CHANGE
      #! For example: https://devops.corp.zim.com/bitbucket/scm/al/vessel-viewer.git
      ref:
        branch: master
```
### 2. Change configuration
- `${MICROSERVICE_NAME}`: Application or microservice's name.
- `${GIT_REPO_URL}`: Application source code git repo URL.
- `JAVA_TOOL_OPTIONS`:
  - `-Dmanagement.server.port=8081 -Dserver.port=8081` : Configures workload's port to be 8081. **Remove if application port is 8080**. 
  - `-Dmanagement.health.probes.enabled="false"`: Disables workload's health checks. **Remove if application exposes health probes**.
- `SPRING_PROFILES_ACTIVE`: Configure Spring active profile.

---

## 2. `catalog-info.yaml`

In the `Tanzu Application Platform`, the `catalog-info.yaml` file is used to define the metadata associated with a given application or service. 

It contains information about the name, version, icon, description, and other details of the application or service that will be displayed in the platform's catalog.

### 1. Copy `catalog/catalog-info.yaml` to source code repo
`catalog/catalog-info.yaml`

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: ${MICROSERVICE_NAME}                  #! TODO: CHANGE
  description: ${MICROSERVICE_DESCRIPTION}    #! TODO: CHANGE
  tags:                                       #! TODO: OPTIONAL CHANGE
    - tanzu
  annotations:
    'backstage.io/kubernetes-label-selector': 'app.kubernetes.io/part-of=${MICROSERVICE_NAME}'    #! TODO: CHANGE
spec:
  type: service
  lifecycle: experimental
  owner: ${DEV_TEAM_NAME}                     #! TODO: CHANGE
```

### 2. Change configuration
- `${MICROSERVICE_NAME}`: Application or microservice's name.
- `${MICROSERVICE_DESCRIPTION}`: Application or microservice's description.
- `${DEV_TEAM_NAME}`: Developer team's name.

---

## 3. `Tiltfile`

In the `Tanzu Application Platform`, a `Tiltfile` is a configuration file that is used by the `Tilt` tool to manage the local development environment for a given application or service. 

The `Tiltfile` contains a series of configuration commands that define how the application or service should be built and deployed, as well as how it should interact with other services or resources in the environment.

It serves as a central point of configuration for the local development environment.

### 1. Copy `Tiltfile` to source code repo
`Tiltfile`
```Tiltfile
SOURCE_IMAGE = os.getenv("SOURCE_IMAGE", default='harbor0.nonprod-shared.lan.k8s.corp.zim.com/tap-workloads-source-code/${MICROSERVICE_NAME}')  
LOCAL_PATH = os.getenv("LOCAL_PATH", default='.')
NAMESPACE = os.getenv("NAMESPACE", default='${DEVELOPER_NAMESPACE}')

k8s_custom_deploy(
   '${MICROSERVICE_NAME}',
   apply_cmd="tanzu apps workload apply -f config/workload.yaml --live-update" +
       " --local-path " + LOCAL_PATH +
       " --source-image " + SOURCE_IMAGE +
       " --namespace " + NAMESPACE +
       " --yes >/dev/null" +
       " && kubectl get workload ${MICROSERVICE_NAME} --namespace " + NAMESPACE + " -o yaml",
   delete_cmd="tanzu apps workload delete -f config/workload.yaml --namespace " + NAMESPACE + " --yes" ,
   deps=['pom.xml', './target/classes'],
   container_selector='workload',
   live_update=[
       sync('./target/classes', '/workspace/BOOT-INF/classes')
   ]
)

k8s_resource('${MICROSERVICE_NAME}', port_forwards=["${APP_PORT}:${APP_PORT}"],
   extra_pod_selectors=[{'carto.run/workload-name': '${MICROSERVICE_NAME}', 'app.kubernetes.io/component': 'run'}])

allow_k8s_contexts('lan-nonprod-dev0')
```

### 2. Change configuration
- `${MICROSERVICE_NAME}`: Application or microservice's name.
- `${DEVELOPER_NAMESPACE}`: Developer namespace for deploying the application.
- `${MICROSERVICE_NAME}`: Application or microservice's name.
- `${APP_PORT}`: Application port.



