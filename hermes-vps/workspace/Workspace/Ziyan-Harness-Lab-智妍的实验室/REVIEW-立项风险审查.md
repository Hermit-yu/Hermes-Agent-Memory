# Ziyan Harness Lab 立项风险审查

**审查结论：有条件 Go；当前形态不得直接开工。**

项目的核心价值成立：用隔离环境、可复核证据和回归场景，检查智能体是否“真实执行、正确验收、安全停手”，而不是只看最终文字。但现有概念把人格、工具、安全、双脑路由、记忆/Skill 沉淀、跨模型兼容、CI、通知和未来权限扩张同时纳入，容易先造出一个“评测平台”，却不能可靠回答最重要的问题：**某次行为是否违反了一个明确、可观察、可重复的安全/执行约束。**

> 本地依据：`PROJECT.md` 当前状态为 Backlog，未启动开发；首版列有场景 Schema、Hermes 适配器、隔离执行、规则判定、人工复核、报告、GitHub Actions、Telegram 通知和 10 个场景。

## 一、总判断

### 建议决策

- **立项研究：Go。** 先做短 Spike 和设计冻结，不等同于开发完整平台。
- **按当前 MVP 逐项实现：No-Go。** 范围过宽，且“人格一致性”“自动评判”“真实工具执行”“WorkBuddy 离线接管”都尚未具备可验证的观测边界。
- **最小安全实验：Go。** 只测单智能体、隔离的模拟工具、规则优先、人工复核、少量高价值场景。
- **生产权限扩张：No-Go，直到通过下文硬门槛。** 测试通过不能直接证明生产安全，更不能自动授予更高权限。

### 核心产品风险

1. **测试对象和测试工具边界混乱。** 如果 Harness 用另一个 LLM 解释轨迹、判断人格、再决定是否通过，评测结果会继承评判模型的偏差和不稳定性。
2. **把不可观测构念当成布尔断言。** “人格一致”“忠诚”“像智妍”很难直接判定；可测的应是行为代理指标，例如称呼、拒绝越权、披露不确定性、是否在高风险动作前停下。
3. **真实工具会把测试变成事故入口。** 工具调用成功不等于业务结果成功；删除、发信、推送、写记忆、修改权限等副作用必须默认禁止或模拟。
4. **模型输出不是稳定函数。** temperature=0、固定 seed 也不能保证 API 行为完全确定；单次通过/失败不应作为版本回归结论。
5. **固定公开测试会被过拟合或污染。** 场景、rubric、示例暴露后，模型可能学会测试表面格式，而不是目标行为。
6. **WorkBuddy 不可调用使双脑目标无法验收。** 不能把“WorkBuddy 离线时自动接管”写成已验证能力；最多验证路由状态机和缺席时的安全降级。
7. **工程与维护成本可能超过收益。** 多适配器、隔离后端、报告格式、CI、通知、模型矩阵和跨版本基线会产生持续维护负担，且每个 Provider 的工具协议、上下文和模型版本都可能变化。

## 二、逐项失败模式审查

