# Application On-boarding into TAP

<!-- TOC -->
* [Application On-boarding into TAP](#application-on-boarding-into-tap)
  * [1. `workload.yaml`](#1-workloadyaml)
    * [1. Copy `config/workload.yaml` to source code repo](#1-copy-configworkloadyaml-to-source-code-repo)
      * [a. Backend service:](#a-backend-service-)
      * [b. Frontend service (Angular):](#b-frontend-service--angular--)
    * [2. Change configuration](#2-change-configuration)
      * [a. Backend Service](#a-backend-service)
      * [b. Frontend Service](#b-frontend-service)
  * [2. `catalog-info.yaml`](#2-catalog-infoyaml)
    * [1. Copy `catalog/catalog-info.yaml` to source code repo](#1-copy-catalogcatalog-infoyaml-to-source-code-repo)
    * [2. Change configuration](#2-change-configuration)
  * [3. `Tiltfile`](#3-tiltfile)
    * [1. Copy `Tiltfile` to source code repo](#1-copy-tiltfile-to-source-code-repo)
      * [a. Maven apps `Tiltfile`](#a-maven-apps-tiltfile)
      * [b. Gradle `Tiltfile` for Intellij](#b-gradle-tiltfile-for-intellij)
      * [c. Gradle `Tiltfile` for VScode](#c-gradle-tiltfile-for-vscode)
    * [2. Change configuration](#2-change-configuration)
<!-- TOC -->

To migrate an existing application into `Tanzu Application Platform` requires a set of 3 YAML files to be added to your source-code repository.

## 1. `workload.yaml`
In the `Tanzu Application Platform`, the `workload.yaml` file is used to define and deploy workloads, which are collections of containers and **associated resources that run as a single application**.

The file contains configuration information that describes the desired state of the workload and its associated resources.

It serves as a declarative specification for how the application should be deployed and managed on the platform.

Developers can use this file to define the required resources and dependencies of their application, including the number of replicas of each container, resource limits and requests, environment variables, and more.

### 1. Copy `config/workload.yaml` to source code repo

##### a. Backend service:
Create a file called `config/workload.yaml` and copy the following content:
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
      ref:
        branch: master
```

##### b. Frontend service (Angular):
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
  build:
    env:
      - name: BP_NODE_RUN_SCRIPTS
        value: "build-tanzu"
      - name: BP_WEB_SERVER_ROOT
        value: "dist"
      - name: BP_WEB_SERVER
        value: "nginx"
  env:
    #! Additional environment variables               #! TODO: OPTIONAL CHANGE
    #!- name: SERVER_PORT
    #!  value: 8081
  source:
    git:
      url: ${GIT_REPO_URL}                           #! TODO: CHANGE
      ref:
        branch: ${GIT_REPO_BRANCH}                   #! TODO: CHANGE
```

### 2. Change configuration
##### a. Backend Service
- `${MICROSERVICE_NAME}`: Application or microservice's name.
- `${GIT_REPO_URL}`: Application source code git repo URL.
- `JAVA_TOOL_OPTIONS`:
  - `-Dmanagement.server.port=8081 -Dserver.port=8081` : Configures workload's port to be 8081. **Remove if application port is 8080**.
  - `-Dmanagement.health.probes.enabled="false"`: Disables workload's health checks. **Remove if application exposes health probes**.
- `SPRING_PROFILES_ACTIVE`: Configure Spring active profile.

##### b. Frontend Service
- `${MICROSERVICE_NAME}`: Application or microservice's name.
- `${GIT_REPO_URL}`: Application source code git repo URL.
- `${GIT_REPO_BRANCH}`: Application source code git repo branch.
- **Build Environment Variables**:
  - `BP_NODE_RUN_SCRIPTS` : Configures scripts to be run throought `npm run-script`.
  - `BP_WEB_SERVER_ROOT`: setting this allows you to modify the location of the static files served by the web server with either an absolute file path or a file path relative to `/workspace`.
---

## 2. `catalog-info.yaml`

In the `Tanzu Application Platform`, the `catalog-info.yaml` file is used to define the metadata associated with a given application or service.

It contains information about the name, version, icon, description, and other details of the application or service that will be displayed in the platform's catalog.

### 1. Copy `catalog/catalog-info.yaml` to source code repo

Create a file called `catalog/catalog-info.yaml` and copy the following content:
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

There are **3 types of Tiltfile**, please use the right template for your code:
- Maven `Tiltfile`
- Gradle `Tiltfile` for `Intellij`
- Gradle `Tiltfile` for `VScode`

##### a. Maven apps `Tiltfile`
Create a file called `Tiltfile` under your source code's root folder and copy the following content:
```Tiltfile
SOURCE_IMAGE = os.getenv("SOURCE_IMAGE", default='${IMAGE_REGISTRY_HOSTNAME}/tap-workloads-source-code/${MICROSERVICE_NAME}')  
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

##### b. Gradle `Tiltfile` for Intellij
Create a file called `Tiltfile` under your source code's root folder and copy the following content:
```Tiltfile
SOURCE_IMAGE = os.getenv("SOURCE_IMAGE", default='${IMAGE_REGISTRY_HOSTNAME}/tap-workloads-source-code/${MICROSERVICE_NAME}')
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
    container_selector='workload',

    # Live Update IntelliJ:
    deps=['build.gradle.kts', './build/classes/java/main', './build/resources/main'],
    live_update=[
       sync('./build/classes/java/main', '/workspace/BOOT-INF/classes'),
       sync('./build/resources/main', '/workspace/BOOT-INF/classes')
    ]
)

k8s_resource('${MICROSERVICE_NAME}', port_forwards=["${APP_PORT}:${APP_PORT}"],
   extra_pod_selectors=[{'carto.run/workload-name': '${MICROSERVICE_NAME}', 'app.kubernetes.io/component': 'run'}])

allow_k8s_contexts('lan-nonprod-dev0')
```

##### c. Gradle `Tiltfile` for VScode
Create a file called `Tiltfile` under your source code's root folder and copy the following content:
```Tiltfile
SOURCE_IMAGE = os.getenv("SOURCE_IMAGE", default='${IMAGE_REGISTRY_HOSTNAME}/tap-workloads-source-code/${MICROSERVICE_NAME}')
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

    # Live Update VScode:
    deps=['build.gradle.kts', './bin/main'],
    live_update=[
        sync('./bin/main', '/workspace/BOOT-INF/classes')
    ]
)

k8s_resource('${MICROSERVICE_NAME}', port_forwards=["${APP_PORT}:${APP_PORT}"],
   extra_pod_selectors=[{'carto.run/workload-name': '${MICROSERVICE_NAME}', 'app.kubernetes.io/component': 'run'}])

allow_k8s_contexts('lan-nonprod-dev0')
```

### 2. Change configuration
- `${IMAGE_REGISTRY_HOSTNAME}`: Image registry hostname.
- `${MICROSERVICE_NAME}`: Application or microservice's name.
- `${DEVELOPER_NAMESPACE}`: Developer namespace for deploying the application.
- `${MICROSERVICE_NAME}`: Application or microservice's name.
- `${APP_PORT}`: Application port.



