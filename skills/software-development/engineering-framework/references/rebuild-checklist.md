# 重建 / 重写检查清单（云瞳 / KPanel 风格）

适用：删除旧部署后重新写后端或前端、或全量重构安全平台时。

## 先清再建（数据层先于代码）
1. 先删测试残留（DB 残留卡片、重复 host、旧 token）→ 再修代码护栏（否则旧污染仍在列表）
2. 清残留时保留用户真实资产（#2 reached），仅删测试残留（#3-#6），记录清后状态（SELECT id,host,status）
3. 数据库重建：先 DROP → 再 CREATE DATABASE → 跑迁移（01→08）→ 验证表存在 + schema_version
4. 提交前现场验证：git rev-parse --short HEAD + DB 现场复查 + 服务 health 200

## 代码修改纪律
5. 先完整读参考源码（KPanel / 旧版）再动手，反对直接在 /root 写新文件
6. API 层加 host 去重护栏（409 拒重）— 同 host 已存在直接拒绝，不依赖支持端修复
7. verify.sh / 测试脚本幂等：先 GET 查已有再决定 POST，已有则复用 id
8. agent token 吊销双侧验证：revoke 路由（revoked_at=NOW()）+ push 鉴权（revoked_at IS NULL）→ 真实 curl 确认 401
9. 全批提交需用户明确授权（"全批 允许提交"），否则不推断

## 部署同步（Vue / nginx / DB）
10. 构建：vite build → dist/ 同步到站点目录（/home/web/html/yuntong.taoque.top/web/）
11. API 同步：cp api/lib + api/public + api/cron 到站点 api/，保留 .env
12. nginx：写 vhost 配置（root 指向 web/，/api/ 指向 PHP-FPM）→ nginx -t → reload
13. DB 连接：PHP 容器用 docker 网络（mysql 容器名或 172.18.0.x IP），非本地 socket
14. 外部重定向：HTTP → HTTPS 重定向由外部代理/证书处理，本地只需保证 HTTPS 200
15. 面板说明：哪吒面板风格卡片（4 功能 + 4 修 + 总结）嵌入每页 template 开头