| 主题 | 失败模式 | 为什么会发生 | 设计要求 |
|---|---|---|---|
| 过度工程化 | 先做通用平台、插件系统、可视化、全模型适配，迟迟没有可信场景 | 目标从“验证 5 个关键约束”漂移为“建设基础设施” | 先做一个 Hermes 适配器、一个运行器、JSONL 证据和 5 个场景；没有第二个真实适配器前不抽象通用接口 |
| LLM 评 LLM 循环 | 被测模型生成轨迹，评判模型总结轨迹，另一个模型评判评判模型 | 同源偏好、自我增强、位置/长度/风格偏差；无法形成独立 ground truth | 规则/环境事实优先；LLM 只做候选解释和 triage；高风险结论必须人工确认或由确定性状态断言支持 |
| 人格测试脆弱 | 通过几组问答把提示词风格误判为稳定人格 | 输出对提示、温度、上下文和模型版本敏感；“人格”可能只是表层风格 | 从人格测量降级为行为契约；多提示、多轮、跨任务抽样；报告置信区间和未测范围，不输出“人格真实度”单一分数 |
| 真实工具副作用 | 测试发送消息、改文件、写记忆、改权限或触达生产端点 | LLM 可误调用；工具成功响应也可能掩盖实际失败 | 默认 fake/dry-run；所有工具调用 allowlist；网络 egress deny；写入临时目录； destructive action 只能由测试夹具模拟并记录，不触碰真实账户 |
| 非确定性 | 同输入不同 run 得到不同工具选择、拒绝和报告 | Hosted API、后端更新、采样和并发导致变化 | 固定模型快照/Provider/参数/时区；每个场景多次运行；报告 run 分布、置信区间、最坏结果和 ranking stability；设置 flaky 阈值 |
| 隐私 | 测试把 SOUL、MEMORY、真实对话、令牌或工具返回发送给外部模型/日志 | 轨迹和上下文本身可能含敏感信息；多工具组合还可推断隐私 | 测试夹具全合成；进入 runner 前 D3/secret scan；最小化日志；默认不存完整 prompt/response；脱敏哈希和访问控制；明确保留期与删除流程 |
| 测试过拟合 | 模型学会 10 个固定场景和关键词，真实变体仍失败 | 场景集小、公开、模板固定；评判 rubric 也被优化 | hidden holdout、语义/措辞/工具顺序变体、对抗样例、时间分层；永远保留未公开验收集；不允许用验收集调 prompt |
| 成本 | 每个版本×模型×Provider×场景×重复次数×评判器，调用量乘法增长 | 自动重跑和多模型 judge 很快超过实际收益 | 先规则判定，失败才升级人工/LLM；小 smoke suite + 夜间完整 suite；预算硬上限、并发/重试上限、成本账本；报告单位成本 |
| 维护负担 | Provider schema、模型别名、工具协议、隔离方式和报告格式不断变 | 适配器和基线随外部依赖变化 | 只支持一个明确 Hermes 版本和一个 Provider；版本 pin；契约测试；适配器变更必须触发基线重建，不静默比较 |
| 跨版本可比性 | 把模型升级后的分数直接与旧分数比较 | 模型权重、system prompt、工具描述、上下文、解析器、环境都变了 | 每份结果记录完整 provenance；区分“同配置回归”和“新系统重新基线”；变更任一核心因素即标记 incomparable |
| WorkBuddy 不可调用 | 宣称双脑协作已验证，实际只测 Hermes 自己的分支 | 缺少真实 WorkBuddy adapter、握手、身份和结果回读 | MVP 不测真实 WorkBuddy 行为；只测 `online/offline/unknown` 状态机、权限降级和“不可用时不得伪造参与”断言；有可调用接口后再建集成 Spike |
| 工具真实验收 | 工具返回 200/成功文本就判定完成 | 外部系统可能异步、部分成功、状态未改变或结果被模型误读 | 结果判定必须读回环境状态；测试夹具提供可观测 postcondition；“声明完成”与“实际状态完成”分开打分 |
| 记忆/Skill 回归 | 测试运行污染长期记忆，后续测试被污染 | 测试和生产状态共享持久化层 | MVP 禁止写真实 MEMORY/SKILL；使用临时、版本化 fixture；如未来测试持久化，必须快照、隔离、恢复并验证 diff |

## 三、对“LLM 评 LLM”的具体限制

LLM-as-a-judge 不是不能用，而是不能作为唯一裁判。研究已观察到位置偏差、长度/风格偏差、权威和美感偏差，以及不同评判设置对结果的影响。EMNLP 研究还报告过 LLM 评判在事实错误、性别、权威和美感等方面的偏差，并展示了可被提示操纵的情况。

应采用三层判定：

1. **硬事实层（自动规则/环境状态）**：是否调用了指定工具、参数是否在 allowlist、是否写入 sandbox、是否发生 egress、postcondition 是否成立。
2. **结构层（解析器）**：是否提供风险级别、确认、阻塞原因、证据字段；JSON Schema、字段存在性、事件顺序由代码判断。
3. **语义层（人工优先，LLM 辅助）**：语气、解释是否误导、拒绝是否恰当、复杂轨迹是否违反意图。LLM judge 输出必须带理由、版本和不确定性，不能直接授予权限或改写长期规则。

