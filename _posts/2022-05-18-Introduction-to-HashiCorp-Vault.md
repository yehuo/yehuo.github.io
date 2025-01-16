---
title: Introduction to HashiCorp Vault
date: 2022-05-18
excerpt: "Why you should use vault in your office"
categories:
    - Hashicorp
tags:
    - Vault
---



# Core principles of Vault

## What is Secret

Secret: a set of credential, which give authentication to a system or authorization to a system

- username
- db credentials
- API token
- TLS certificates

## Secret Management

Who has access to them

Who has been using them

How we can periodically rotate these things

## Secret Sprawl

- Source code
- Configuration
- Version  Control system(Github)

Sprawl makes secret hard to audit and rotate.

## Vault's Target

- Solving the secret sprawl problem with **centralizing**, move everything to a central location
- **Encrypt** everything inside the vault and transit them between vaults and users need to use them
- Fine-grained access control(ACL) everyone shouldn't have access to everything
- Audit trail

## Second problem with Secret

Application can not be trusted, our secret can be seen in log files and output

## Dynamic Secret

- Ephemeral: long-lived credentials are inevitable leaked but short-lived ephemeral credentials 
- unique: each credentials is unique for each client
- revoke: isolate the leak point and keep service alive, keep the blast radius of a revocation contorled

## Usage problem in Vault

How do we get away from ultros storing an encryption key and handing it to the application and assuming the app will  not do cryptography right.

## Encrypt as Service

- Keep data secret
- Offering the high level APIs to cryptography
  - Encrypt
  - Decrypt
  - Sign
  - Verify
-  the full life cycle key management
  - Key versioning
  - Key rotation
  - Key decommissioning

# Architecture and Implement of Vault

## Authentication Center

Offering different provider to different users, the providers can provide application or human identity.

- EC2 VM
- AWS
- LDAP/AD
- K8S

The Notion of identity call

## Auditing Backend

Stream out requests' response auditing to an external system that gives us a trail of who's done what

- Splunk
- syslog

## Storage Backend

Provide durable storage which is highly available, so we can tolerate the loss of one of the other backends

- RDBMS
- Consuls
- Spanner

## Secret Backend

How does vault provide access to different secret. The biggest usage of this is to enable dynamic secret capability.

- key-value: basic data like name and password
- database plugins: to offer complicated dynamic secret management
- RabbitMQ
- AWS short-lived credentials
- PKI: It can be nightmare to keeping go through the process of generating certificates. So we can defined some very short lived certificates, like short to 72 or 24 hours
- SSH

# How to HA

There can be several instance in vault cluster, with one leader node. In the usage, if we talked with non leader node, our requests will be transparently forwarded to active leader node.

 Multiple instances with a shared network service, as a API client in network. Vault cluster will just expose a JSON API.

## Reference

 - [Introduction to HashiCorp Vault](https://www.youtube.com/watch?v=VYfl-DpZ5wM&ab_channel=HashiCorp)