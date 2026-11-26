---
name: test-overview
description: software-test-sop 总纲：T0→T1→T2→T3；取样优先级；缺事实停问；门禁三态；接包最小集；SOP 约束。开工、不确定阶段、改 test-sop、或其他 skill 引用「生命周期 ›」时读本目录文件。
---

# test-overview

本目录是 software-test-sop 总纲：

- [生命周期.md](生命周期.md)：阶段出口、取样、门禁、执行循环、当前位置、单一真相源。
- [SOP约束.md](SOP约束.md)：改 test-sop 的硬约束。

## 该用哪个 skill

| 时机 | skill |
|------|-------|
| 建/补测试手册（基址、鉴权、信封、探活） | `test-t0-handbook` |
| 接包、拆 AC、取样、写接口卡与 cases | `test-t1-design` |
| 按卡执行、记结果证据 | `test-t2-execute` |
| 失败项出可复现缺陷单 | `test-t3-defect-handoff` |

## 开工前先读

1. `artifacts/{需求}-qa/00-当前位置.md`（有则继续；无则判阶段）。
2. `artifacts/_project/T0-01-测试手册.md`（无则先 T0；不全禁止宣称 T2 接口验收通过）。
3. `生命周期.md`：取样优先级、缺事实停问、门禁、当前位置。

每阶段、T2 每轮开新会话；只靠 `00-当前位置` 与 `artifacts/` 接续。对话末条只发「你要做的」正文。

## 三条总规则

1. skill 只写通用流程；项目/需求专有进手册或 `{需求}-qa/`。
2. 一事实一处：通识在 T0，契约在 T1-04，结果在 T2，缺陷在 T3；别处引编号。
3. 门禁三态如实；臆造 path/body 不算证据。出口规则见生命周期。
