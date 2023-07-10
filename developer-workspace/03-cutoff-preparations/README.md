# Cutoff Preparations

The purpose of this document is to map the required preparations for a successful Application Migration to Production environment in TAP ('Cutoff'). 


<!-- TOC -->
* [Cutoff Preparations](#cutoff-preparations)
  * [1. Development workstream](#1-development-workstream)
    * [1.1 Developer Workspace](#11-developer-workspace)
        * [1.1.1. Required software installations](#111-required-software-installations)
        * [1.1.2 Required Credentials and Access](#112-required-credentials-and-access)
    * [1.2 Inner loop development](#12-inner-loop-development)
        * [1.2.1 Validate Live Update capability](#121-validate-live-update-capability)
        * [1.1.2 Validate Live Debug capability](#112-validate-live-debug-capability)
    * [1.3 YAML files](#13-yaml-files)
        * [1.3.1 `workload.yaml`:](#131-workloadyaml-)
        * [1.3.2. `catalog-info.yaml`:](#132-catalog-infoyaml-)
        * [1.3.3 `Tiltfile`](#133-tiltfile)
    * [1.4 Developer Namespaces](#14-developer-namespaces)
        * [1.4.1 TAP Label on Developer Namespaces](#141-tap-label-on-developer-namespaces)
  * [2. Production Environment Readiness](#2-production-environment-readiness)
    * [2.1 Spring Cloud Gateway](#21-spring-cloud-gateway)
    * [2.1 AppSSO](#21-appsso)
    * [2.2 Deliverables](#22-deliverables)
    * [2.3 Network](#23-network)
    * [2.4 TAP-GUI Visibility](#24-tap-gui-visibility)
<!-- TOC -->

---
## 1. Development Work Stream

First, verify development cycle is complete and functioning, allowing to build and deploy future versions of the Application.

### 1.1 Developer Workspace

##### 1.1.1. Required software installations

Verify development team has all required software installations as specified in `01-setup-developer-workspace`:

- `docker`
- `kubectl`
- `Tilt`
- `tanzu` CLI
- `Tanzu` IDE Plugins.

##### 1.1.2 Required Credentials and Access 

Verify development team has these capabilities: 

1. Login to Harbor (`harbor0`).
2. Login to 'dev0' cluster.
3. Login to TAP-GUI.
4. Dev team SSO group is bounded to 'app-editor' cluster role.
5. Dev team SSO group has permissions for these AzureAD clients:
   - TAP-GUI Backstage (used for accessing TAP GUI via AzureAD authentication).
   - Relevant AppSSO servers that the application is registered to.


---

### 1.2 Inner loop development

Verify inner-loop development is working correctly:

##### 1.2.1 Validate Live Update capability

Validate a workload can be deployed using Live Update, and that the functionality itself works.

##### 1.1.2 Validate Live Debug capability

Validate a workload can be deployed using Live Debug, and that the functionality itself works.

---

### 1.3 YAML files

Validate all YAML files are configured correctly:

##### 1.3.1 `workload.yaml`: 

- Points to 'master' git branch in source code repo.
- GitOps repo params are configured.
- Workload's name is matching the `app.kubernetes.io/part-of` label value.
- Workload is deployed on developer's namespace.
- Workload is deployed on Build cluster.

##### 1.3.2. `catalog-info.yaml`: 
- Registered under TAP GUI catalog for each microservice. 
- Matching the `app.kubernetes.io/part-of` label value of the workload.

##### 1.3.3 `Tiltfile` 
- Configured according to Framework + IDE [Maven | Gradle + VScode | Gradle + Intellij].
- Points to 'dev0' cluster with `allow_k8s_contexts('lan-nonprod-dev0')`.

---

### 1.4 Developer Namespaces

##### 1.4.1 TAP Label on Developer Namespaces
Verify Dev namespaces carries `apps.tanzu.vmware.com/tap-ns` label.

Can be labeled using `kubectl label namespace NAMESPACE_NAME apps.tanzu.vmware.com/tap-ns=""`.

---

## 2. Production Environment Readiness

Second, verify all required CRD's and components are deployed and configured correctly on Production cluster:

### 2.1 Spring Cloud Gateway

Verify Spring Cloud Gateway is configured for each cluster the application will run on:

1. Name: `hive-gateway`

   Kind: `SpringCloudGateway`

2. Name: `hive-gateway`

   Kind: `Ingress`

3. Name: `hive-gateway-routes`

   Kind: `SpringCloudGatewayRouteConfig`

4. Name: `hive-gateway-mapping`

   Kind: `SpringCloudGatewayMapping`

---

### 2.1 AppSSO

Verify AppSSO is configured for each cluster of the Iterate/Run clusters:

1. Name: `appsso-azuread-authserver`

   Kind: `AuthServer`

2. Name: `authserver-signing-key`

   Kind: `RSAKey`

3. Name: `appsso-azuread-client-secret`

   Kind: `Secret`

4. Name: `appsso-azuread-authserver`

   Kind: `Service`

5. Name: `appsso-azuread-authserver`

    Kind: `HTTPProxy`

6. Name: `hive-workload-client-registration`

   Kind: `ClientRegistration`

7. Name: `hive-client-claim`

   Kind: `ResourceClaim`

---

### 2.2 Deliverables 

Prepare the relevant deliverables to be deployed on Production cluster.

The manifests should be identical to the ones deployed on previous environment, only the git branch should point to the 'master' or 'production' branch of the GitOps repo.  

---

### 2.3 Network

Verify all relevant backing services are accessible from Production cluster.

Here are a few examples:

- Databases
- Kafka
- RabbitMQ 
- Redis 

---

### 2.4 TAP-GUI Visibility

Verify TAP-GUI displays data from Production cluster.

---

### 2.5 Application Namespace

##### 1.4.1 TAP Label on Application Namespaces

Verify Application namespaces in all relevant clusters carry the `apps.tanzu.vmware.com/tap-ns` label.

Can be labeled using `kubectl label namespace NAMESPACE_NAME apps.tanzu.vmware.com/tap-ns=""`.
