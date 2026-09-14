---
description: 调用 reviewer 审查当前未提交的改动或指定提交,输出结构化评审意见
agent: build
---

用 task 工具调用 reviewer 子代理, 审查当前工作区未提交的 git 改动

把 $ARGUMENTS 作为审查重点传给子代理, 若为空则根据修改推理审查重点
