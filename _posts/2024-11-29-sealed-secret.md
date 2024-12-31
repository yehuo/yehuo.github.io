---
title: "Using Sealed Secret to manage Kubernetes Secret"
date: 2024-11-29
excerpt: "Sealed Secrets 使用指南"
categories: 
    - Kubernetes
tags: 
    - Application
    - Addon
---

# 0x01 安装

Sealed Secrets 由两个部分组成：

- Client Side cli tool: kubeseal，客户端CLI工具 kubeseal，用于加密机密和创建密封机密
- Server Side controller：服务器端控制器，用于解密 SealedSecret CRD 和 创建 secrets

## 使用helm安装 sealed secret controller

```shell
#!/bin/bash

REPO="https://bitnami-labs.github.io/sealed-secrets"
CHART="sealed-secrets"
TARGET="sealed-secrets"
NAMESPACE="kube-system"

helm upgrade --install ${TARGET} ${CHART} \
  --repo ${REPO} \
  --namespace ${NAMESPACE} \
  --create-namespace \
  --set-string fullnameOverride=sealed-secrets-controller 
  # --set customKey=YOUR_CUSTOM_KEY_HERE 
  # key-renew-period=0
```

- `--namespace` 将其安装在kube-systems使得kubeseal命令不用显示声明
- `--controller-namespace` 建议使用kube-system
- `--set-string` 使用 `fullnameOverride=sealed-secrets-controller` 这个参数会 kube-system 命名空间里创建 sealed-secrets-controller service 。之后使用 kubeseal 命令就不用显示声明controller-name=sealed-secrets-controller
- controller 在首次部署时会生成自己的证书，它还会为用户管理续订。但用户也可以自带证书，以便控制器也可以使用它们。
- controller 使用任何标记为 sealedsecrets.bitnami.com/sealed-secrets-key=active 的密钥中包含的证书，该密钥必须与控制器位于同一命名空间中。可以有多个这样的秘密

## 安装本地管理工具 kubeseal

kubeseal 使用当前 kubectl 的 context 设置。安装前，需要确保 kubectl 可以连接到应安装 Sealed Secrets 的群集。

```shell
# macos
brew install kubeseal

# linux
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.13.1/kubeseal-linux-amd64 -O kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```


# 0x02 使用

![architecture](\images\SealedSecret\architecture.webp)
- controller启动时，会在其命名空间中搜索带有 sealedsecrets.bitnami.com/sealed-secrets-key 标签的 Secret 读取其中存放的私钥/公钥对
- 如果找不到，controller则会生成一个新的 4096 位 RSA 密钥对，并在命名空间中创建新的 Secret 将其保存其中。随后会将公钥部分打印到输出日志中
  - 用户可以使用以下命令以 YAML 格式查看此 Secret（包含公有/私有密钥对）的内容：
    ```shell
    kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml
    ```
- 配套的 CLI 工具 kubeseal 使用公钥加密 Secret 资源生成 SealedSecret 定制化资源定义(CRD)文件
- 将 SealedSecret CRD 部署到 Kubernetes 集群时，controller会识别到，然后使用私钥将其解封并创建一个 Secret 资源
- 加密和解密时会使用 SealedSecret 的 namespace/secret_name 作为输入参数，这样可以确保 SealedSecret 和 Secret 严格绑定到相同的命名空间和名称

kubeseal 通过 apiserver 与 controller进行通信，并在运行时检索加密 Secret 所需的公钥，但是用户也可以从控制器下载公钥并保存在本地以便离线使用。

# 0x03 Usage

SealedSecret 和 Secret 必须具有相同的命名空间和名称。此功能可防止同一集群上的其他用户重复使用设置过的 sealedsecret 资源。

```shell
kubeseal --format yaml < mysecret.yaml > mysealedsecret.yaml
# --scope 全局可用生成的密文可以在整个集群中使用，而不是仅限于特定的命名空间
kubeseal --format yaml --scope cluster-wide < mysecret.yaml > mysealedsecret2.yaml
```

上述过程中，kubeseal 将 Kubernetes Secret 作为输入，对其进行加密并输出 CRD 清单 SealedSecret 。

## Test Case