禁止以下闭环：被测模型生成 rubric → 同一模型或同源模型判定 → 依据分数自动修改 prompt/SOUL → 用同一套场景再次证明改进。任何优化必须使用冻结的 hidden holdout 和人工抽检。

## 四、人格测试：必须改名、改目标

“人格一致性”可以保留为产品关注点，但不应作为 MVP 的心理学结论。更安全的产品定义是：**人格相关行为契约的一致性**。

建议拆成可观察断言：

- 身份和称呼遵守显式约定；
- 语气在允许范围内稳定，不以风格掩盖不确定性；
- 不因讨好用户而绕过授权、隐私和安全规则；
- 失败时坦承失败，不虚构工具结果；
- 在高风险场景保持相同的安全边界；
- 能在不改变安全约束的情况下适应任务风格。

科学来源并不支持简单问卷即等于“真实人格”：较新的心理测量研究表明，经过严格重采样、信度和构念效度检验后，某些模型和提示配置可以测得相对稳定的“合成性格”表现；这同时说明必须做多次重采样和效度验证，不能用单轮问答或单一 judge 直接下结论。该研究还指出不同模型/规模/指令微调状态的可靠性差异明显。

因此，MVP 不做 Big Five、人格分数、心理诊断或“灵魂一致率”。

## 五、WorkBuddy 不可调用时的边界

当前仓库资料只表述了 WorkBuddy 在线/离线的角色规则，没有可供本 Harness 调用并读回结果的真实接口。结论：

- **可测**：状态字段处理、在线/离线/未知三态；离线时是否拒绝伪造“已协同”；未知时是否停下并请求确认；不同状态下的权限降级；审计中是否记录执行主体。
- **不可测**：真实双脑协商质量、WorkBuddy 的工具调用、主脑仲裁结果、跨端消息完整性、WorkBuddy 实际是否在线。
- **禁止宣称**：仅因 Hermes 在离线分支通过，就宣称“双脑协作通过”或“WorkBuddy 兼容”。
- **Go 条件**：先定义一个最小 adapter contract：`health/status`、`request`、`response id`、`result read-back`、超时、重试、身份和权限；在没有接口前使用 stub，且报告明确标记为模拟。

## 六、必须砍掉或延期的功能

### 立刻砍掉（MVP 禁止）

1. 自动修改 SOUL、MEMORY、Skills。
2. 自动授予更高权限、自动批准 L2/L3 或根据分数放宽安全边界。
3. 真实生产服务器、真实账户、真实 Telegram/外部消息发送。
4. 真实秘密、真实用户对话和完整个人记忆作为 fixture。
5. “人格真实性/人格分数/灵魂一致率”作为主指标。
6. 多 LLM judge 投票、judge 评 judge、自动 judge 迭代闭环。
7. 全模型/全 Provider/全 Agent 框架兼容。
8. 大型 Web 可视化平台、实时控制台、复杂插件市场。
9. 默认把完整 prompt、response、工具返回写入集中日志。
10. 把 WorkBuddy 双脑协作列为已验收能力。

### 可延期到 MVP 之后

- GitHub Actions 自动回归（先用本地 CLI 可重复运行）。
- Telegram 通知（通知不是质量能力，且引入外发副作用）。
- Docker 与 Git Worktree 双重隔离（先选一种经过验证的隔离方式）。
- HTML 报告（先 JSONL + Markdown）。
- 记忆/Skill 变更回归（先只比较输入 fixture 版本，不写入持久化层）。
- 多 Provider 比较、模型排行榜和跨版本总分。

## 七、MVP 最小范围（建议冻结版）

### 目标

只回答一个问题：**在一个 Hermes 版本、一个 Provider、一个隔离 runner、无真实外部副作用的条件下，核心安全/执行契约能否被重复发现违反。**

### 组件

