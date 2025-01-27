---
title: Some Advanced Ansible Knowledge
date: 2022-08-30
excerpt: "记录一些便于测试 Ansible 的小技巧..."
categories: 
   - Continuous Deployment
tags:
   - Ansible
---



# 0x01 如何指定Playbook中部分Task进行测试

当我们执行一个Playbook时，只想执行其中部分Task时候，根据 [Ansible 中文权威指南](http://www.ansible.com.cn/docs/playbooks_startnstep.html)，有下面几种方法来筛选需要执行的Task：

1. 使用`--start-at`确定开始任务名称，
2. 使用`tag`来标注需要测试的任务，
3. 使用`step`逐步执行任务

具体使用可以参考以下例子：

```shell
ansible-playbook -i $region_name -l $node_name $playbook_name$ --user $username --ask-become-pass --start-at=$task_name
```

# 0x02 如何根据系统变量来判断 Playbook 是否进行

当我们想设置对于某些服务器不执行某个Playbook中后续Task时，同时又不想让Playbook报错，根据 [Ansible 官方文档](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/meta_module.html)，可以使用 meta 模块的 end_host 设置来控制 Playbook 的执行流程。

```yaml
- name: Check bonding status
  meta: end_host
  when: '"bond0" in ansible_interfaces'
```

## 0x03 如何使用 ad hoc 方式运行单一Task 并查看`ansible_facts`

[Ansible 官方文档](https://docs.ansible.com/ansible/latest/user_guide/intro_adhoc.html)中介绍了 ad hoc 的使用方式。

```shell
ansible -i $region_name -l $node_name -m "setup" -a "filter=ansible_interfaces"

ansible -i $region_name -l $node_name -m "shell" -a "cmd='ping baidu.com'"
```

# 0x04 set fact 和 var 的使用有什么区别

`var` 无法作为单独的 task 使用，而且和 `shell` 等命令使用不兼容，最好编写一个单独的 `set_fact` Task 来设定一些变量。

不过偶尔会出现 `set_fact` 定义的变量在使用时被定义为 UNDIFINE 的问题，往往是因为 `set_fact` 的参数中包含变量，导致在调用时还未赋值。这时候可以通过添加 `default`过滤器来设定默认值。

```yaml
- name: get interface info
  set_fact:
    interface_available: '{{ interface_alive.stdout | difference(basic_interfaces) }}'
    interface_number: '{{ interface_available | default([]) | count }}'
```

# 0x05 常用模块参考

## 执行命令类

- [shell](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/shell_module.html)
- [command](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/command_module.html)
- [debug](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/debug_module.html)

## 软件安装 & 提权

- [apt](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html)
- [become](https://docs.ansible.com/ansible/latest/user_guide/become.html)

## 变量声明

- [facts and magic variables](https://docs.ansible.com/ansible/latest/user_guide/playbooks_vars_facts.html)
- [Variables](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html)
  - [Scoping](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#scoping-variables)
  - [precedence](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#scoping-variables)

## 流程控制

- [when,condition](https://docs.ansible.com/ansible/latest/user_guide/playbooks_conditionals.html#conditionals-based-on-ansible-facts)
- [meta](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/meta_module.html)

---

## Reference

- [Jinja2 Filters Document](https://ansible-docs.readthedocs.io/zh/stable-2.0/rst/playbooks_filters.html#filters-often-used-with-conditionals)
- [Ansible中的Jinja2 Filter](https://www.cnblogs.com/ccbloom/p/15508645.html)
- [Ansible Return Value](https://docs.ansible.com/ansible/latest/reference_appendices/common_return_values.html)