1. 编写一份普通的secret资源
   
    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      creationTimestamp: null
      name: my-secret
    data:
      password: YmFy
      username: Zm9v
    ```
2. 使用kubeseal加密上述secret资源
   
    ```shell
    cat secret.yaml | kubeseal \
    --controller-namespace kube-system \
    --controller-name sealed-secrets \
    --format yaml \
    > sealed-secret.yaml
    ```
3. 查看加密后的内容
   
   ```yaml
   # cat sealed-secret.yaml
   apiVersion: bitnami.com/v1alpha1
   kind: SealedSecret
   metadata:
     creationTimestamp: null
     name: my-secret
     namespace: default
    spec:
      encryptedData:
        password: AgA...
        username: AgA...
      template:
        metadata:
          creationTimestamp: null
          name: my-secret
          namespace: default
    ```
4. 将加密后的内容部署到集群中，之后 controller 会自动对该 sealedsecret 解密，并创建对应的 Secret 资源
   
    ```shell
    kubectl apply -f sealed-secret.yaml
    ```
5. 在集群中查看解密后的资源
   
    ```shell
    kubectl get secret my-secret -o yaml
    ```

# 0x04 Customized Resources

## Define costomized certificate

refer: https://github.com/bitnami-labs/sealed-secrets/blob/main/docs/bring-your-own-certificates.md

1. 在controller中生成并使用新证书

    ```shell
    export PRIVATEKEY="default.key"
    export PUBLICKEY="default.crt"
    export NAMESPACE="sealed-secrets"
    export SECRETNAME="mycustomkeys"
    export DAYS="3650"
    # create RSA key pair (certificate)
    openssl req -x509 -days ${DAYS} -nodes -newkey rsa:4096 -keyout "$PRIVATEKEY" -out "$PUBLICKEY" -subj "/CN=sealed-secret/O=sealed-secret"
    # create k8s tls key pair with the RSA key
    kubectl -n "$NAMESPACE" create secret tls "$SECRETNAME" --cert="$PUBLICKEY" --key="$PRIVATEKEY"
    kubectl -n "$NAMESPACE" label secret "$SECRETNAME" sealedsecrets.bitnami.com/sealed-secrets-key=active

    # delete the legacy controller pod

    kubectl -n  "$NAMESPACE" delete pod -l name=sealed-secrets-controller
    # wait the deployment restart the pod with new certificate
    # check the new certificate in controller
    kubectl -n "$NAMESPACE" logs -l name=sealed-secrets-controller
    ```

2. 使用新证书加密 sealedsecret，并查看对应资源
   
    ```shell
    kubeseal --cert "./${PUBLICKEY}" --scope cluster-wide < mysecret.yaml | kubectl apply -f 

    kubectl -n "$NAMESPACE" logs -l name=sealed-secrets-controller
    ```

## Export public key and encryption

对于未加密的 secret，如果需要手工加密，可以导出集群中的 public key 来加密

```shell
kubeseal --fetch-cert > public-key-cert.pem

# create sealed secret CRD
kubeseal --format=yaml --cert=public-key-cert.pem < secret.yaml > sealed-secret.yaml
```

## Export private key and decryption

对于已加密的 sealed secret，如果需要手工加密，可以导出集群中的 private key 来解密

```shell
kubectl -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key=active -o yaml  | kubectl neat > allsealkeys.yml

# get current sealed secret CRD
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealed-secrets-key.yaml

# decrypting it to secret
kubeseal < sealed-secret.yaml --recovery-unseal --recovery-private-key sealed-secrets-key.yaml -o yaml
```

# 0x05 Conclusion & Reference

Sealed Secrets 是一种在版本控制工具（例如git）里管理 Kubernetes Secret的安全方法。通过在集群中存储加密密钥并解密机密。来保证非授权客户端（无私钥客户端）无权访问加密密钥。

客户端使用 kubeseal 工具生成 SealedSecret 保存加密数据的清单。应用文件后，集群中的 controller 将识别新的密封密钥资源并对其进行解密以创建 Secret 资源。

## Reference

- ["Sealed Secrets" for Kubernetes](https://github.com/bitnami-labs/sealed-secrets)
- [Bring your own certificates](https://github.com/bitnami-labs/sealed-secrets/blob/main/docs/bring-your-own-certificates.md)
- [加密 Secrets 资源：Sealed Secrets 使用指南](https://cloudnative.love/blog/2023/06/20/%E5%8A%A0%E5%AF%86%20Secrets%20%E8%B5%84%E6%BA%90%EF%BC%9ASealed%20Secrets%20%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/README/)