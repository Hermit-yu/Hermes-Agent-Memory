# ziyan-governance skill 注释

## 用途

这是将 OpenClaw 时代的“三省六部 + 中枢院/尚书局”治理规划封装为 Hermes Agent 可直接加载的 skill。

## Runtime 安装位置

- Live Hermes skill: `/root/.hermes/skills/personal/ziyan-governance/SKILL.md`
- Repository audit copy: `skills/personal/ziyan-governance/SKILL.md`

## 触发场景

当任务涉及以下情况时，智妍应优先加载/遵循该 skill：

- 多步骤技术任务
- 部署、配置、代码修改、GitHub 同步
- 高风险动作审批与验收
- 需要阶段性进度回执
- 需要把执行结果同步回 Hermes-Agent-Memory

## 与原始治理文档的关系

来源锚点：

- `projects/智妍的自我提升计划/governance/三省六部-中枢院尚书局-实装方案.md`
- `projects/智妍的自我提升计划/governance/任务路由-六部映射.yaml`
- `projects/智妍的自我提升计划/governance/C01-实装运行手册.md`
- `memory-echoDB/long-term/projects/智妍的自我提升计划.md`

原始文档作为长期治理档案；本 skill 作为 Hermes runtime 的实际调用入口。

## 检查方式

在 Hermes 中可通过：

```text
skill_view(name="ziyan-governance")
```

验证是否可加载。

## 变更说明

- 2026-05-21：首次封装为 Hermes skill，并同步仓库审计副本。
