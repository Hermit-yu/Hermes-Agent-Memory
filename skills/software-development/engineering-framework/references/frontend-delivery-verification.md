# 前端/SPA 交付验证与黑屏排查 recipe

适用：声明"前端已做完/可用"之前；或用户报"只有标题、内容空白/黑屏"。核心原则：**页面返回 200 只证明 HTML 壳能下，不证明 JS 渲染出了内容**。必须真浏览器端到端验证。

## 症状 → 根因

| 症状 | 最可能根因 | 定位命令 |
| --- | --- | --- |
| 只有顶栏/标题，内容区全黑 | App.vue 用了 `<router-view>`/动态 ViewMap，但 `main.js` 没 `createRouter`/没接 hash 路由，路由没注册 | `grep -rn 'createRouter\|location.hash\|ViewMap' src/main.js src/App.vue` |
| 某页空白、其它页正常 | 该视图被覆盖成"说明卡片壳"（丢了 `api.*` 数据绑定 + `v-for`） | `grep -c 'api\.' src/views/X.vue`（0 或极少 = 被壳化）；对照 `git show HEAD:src/views/X.vue` |
| 内容在但数据不对/乱码 | 数据源 charset 或后端字段名与前端 shape 不一致 | 浏览器 Network 看真实 JSON；对齐 API struct 的 `json:` tag |

## 恢复误覆盖的功能版（最快路径）

1. 别在覆盖后的壳上继续堆。先 `git status --short` 看哪些视图被改。
2. 若基线是可用的功能版：`git checkout -- <被覆盖的视图/组件/App.vue>`（一次性恢复，保住真实数据绑定与路由）。
3. 只把**追加性**改动（说明卡片、新字段）在恢复版上重新叠加，不整文件替换。
4. 重新 `vite build` → 同步 dist → 站点 → 浏览器验证。

## 真浏览器端到端断言（build 成功 ≠ 能用）

1. 打开面板 → 走真实登录（用户名/密码填表单 + 触发 input 事件，`dispatchEvent(new Event('input',{bubbles:true}))`，否则 Vue 绑定吃不到值）。
2. 逐路由切换（SPA 用 `location.hash = '#<page>'`），每个页面 `read document.body.innerText`。
3. 断言 `innerText` 含**预期实时数据**（资产名/审计时间戳/统计数字），而不只是静态标题。出现 `Ã…` 双字节乱码 = 数据层 charset 问题（写 UTF-8 忘了 `--default-character-set=utf8mb4`）。
4. 空态（"暂无发现"）不等于坏——要确认是"数据源确实空"而非"没请求到"：看该页有没有触发对应 API、回包 200。

## 判定"前端可用"的最低证据

- 登录门可进 + 每个路由渲染出对应内容（innerText 非空且含数据）。
- 至少一个真实数据回包（非 mock）能上屏。
- 没有黑屏路由。三者齐了才可报"前端已交付"；缺任一报"骨架/待接入"。
