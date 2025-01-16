---
title: Enforcing Label-based Pod Restrictions with Admission Webhook
date: 2024-10-21
excerpt: "In Kubernetes, ensuring that only pods with specific labels can be deployed is a common requirement for enforcing organization policies or resource allocation strategies. This blog demonstrates how to use an Admission Webhook to restrict pod creation based on labels. By implementing a custom webhook, you can control which pods are allowed to start, ensuring that only those with the required labels meet your deployment criteria. This solution provides an additional layer of validation, enhancing the security and consistency of your Kubernetes clusters."
categories: 
    - Kubernetes
tags: 
    - Admission Webhook
---



# 0x00 Intro and Preparation

## What is the Admission Controller

在Kubernetes请求执行的生命周期中，在请求到达apiserver后，经过认证和鉴权后，对于请求本身还有一个准入控制器，并包括 `Validating` 和 `Mutating` 两个阶段，请求通过两个阶段验证后才会正式将请求内容持久化到etcd当中。

所以通俗上理解，`Admission Controller` 就是在Kubernetes中变更持久化之前用于对请求进行拦截和修改的一种自动化工具。而在处理请求的两个阶段中

- `Mutating` 控制器在前，可以修改发送请求中的资源对象
- `Validating` 控制器在后，不会修改请求中的资源对象

但当两个控制器中任一个拒绝了请求，则整个请求会被直接拒绝掉，并可以将错误返回给用户（或者drop掉）。

## Configure the API Server Feature Gateway



```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    component: kube-apiserver
    tier: control-plane
  name: kube-apiserver-ydzs-master
  namespace: kube-system
......
spec:
  containers:
  - command:
    - kube-apiserver
    - --advertise-address=10.151.30.11
    - --allow-privileged=true
    - --authorization-mode=Node,RBAC
    - --client-ca-file=/etc/kubernetes/pki/ca.crt
    - --enable-admission-plugins=NodeRestriction,MutatingAdmissionWebhook,ValidatingAdmissionWebhook
```

上面的`enable-admission-plugins`参数中带上了`MutatingAdmissionWebhook`和`ValidatingAdmissionWebhook`两个准入控制插件，如果没有的，需要添加上这两个参数，然后重启 apiserver。

```yaml
$ kubectl api-versions | grep admission
admissionregistration.k8s.io/v1
TypeMeta
```

# 0x01 Setup Webhook Server

## 编写webhook server

## 构建镜像

直接Pull example Image



## 部署CSR资源及Secret

## 配置webhook resources in Kubernetes

# Webhook Function Test





