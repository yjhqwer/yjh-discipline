# yjh-discipline

**治好你的编程 agent：瞎猛干、撑爆上下文、无视已装技能。**

三个针对 AI 编程 agent（Claude Code、Codex、Cursor、Gemini CLI、Antigravity、OpenCode 等）的纪律补丁。它们看起来各自独立——其实缺一不可，少了任何两个，剩下的那个也会失效。

> 最好的代码和配置，是全球社区已经实战检验过的那些。

---

## 三大失效模式

三个你都见过，而且大多数 agent 是三个一起犯。

### 1. 不会委派——你的上下文被淹死

agent 在主线程里干所有事：几十次 grep 和 read、整文件倾倒、搜索结果直接贴进对话。等它找到答案时，上下文窗口已经被噪声塞满，之后每一轮都要为这些噪声重复付费，半小时前定的计划早已跌出注意力范围。

| 改前（主线程猛干） | 改后（委派出去） |
|---|---|
| 几十次 `grep`/`read`/抓取调用灌满对话 | 抛弃式子代理在自己干净的窗口里翻完所有材料 |
| 直接读 872KB 文件：一次调研 **158 万 token、45 次工具调用**（作者实测） | 同样的任务加上结构化简报：**约 11 万 token**，一屏纸的裁定返回 |
| agent 干着干着忘了目标 | 主线程只留结论，不留证据 |

### 2. 猛干不找先例——闭门造车

接到新功能、新配置、新集成，agent 凭想象开写：为已有 2 万 star 现成库的问题手搓方案、写出跑不起来的配置、重新发明已有标准。写代码很有趣，查查别人是不是早就解决了很无聊——所以 agent 会跳过无聊的那步。

| 改前（先猛干） | 改后（先搜索） |
|---|---|
| 给有成熟库的问题手写定制方案 | 先找到实战检验过的实现 |
| 没有任何"不存在更好方案"的证据 | 每个决策以裁定收尾：**Adopt / Extend / Compose / Build** |
| 因为瞎猜 API 用法而出一堆 bug | 第一行代码写下之前，坑已经记录在案 |

### 3. 无视你装的技能

技能是惰性加载的。装了的技能在 agent 主动去找它之前**什么都不做**——而 agent 的默认是不去找。作者亲眼看着一个装好的方法论技能**连续数月零次自动触发**。从不触发的技能，只是个名字好听的死文件夹。

| 改前（装完就祈祷） | 改后（强制路由） |
|---|---|
| 技能躺在 `~/.agents/skills/` 里，agent 从不提起 | 指令文件里一条常驻规则，强制 agent 在非常规任务前先查技能列表 |
| "我不知道还有个技能能干这个" | 每个会话都核对技能清单，触发稳定可靠 |

---

## 为什么必须联立解决（三位一体）

每个补丁都在堵另外两个补丁留下的口子：

- 只解决 **②**（"去找现成方案！"），agent 就在**主线程里搜**——刚治好猛干，又患上上下文爆炸（①）。
- 只解决 **①**（委派）而没有搜索纪律，你会得到一批**并行重新发明轮子**的 agent（②）。
- 用技能解决两者但没有路由层，**什么都不会触发**（③）。

```
┌─────────────────────────────────────────────────────────────┐
│  1. 看门狗（写进 AGENTS.md / CLAUDE.md 的规则层）             │
│     强制路由：写码前先找先例；大范围翻阅必须委派；             │
│     动手前先核对技能清单。                                    │
└──────────────────────────────┬──────────────────────────────┘
                               │ 强制触发
                               ▼
┌─────────────────────────────────────────────────────────────┐
│  2. 战术工具箱（Agent Skills）                                │
│     prior-art-search：检索 SOP + Adopt→Extend→Compose→Build  │
│     裁定阶梯。                                                │
│     delegate-or-die：委派时机 + 自足式简报格式。               │
└──────────────────────────────┬──────────────────────────────┘
                               │ 委派执行
                               ▼
┌─────────────────────────────────────────────────────────────┐
│  3. 抛弃式子代理                                              │
│     所有搜索和翻文件都在隔离上下文里跑完，                      │
│     只向主线程返回裁定（<250 词），绝不返回证据本身。           │
└─────────────────────────────────────────────────────────────┘
```

哪一层治哪个失效模式——以及为什么这个分法没得商量：

| 失效模式 | 规则层（每轮在场） | 技能层（按需加载） |
|---|---|---|
| ① 不会委派 | 触发行：">3 个文件 → 派子代理；简报必须自足" | `delegate-or-die`：完整简报解剖与输出契约 |
| ② 猛干不找先例 | 触发行："先搜索；Adopt → Extend → Compose → Build" | `prior-art-search`：检索顺序与裁定报告 |
| ③ 无视技能 | 路由规则——**只能放规则层** | ——治不了：技能治不了自己的不触发 |

**规则决定何时做，技能决定怎么做，子代理负责干活。**

---

## 仓库内容