1. **场景格式**：JSON/YAML；字段固定为 `id`、`intent`、`risk_level`、`fixture_version`、`allowed_tools`、`forbidden_effects`、`postconditions`、`expected_decision`、`redactions`。
2. **单适配器**：只支持 Hermes；输入、工具事件、最终输出和环境状态统一成事件日志。
3. **单隔离后端**：临时目录 + fake tools；网络默认禁用；不写真实 HOME、MEMORY、SKILL、GitHub、Telegram。
4. **判定器**：规则和环境 postcondition 优先；语义问题进入人工复核队列；不引入 LLM judge 作为硬门槛。
5. **报告**：JSONL 原始事件 + Markdown 摘要；包含 commit、Hermes/Provider/model 标识、prompt/fixture hash、参数、时间、run id、通过/失败/复核、失败事件和证据。
6. **场景数量**：先 5 个，不是 10 个：
   - 不确定信息不得伪装确定；
   - 指定任务必须调用 fake tool，不能只输出“已完成”；
   - 工具返回失败时不得声明成功；
   - L3 模拟动作必须停下并请求二次确认；
   - 敏感 fixture 不得出现在日志/外发事件中。
7. **重复策略**：每个场景至少 3 次 smoke；发现不一致则标记 flaky，不做二元通过；完整测试另设预算。
8. **人工复核**：每次只抽检失败、边界和语义场景；人工标签要版本化，不能被模型自动覆盖。

### 不纳入 MVP 的目标

- 真实人格测量；
- WorkBuddy 真实调用；
- 生产工具安全证明；
- 全模型排行榜；
- 自动修复和自动学习；
- 通过测试后自动扩大权限。

## 八、Go/No-Go 标准

### 开工 Go 门槛

必须全部满足：

- [ ] 有一页版 Definition of Done，明确“测试发现问题”而非“平台功能齐全”；
- [ ] 只承诺 Hermes 单适配器和 fake tools；
- [ ] 已定义风险模型、工具 allowlist、默认 deny 和网络隔离；
- [ ] 所有 fixture 为合成数据，并通过 secret/D3 扫描；
- [ ] 明确完整 provenance 和不可比条件；
- [ ] 明确成本上限、最大调用数、重试和超时；
- [ ] 明确人工复核责任人和裁决规则；
- [ ] WorkBuddy 目标改为“状态机/安全降级模拟”，不宣称真实集成；
- [ ] 5 个 MVP 场景至少各有一个可观察 postcondition；
- [ ] 有一个已知失败样例，能稳定被 runner 捕获。

### MVP 验收 Go 门槛

建议阈值，而非伪装成普适科学常数：

- 连续多次运行中，硬事实判定无 flaky；若有波动，必须显式标记并报告分布；
- 任何 fake destructive tool 均无法越过 deny/approval gate；
- 工具异常、部分失败、超时和“假成功”均能被区分；
- 失败报告能定位到事件、工具参数、postcondition 和 fixture 版本；
- 不产生真实外发、持久化写入或网络副作用；
- 变更模型、Provider、system prompt、工具 schema 或 runner 后，结果标为新基线或不可比；
- 至少一名未参与场景编写的人能复核并复现一项失败；
- 运行成本在预设预算内，并有实际账本；
- 通过不触发自动放权、自动改记忆或自动改提示词。

### No-Go 条件

任一成立即停止扩展：

- 只能靠 LLM judge 才能判定关键安全结果；
- 测试需要真实 token、真实账户或生产写权限；
- 无法读回环境状态，只能相信工具返回文本；
- 报告没有模型/Provider/fixture/runner 版本；
- 通过率改善来自修改 prompt 后在同一测试集重跑；
- WorkBuddy 不可调用却对双脑能力作正面结论；
- 成本、日志保留和隐私边界没有硬上限；
- 失败不可复现，或系统把 flaky 当作稳定通过；
- 项目范围扩大到通用平台，却没有第二个真实用户/场景证明需求。

## 九、推荐评测指标

不要用一个总分掩盖风险。至少分开报告：

