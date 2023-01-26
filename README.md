# AuthN & AuthZ Using NIC with JWT's and Azure AD

## Steps to Set Up

1. Launch k8s cluster (This guide uses AKS)
2. Deploy NGINX+ Ingress Controller (NIC)
3. Deploy protected App 
4. Implement SSO With Azure AD
A. Configure Azure AD as IdP
B. Configure NIC as Relaying Party
5. Create security group
6. Create VS
7. 

### 1. Launch K8s Cluster

This guide uses AKS, the managed Azure Kubernetes environment.  

### 2. Deploy NGINX+ Ingress Controller (NIC)

Reference for installing with manifests:  <https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/>

This guide uses a Deployment for the NGINX Ingress Controller.  A Deployment makes troubleshooting easier since you only have one pod log to look at.  Later, scale up the Deployment to two or mode pods to ensure cluster syncing between the deployment pods is working.  

Note the command line options (args) in the [deployment manifest](Manifests/nginx-plus-ingress.yaml) that are required for this use case.  
### 3. Deploy Protected App

This is the application that sits behind NGINX+ and that will only be accessible after the user authenticates with Azure AD using OIDC.  We will use a simple app from the NGINX Inc GitHub repo:  <https://github.com/nginxinc/kubernetes-ingress/blob/main/examples/custom-resources/oidc/webapp.yaml>.  This file has also been copied to the Manifests folder for convience.  

- Guide to installing Elasticsearch/Kibana in K8s: <https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-deploy-eck.html>

4. A Configure Azure AD as IdP
- In Azure Portal, Azure AD -> App Registration -> New Registration
- Provide a name (e.g. kibana), set to Single Tenant
- For Redirect URI, select "Web" and "https://kibana.example.com/_codexch"
- On left of page under "Manage", select "Certificates and secrets"
- Under Client secrets, select "New client secret"
- Description = kibana-secret, Expiration = 12 months - click "Add"
- Copy client secret "Value" - 4dZ8Q~Fxzx_uikNoHKLzcN0RKVu_zOXjJjroBbq_ 




### Enable Authorization

Reference:  Conditional Access Control with Microsoft Azure Active Directory <https://www.nginx.com/blog/conditional-access-control-with-microsoft-azure-active-directory/>

### Edit the App Reg Manifest to Ensure Group Membership in JWT

Reference: RBAC <https://www.nginx.com/blog/conditional-access-control-with-microsoft-azure-active-directory/#Role-Based-Access-Control>

Default is:
"groupMembershipClaims": null,

Change to:
"groupMembershipClaims": "All",

SpTestGroup ID:  ffdb3bb1-30de-47af-a240-c8d8dd126239

## Modify the VirtualServer Manifest to Include Authz

To do this we need to add two snippets to the VirtualServer Manifest.  First an HTTP snippet:

auth_jwt_claim_set $jwt_groups groups;
map $jwt_groups $isSpTestGroup {
    "ffdb3bb1-30de-47af-a240-c8d8dd126239" 1; # SPTestGroupID
    default                                 0;
}

Then, a Location snippet:  

auth_jwt_require $isSpTestGroup error=403;

