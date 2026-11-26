# verify 包样例（虚构）

本目录是 **模板**，复制到 `artifacts/{需求}-qa/T1/verify/` 后按 T1-04 改写。

## 硬约束

- `cases.json` 的 `method` / `path` / `headers` 键 / `body` 键 **必须**出现在对应接口卡上。  
- 禁止增加卡上没有的路径或字段来「先跑通再说」。  
- 账号与令牌只写 `env.local`（不入库）；提交前确认无 `out.txt`。

## 与卡的对应（本样例）

虚构卡 `I-01`（AC-01 主路径）、`I-02`（AC-02 无权限反例）——见下方注释；真实需求以 `T1-04-接口卡.md` 为准。

| case id | card | 卡上字段（节选） |
|---------|------|------------------|
| C-01 | I-01 | POST `/{svc}/adminapi/demo/_search`；Header Authorization；body page,size |
| C-02 | I-02 | 同 path；用无权限 TOKEN；期望拒绝 |

## 文件

| 文件 | 作用 |
|------|------|
| `cases.json` | 用例；只引用已取样字段 |
| `env.example` | 变量名说明 |
| `run.ps1` / `run.sh` | 读 env → 请求 → 断言 → `out.txt` |
