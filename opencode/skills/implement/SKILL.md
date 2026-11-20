---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

在预先约定的 seam 上尽量使用 `tdd` skill。

定期运行类型检查与单个测试文件,最后再跑一次完整测试套件。

完成后用 `code-review` skill 复查改动。

不要主动提交:把改动留在工作区;需要提交时先征得用户同意(遵循全局 AGENTS.md)。
