# AuthN & AuthZ Using NIC with JWT's and Azure AD

This guide is intended to configure the NGINX Inc. Ingress Controller (NIC) to act as the Relaying Party in an OIDC flow to authenticate a user with their credentials in Azure AD.  In addition, the guide also configures the NIC to authorize the user's access based on their AD group membership.  

The guide relies on three sources to create the configuration.

1. The document "Managing Kubernetes Traffic with F5 NGINX" by Amir Rawdat.  The relavent section of that document is available [here](References/NIC-Azure%20AD.pdf)
2. The NGINX Inc. Github Site <https://github.com/nginxinc/kubernetes-ingress/tree/main/examples/custom-resources/oidc>
3. The blog post "Conditional Access Control with Microsoft Azure Active Directory" by Liam Crilly <https://www.nginx.com/blog/conditional-access-control-with-microsoft-azure-active-directory/#Role-Based-Access-Control>

Note that the configuration of the NIC is done through NGINX CRD's and not Ingress Resources.  
## Steps to Set Up

1. Launch k8s cluster (This guide uses AKS)
2. Deploy NGINX+ Ingress Controller (NIC)
3. Deploy protected Application
4. Implement SSO With Azure AD
    - A. Configure Azure AD as IdP
    - B. Configure NIC as Relaying Party
5. Create security group
6. Create VS - To expose your protected App and apply the OIDC Policy
7. 

### 1. Launch K8s Cluster

This guide uses AKS, the managed Azure Kubernetes environment.  

### 2. Deploy NGINX+ Ingress Controller (NIC)

Reference for installing with manifests:  <https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/>

This guide uses a Deployment for the NGINX Ingress Controller.  A Deployment makes troubleshooting easier since you only have one pod log to look at.  Later, scale up the Deployment to two or mode pods to ensure cluster syncing between the deployment pods is working.  

Note the command line options (args) in the [deployment manifest](Manifests/nginx-plus-ingress.yaml) that are required for this use case.  
### 3. Deploy Protected App

This is the application that sits behind NGINX+ and that will only be accessible after the user authenticates with Azure AD using OIDC.  We will use a simple app from the NGINX Inc GitHub repo:  <https://github.com/nginxinc/kubernetes-ingress/blob/main/examples/custom-resources/oidc/webapp.yaml>.  This file has also been copied to the Manifests folder for convience.  

### 4. A Configure Azure AD as IdP

This is described in the [NIC-Azure AD Guide](References/NIC-Azure%20AD.pdf).  Here is a summary of the steps:

- In Azure Portal, Azure AD -> App Registration -> New Registration
- Provide a name (e.g. webapp), set to Single Tenant
- For Redirect URI, select "Web" and "https://webapp.example.com/_codexch"
- Click "Register"
- On left of page under "Manage", select "Certificates and secrets"
- Under Client secrets, select "New client secret"
- Description = webapp client secret, Expiration = 12 months - click "Add"
- Copy and save client secret "Value" - 4dZ8Q~Fxzx_uikNoHKLzcN0RKVu_zOXjJjroBbq_ 

### 4. B Configure NIC as the Relaying Party

- Base64 encode the client secret value and save it into the [client-secret.yaml](Manifests/client-secret.yaml) in the data.client-secret field.  
- Create the secret with the manifest created in the previous step.
- Retrieve the URL's, specific to your app and org, that the NIC will need to call to perform the OIDC flow, namely, "authorization_endpoint", "jwks_uri", "token_endpoint"

```bash
curl -s https://login.microsoftonline.com/<tenant>/v2.0/.well-known/openid-configuration?appid=<app_id>
```

"tenant" and "app_id" can be found in the App registrations/Overview section of your app in the Azure portal.  
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

