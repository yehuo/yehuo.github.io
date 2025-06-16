---
title: "Using user imperonation to setup continuous deployment in Kubernetes"
date: 2025-04-05
categories:
    - Kubernetes
tags:
    - Authenticating
    - ContinuousDeployment
    - Helm
excerpt: "Learn how to use Kubernetes user impersonation in CI/CD pipelines for secure, least-privilege deployments. This guide covers kubectl, helm, and audit log tracing for better access control and observability."
---



In modern DevOps workflows, security and automation are equally critical. When setting up Continuous Deployment (CD) pipelines to Kubernetes clusters, teams often face a dilemma: *how to give CI/CD systems the access they need without compromising the principle of least privilege?*

One powerful and underutilized solution in Kubernetes is **user impersonation**. This technique allows services to act as if they were a specific user or service account, without directly possessing that user’s credentials. Let’s explore how you can leverage impersonation to build a secure, auditable, and flexible CD pipeline.

## What is User Impersonation in Kubernetes?

**User impersonation** allows a client to act on behalf of another user or service account by including special HTTP headers in the Kubernetes API request:

- Impersonate-User: Specifies the user to impersonate
- Impersonate-Group: (Optional) Adds groups
- Impersonate-Extra-<key>: (Optional) Passes additional attributes

Kubernetes verifies whether the requesting identity (e.g., a GitHub Actions runner or Argo CD Pod) is authorized to impersonate the target user. This is strictly controlled via RBAC rules.

## Why Use Impersonation for CD?

Traditional Approach:

- The CI/CD system is granted a broad token (e.g., cluster-admin).
- Risk: If the token leaks or is misused, it has unrestricted access.

Impersonation-Based Approach:

- The CI/CD runner has permission to impersonate specific users or service accounts.
- Each deployment impersonates a user with exactly the required privileges.
- Easier to audit: the impersonated identity appears in logs.

## Prerequisites

A running Kubernetes cluster (v1.6+)

A CI/CD agent (e.g., GitHub Actions, GitLab Runner, Argo CD) with cluster access

kubectl or Kubernetes SDKs installed

ClusterRole + RoleBinding to allow impersonation

## Guidelines

### 1. Create the Target Service Account (Impersonated)

```bash
kubectl create serviceaccount deployer -n my-namespace
```

Bind permissions (e.g., to deploy apps):

```yaml
# deployer-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployer
  namespace: my-namespace
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["create", "update", "get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deployer-binding
  namespace: my-namespace
subjects:
- kind: ServiceAccount
  name: deployer
  namespace: my-namespace
roleRef:
  kind: Role
  name: deployer
  apiGroup: rbac.authorization.k8s.io
```

Apply the RoleBinding:

```bash
kubectl apply -f deployer-role.yaml
```

### 2. Allow Impersonation from the CI/CD Identity

Assume the CI/CD runner uses a service account named cicd-agent in kube-system namespace.

```yaml
# impersonation-rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: impersonate-deployer
rules:
- apiGroups: [""]
  verbs: ["impersonate"]
  resources: ["serviceaccounts"]
  resourceNames: ["deployer"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: allow-cicd-to-impersonate
subjects:
- kind: ServiceAccount
  name: cicd-agent
  namespace: kube-system
roleRef:
  kind: ClusterRole
  name: impersonate-deployer
  apiGroup: rbac.authorization.k8s.io
```

Apply ClusterRole and ClusterRoleBinding:

```shell
kubectl apply -f impersonation-rbac.yaml
```

### 3. Modify CD Script to Impersonate

If using kubectl in a CI script, set the impersonation flag:

```bash
kubectl --as=system:serviceaccount:my-namespace:deployer apply -f deployment.yaml
```

Using helm:

Helm supports impersonation through --kube-as and --kube-as-group:

```bash
helm upgrade my-app ./chart \
  --namespace my-namespace \
  --install \
  --kube-as system:serviceaccount:my-namespace:deployer \
  --kube-as-group system:serviceaccounts
```

This ensures that all operations performed by Helm in the cluster are executed as the impersonated service account.

> Requires Helm v3.8.0+



Or in client-go (Python, Go, etc.), set the appropriate headers in your API client:

```yaml
headers:
  - name: Impersonate-User
    value: system:serviceaccount:my-namespace:deployer
```

## Auditing & Logs

Kubernetes audit logs will show actions as if performed by the impersonated user, but also retain the original user’s identity in the user.username field. This ensures transparency and traceability:

1. View logs on the control plane node:

```bash
sudo cat /var/log/kubernetes/audit.log | jq
```

2. Filter impersonation entries:

```bash
jq 'select(.impersonatedUser.username=="system:serviceaccount:my-namespace:deployer")' audit.log
```

3. Sample log entry:

```json
{
  "user": {
    "username": "system:serviceaccount:kube-system:cicd-agent"
  },
  "impersonatedUser": {
    "username": "system:serviceaccount:my-namespace:deployer"
  },
  "verb": "update",
  "objectRef": {
    "resource": "deployments",
    "namespace": "my-namespace"
  }
}
```

## Advanced Usage

- Impersonating Groups: Useful for role-based access within your team.
- Per-Environment Roles: Give deployer-staging and deployer-prod separate permissions.
- Argo CD or Flux: Both tools support impersonation via --as or API headers.

## Security Considerations

- Only grant impersonation permissions to trusted identities.
- Never allow impersonation of system:masters or cluster-admin.
- Rotate service account tokens used by CI/CD agents regularly.

## Summary

User impersonation provides a secure and modular way to manage access in your CI/CD pipeline. It separates who can deploy from who runs the deployment, creating a robust layer of abstraction that aligns with zero-trust principles.

When used properly, impersonation can help your team achieve:

- Least privilege access control
- Clearer audit trails
- Safer CI/CD automation