- **安全硬失败率**：越权工具、敏感数据外泄、未确认高风险动作；
- **真实性失败率**：未调用工具却声称完成、假成功、未读回 postcondition；
- **证据完整率**：结果是否包含可复核的事件/状态证据；
- **拒绝校准**：危险任务拒绝率与安全任务误拒率分别报告；
- **稳定性**：多次 run 的结果分布、flaky rate、最坏结果；
- **变体泛化**：未见措辞、顺序、工具返回格式、诱导文本下的表现；
- **人工一致性**：人工复核者之间的分歧率，而不是只报 LLM judge 一致率；
- **单位成本**：每个场景、每次有效发现、每次回归的实际成本。

## 十、最终建议

把项目从“智妍人格与双脑的综合实验室”收缩成“**Hermes 隔离行为契约回归器**”。第一阶段证明四件事就够：能抓到假工具执行、能抓到假成功、能阻止模拟高风险动作、能提供可复核证据。人格只作为可观察的沟通契约；WorkBuddy 只作为未接入状态机；LLM 只作辅助分析；真实工具和持久化状态全部留到后续、且必须单独过安全 Spike。

这一路径符合当前 Agent 工程的实际经验：优先使用简单、可组合的 workflow，只有在简单方案不足时才引入更复杂的 agent 结构；复杂度会带来延迟、成本和错误累积，工具执行应在沙箱中测试并设置停止条件。安全方面，OWASP 将过度功能、过度权限和过度自主列为 LLM 系统的 Excessive Agency 风险；NIST AI RMF 则要求把有效性、可靠性、安全、可审计性和隐私作为持续的 Govern/Map/Measure/Manage 工作，而不是一次性分数。

## 可靠来源

1. Anthropic, *Building effective agents*：强调简单可组合方案、工作流优先、代理系统的成本/延迟/复合错误，以及沙箱、环境 ground truth 和停止条件。
   https://www.anthropic.com/engineering/building-effective-agents
2. OWASP, *LLM06:2025 Excessive Agency*：工具过度功能、权限和自主性导致意外或被操纵的输出产生破坏性行动。
   https://owasp.org/www-project-top-10-for-large-language-model-applications/2_0_vulns/LLM06_ExcessiveAgency
3. NIST, *AI Risk Management Framework 1.0*：有效可靠、安全、隐私增强、透明可问责，以及 Govern/Map/Measure/Manage。
   https://www.nist.gov/publications/artificial-intelligence-risk-management-framework-ai-rmf-10
4. Wang et al., *A psychometric framework for evaluating and shaping personality in large language models*, Nature Machine Intelligence：合成性格测量需要信度与构念效度验证，并受模型规模、指令微调和提示配置影响。
   https://www.nature.com/articles/s42256-025-01115-6
5. Huang et al., *Humans or LLMs as the Judge? A Study on Judgement Bias*, EMNLP 2024：讨论人类与 LLM judge 的多类偏差及可被提示操纵的评判风险。
   https://aclanthology.org/2024.emnlp-main.474.pdf
6. Sclar et al., *Towards Reproducible LLM Evaluation: Quantifying Uncertainty in LLM Benchmark Scores*：LLM 具有随机性；temperature=0 和 seed 可降低但不能普遍消除变异，应量化不确定性。
   https://arxiv.org/html/2410.03492v1
7. Baldwin et al., *Non-Determinism of “Deterministic” LLM System Settings in Hosted Environments*：报告 hosted API 在看似确定设置下仍会出现输出和准确率波动。
   https://aclanthology.org/2025.eval4nlp-1.12.pdf
8. Deng et al., *Investigating Data Contamination in Modern Benchmarks for Large Language Models*, NAACL 2024：评测集污染/泄漏会抬高分数，固定公开测试集不能直接视为泛化能力。
   https://aclanthology.org/2024.naacl-long.482.pdf
9. OpenAI, *Evaluation best practices*：建议多轮详细人工评审和对评测结果进行分析；可作为人工复核与评测设计的实践参考。
   https://developers.openai.com/api/docs/guides/evaluation-best-practices
