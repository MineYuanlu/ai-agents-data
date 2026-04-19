# AI Agents Data

一个集中管理 AI 智能体配置、系统提示词和部署工具的仓库，支持多种 Vibe Coding 平台。

## 概述

本仓库提供：

- **智能体定义**：预配置的角色，包括项目管理、调试、文档生成等
- **提示词模板**：支持变量替换的可复用模板
- **部署脚本**：本地开发环境的一键设置工具
- **跨工具支持**：兼容 OpenCode、Claude Code、Qoder、Cursor 和 Roo Code

## 支持的平台

| 平台                                  | 状态        | 配置路径                 |
| ------------------------------------- | ----------- | ------------------------ |
| [OpenCode](https://open-code.ai)      | ✅ 逐步支持 | `.opencode/agents/`      |
| [Claude Code](https://claude.ai/code) | ✅ 逐步支持 | `CLAUDE.md` / `.claude/` |
| [Qoder](https://qoder.com)            | ✅ 逐步支持 | `.qoder/agents/`         |
| [Cursor](https://cursor.com)          | 🚧 计划中   | `.cursor/rules/`         |
| [Roo Code](https://roocode.com)       | 🚧 计划中   | `.roorules`              |

## 快速开始

### OpenCode 设置

```bash
# 克隆本仓库
git clone https://github.com/MineYuanlu/ai-agents-data.git
cd ai-agents-data

# 部署智能体到你的项目
mkdir -p .opencode/agents
ln -sf ../../opencode/agents/*.md .opencode/agents/
ln -sf ../../opencode/agents/template .opencode/agents/
# 后期都会提供一键脚本
```

### 使用智能体

部署完成后，可以在 OpenCode 中调用智能体：

```
@project-manager "规划用户认证功能的实现"
@debugger "分析构建失败的原因"
@documenter "为支付模块创建 API 文档"
```

## 仓库结构

```
.
├── opencode/
│   └── agents/
│       ├── agents.md      # 直接可用的智能体定义
│       └── template/      # 需要二次配置的智能体模板
│           └── builder.md
├── tools/                 # 部署工具
└── docs/                  # 补充文档
```

## 许可证

MIT 许可证 - 详见 [LICENSE](./LICENSE) 文件。

## 未来路线图

- [ ] 所有支持平台的部署脚本
- [ ] 跨平台格式转换器
- [ ] 预设模板库
- [ ] 智能体语法 CI 验证
- [ ] 基于网页的智能体构建器

---

为 AI 编程社区打造 ❤️
