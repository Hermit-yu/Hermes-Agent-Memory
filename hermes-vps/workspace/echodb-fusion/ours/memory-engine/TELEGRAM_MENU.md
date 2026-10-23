# Telegram 菜单（Bot Commands）接入说明

宝贝，你要求把 `echodb` 命令加到 Telegram 菜单里。

说明：Telegram 的“命令菜单”（输入框左侧的 /commands 列表）一般需要通过 **BotFather** 或 Telegram Bot API 的 `setMyCommands` 来设置。OpenClaw 这边我可以提供：
- 命令清单（你复制粘贴到 BotFather）
- 或者如果你这边的 OpenClaw/Telegram 插件支持设置 commands，我再帮你写入对应配置

## 推荐命令清单（MVP）

```
echodb - EchoDB 工具入口
memory_search - 搜索记忆（BM25/Hybrid）
memory_stats - 记忆统计
memory_reindex - 重建索引
```

## BotFather 设置步骤（你操作一次就行）
1) 打开 BotFather
2) `/mybots` → 选择你的 bot
3) `Edit Bot` → `Edit Commands`
4) 粘贴上面的命令清单

完成后，Telegram 菜单就会出现这些命令。