```
yjh-discipline/
├── rules-template.md              # 看门狗：粘贴进 AGENTS.md / CLAUDE.md / GEMINI.md
└── skills/
    ├── prior-art-search/SKILL.md  # 先例检索 SOP + 裁定阶梯
    ├── delegate-or-die/SKILL.md   # 委派时机 + 自足式简报格式
    └── j-space/                   # 非常规任务的思考工作区（完整套件：9 个模块、参考、控制器）
```

**j-space** 是作者的原创方法论技能，理论根基是 Anthropic 的可解释性研究 [《Verbalizable Representations Form a Global Workspace in Language Models》](https://transformer-circuits.pub/2026/workspace/index.html)（Gurnee 等，2026 年 7 月）——正是这篇论文发现并命名了模型内部的 **J-space** 工作区。这个技能把发现变成了可操作的方法：每个任务先分档（fast / full / loop）、长任务靠五行台账延续状态、在工作区里想而不是在纸上想。规则模板用第四条触发行把它路由起来：非常规任务先加载技能再动手。

## 安装

**任何支持 [Agent Skills 标准](https://agentskills.io) 的 agent**（Claude Code、Codex、Cursor、Gemini CLI、OpenCode、Antigravity 等 60+ 个）：

```bash
npx skills add yjhqwer/yjh-discipline
```

**手动安装**：把任意 `skills/<名字>/` 文件夹复制进你 agent 的技能目录（`~/.claude/skills/`、`~/.agents/skills/` 等）。

**看门狗规则**不是技能——它必须写进 agent 的指令文件，每个会话才会被看到。把 `rules-template.md`（或其中你需要的章节）复制进 `AGENTS.md` / `CLAUDE.md` / `GEMINI.md`。没有这一层，技能很少会自己触发——这正是失效模式③。

## 设计原则

- **只写模型推不出的东西。** 规则描述失效模式和默认行为，不堆玩具式触发清单。
- **流程进技能、常驻禁令进规则、一次性要求进对话。** 每层只干一件事。
- **质量优先，不设预算。** 子代理简报定义输出契约，从不设 token 上限——预算让 agent 变怂，契约让 agent 变准。
- **状态先行回报。** 每个委派任务在任何内容之前先返回 `STATUS: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT`，让一次失败的委派只花一行字，而不是一堵墙。

## 实测过，不是只写了

三个技能加路由规则在隔离的 agent 会话里做过触发实测（模型为 flash 档的 GLM-5.3-Flash），每次工具调用都从会话日志核实过：

| 测试题 | 预期 | 结果 |
|---|---|---|
| "把登录模块看明白，相关文件都读一遍" | 委派出去，主线程保持干净 | ✅ 1 个子代理包揽全部 6 次文件读取，主线程只抽查并转述结论 |
| "加一个请求失败自动重试" | 写码前先搜先例 | ✅ 加载 prior-art-search；调研子代理跑了 7 次网页抓取（主线程 0 次）；动第一行代码前给出带证据的 `Verdict: Build` |
| "把变量 usr 改成 user" | 什么都不该触发 | ✅ 工具记录只有 Read → Edit，零技能、零派发、零联网 |
| "规划一次 src/auth 重构：抽出 session 服务，只出提纲不写码" | 动手前先加载 `j-space` | ✅ 第一个工具调用就是 `Skill: j-space`；随后加载 delegate-or-die、派 1 个只读子代理去翻文件——prior-art-search 正确保持沉默（重构豁免） |

正反用例双双通过：该触发的触发，不该触发的不吵不闹。

## 出处与致谢

本仓库是一次 *Extend* 而非 *Build*——它组合了社区已经验证过的想法：

- [anthropics/skills](https://github.com/anthropics/skills)——Agent Skills 格式与生态
- [obra/superpowers](https://github.com/obra/superpowers)——证明技能式纪律可以规模化有效（也反证了轻量的必要：本仓库只有它约 2% 的体积）
- [shimo4228/search-first](https://github.com/shimo4228/search-first) 与 [anombyte93/claude-research-skill](https://github.com/anombyte93/claude-research-skill)——先例检索 SOP
- [techygarg 的 subagent-cost-economy](https://gist.github.com/techygarg/f8f98a2f026538fad4a69b593a964d95)——"保护主线程、委派调研"的成本论证
- [jbarbier/CLAUDE.md](https://github.com/jbarbier/CLAUDE.md)——规则文件作为"工作契约"的提法
- Karpathy 精神的极简规则集：[multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills)、[vinta/hal-9000](https://github.com/vinta/hal-9000)
- Anthropic 的可解释性研究：[《Verbalizable Representations Form a Global Workspace in Language Models》](https://transformer-circuits.pub/2026/workspace/index.html)（Gurnee、Sofroniew、Lindsey 等，2026 年 7 月）——**J-space** 的发现。随仓库发布的 `j-space` 技能构建在这一发现之上，技能本身为作者原创。

本仓库没有复制上述任何项目的文本——借的是思想，而按本仓库自己的规则，借了思想就要署名。

"三位一体"框架——规则负责路由、技能负责方法、子代理负责执行、三者缺一不可——是本仓库的增量。

## 许可

MIT。如果它救过你一次上下文窗口，给个 ⭐。
