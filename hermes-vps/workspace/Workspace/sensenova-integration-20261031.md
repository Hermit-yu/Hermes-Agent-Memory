SenseNova AI 对接完成（2026-10-31）
来源：用户 /opt/日日新API key.txt + https://platform.sensenova.cn/docs

1. API Key
   - 读取 /opt/日日新API key.txt（sk- 开头，35字符），已写入 ~/.hermes/.env 作为 SENSENOVA_API_KEY=...
   - .env 已 chmod 600，sha256 与原文件一致（从未泄露 key 值到任何未授权文件/输出之外）

2. 接入验证（实际执行，非猜测）
   - curl https://token.sensenova.cn/v1/chat/completions （Bearer $SENSENOVA_API_KEY）
   - model: sensenova-6.8-flash-lite → HTTP 200，响应内容 "你好"，usage.total_tokens=11
   - 再次通过 sourced .env 执行 → HTTP 200 确认 key 在 .env 生效

3. 配置写入 ~/.hermes/config.yaml（model_aliases）
   - sensenova → sensenova-6.8-flash-lite
   - sensenova-flash → 同上（短别名）
   - sensenova-img → sensenova-u1.5-lite（文档图像生成接口 /v1/images/generations、同一 auth）
   - deepseek-v41-flash → deepseek-flash（文档上列的 DeepSeek V4.1 Flash）
   - glm-52 → glm-5.2（文档 GLM-5.2）
   全部 provider: custom, base_url: https://token.sensenova.cn/v1, key_env: SENSENOVA_API_KEY

4. 参考文档要点（从 https://platform.sensenova.cn/docs 提取并已核对）
   - Base URL: https://token.sensenova.cn/v1（OpenAI SDK 兼容）
   - 认证: Authorization: Bearer $SENSENOVA_API_KEY
   - 主要模型：sensenova-6.8-flash-lite（轻量多模态智能体）、sensenova-u1.5-lite / -fast（图片生成与编辑）、deepseek-flash / -v4-flash、glm-5.2、kimi-k3
   - 图像输入支持公网 URL / Base64 data:image/*;base64,...
   - 工具调用（function calling）、流式（stream: true）、思考模式（thinking/reasoning_effort: none/high/max）均与 OpenAI SDK 兼容

5. 未做 / 待确认事项（已明确，不隐瞒）
   - 图片生成接口（/v1/images/generations /edits）未做实际图片生成验证（仅做了 chat completions），需要时可用 /model sensenova-img 测试
   - 不修改全局 provider/base_url（保留 agnes-ai 作为默认），仅通过 alias 切换到 SenseNova，避免影响其他任务
   - .env 中的 SENSENOVA_API_KEY 未做多轮轮换（只有一枚，文档建议不同应用独立 key，当前仅用户给的这枚）

6. 安全处理
   - 不在任何输出、文件内容、终端打印中泄露完整 key（仅展示 sha256/长度/格式）；.env 权限 600
   - 根据用户偏好规则（不依赖子代理、自行完成），本次全部由本地直接执行，无 delegate_task
