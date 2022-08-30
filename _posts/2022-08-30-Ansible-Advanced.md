---
title: "Ansible进阶知识"
date: 2022-08-30
excerpt: "一些便于测试Ansible的小tricks"
categories: 
   - Notes
tags:
   - Ansible

---



# Ansible 偷鸡方法一览

## 测试单个task时候

使用`--start-at`确定开始任务名称，或者使用`tag`来标注需要测试的任务，或者使用`step`逐步执行任务，参考[cn-doc](http://www.ansible.com.cn/docs/playbooks_startnstep.html)

```shell
ansible-playbook -i daxing/dev/ playbooks/proxmox.yaml -l dx-proxmox-dev-005.dx.corp.pony.ai --extra-vars "bonding=1" --user shujia --ask-become-pass --ssh-extra-args "-F /home/shujia/.ssh/teleport-current" --start-at="Check bonding status"
```

## 开头根据变量筛选任务是否进行

使用meta的end_host模块进行控制

```yaml
- name: Check bonding status
  meta: end_host
  when: '"bond0" in ansible_interfaces'
```

## ad-hoc方式测试某个命令及查看`ansible_facts`

ad hoc使用方式[官方文档](https://docs.ansible.com/ansible/latest/user_guide/intro_adhoc.html)

```shell
# 查看ansible facts中某变量
ansible -i daxing/dev/ dx-proxmox-dev-005.dx.corp.pony.ai -m "setup" -a "filter=ansible_interfaces"
# 测试ping
ansible -i daxing/dev/ dx-proxmox-dev-005.dx.corp.pony.ai -m "shell" -a "cmd='ping dx-proxmox-dev-004.dx.corp.pony.ai'"
```

## set fact和var的使用问题

`var`无法作为单独的task使用，而且和`shell`等命令使用不兼容，最好直接`set_fact`作为一个单独task来设定一些变量。

不过偶尔会出现`set_fact`定义的变量使用时被定义为undefined的问题，多半是因为set_fact的值中包含变量，所以使用时需要添加`default`filter，如下

```yaml
- name: get interface info
  set_fact:
    interface_available: '{{ interface_alive.stdout | difference(basic_interfaces) }}'
    interface_number: '{{ interface_available | default([]) | count }}'
```

## 常用模块参考

- [shell](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/shell_module.html)
- [command](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/command_module.html)
- [debug](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/debug_module.html)
- [apt](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html)
- [become](https://docs.ansible.com/ansible/latest/user_guide/become.html)
- [facts and magic variables](https://docs.ansible.com/ansible/latest/user_guide/playbooks_vars_facts.html)
- [Variables](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html)
  - [Scoping](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#scoping-variables)
  - [precedence](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#scoping-variables)
- [when,condition](https://docs.ansible.com/ansible/latest/user_guide/playbooks_conditionals.html#conditionals-based-on-ansible-facts)
- [meta](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/meta_module.html)

## Reference

- [Jinja2 Filters Document](https://ansible-docs.readthedocs.io/zh/stable-2.0/rst/playbooks_filters.html#filters-often-used-with-conditionals)
- [Ansible中的Jinja2 Filter](https://www.cnblogs.com/ccbloom/p/15508645.html)
- [Ansible Return Value](https://docs.ansible.com/ansible/latest/reference_appendices/common_return_values.html)