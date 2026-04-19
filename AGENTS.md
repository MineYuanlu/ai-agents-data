# AI Agents Data Repository

This repository stores and manages AI agent configurations, prompts, and deployment tools for OpenCode, Claude Code, Qoder, and other Vibe Coding platforms.

## Purpose

Centralized storage for:

- Agent role definitions and system prompts
- Task-specific prompt templates
- One-click deployment tools for agent files
- Cross-tool configuration converters

## Repository Structure

```
/
├── AGENTS.md                    # This file
├── opencode/                    # OpenCode-specific agents
│   └── agents/
│       ├── project-manager.md   # PRIMARY: Task orchestrator
│       ├── debugger.md          # Analysis and debugging
│       ├── documenter.md        # Documentation generation
│       └── template/
│           └── builder.md       # Build command executor template
├── .cursor/rules/               # Cursor rules (future)
├── .claude/                     # Claude Code configs (future)
├── .qoder/                      # Qoder agents (future)
└── tools/                       # Deployment tools (future)
```

## Supported Tools

| Tool        | Config Path                                         | File Format                       |
| ----------- | --------------------------------------------------- | --------------------------------- |
| OpenCode    | `.opencode/agents/` or `~/.config/opencode/agents/` | Markdown with YAML frontmatter    |
| Claude Code | `CLAUDE.md` or `~/.claude/CLAUDE.md`                | Plain Markdown                    |
| Qoder       | `.qoder/agents/` or `~/.qoder/agents/`              | Markdown with YAML frontmatter    |
| Cursor      | `.cursor/rules/*.mdc`                               | MDC (Markdown + YAML frontmatter) |
| Roo Code    | `.roorules` or `.clinerules`                        | Plain text/Markdown               |

## Agent Naming Conventions

- Use lowercase with hyphens: `project-manager`, `code-reviewer`
- Primary agents: Full role description with workflow diagrams
- Sub-agents: Focused task scope, minimal context
- Templates: Use `{{placeholder}}` syntax for variables

## Deployment

### OpenCode (Primary)

Symlink agents to local `.opencode` folder:

```bash
# One-time setup
mkdir -p .opencode/agents
ln -sf ../../opencode/agents/*.md .opencode/agents/
ln -sf ../../opencode/agents/template .opencode/agents/

# Or use the deployment script (when created)
./tools/opencode/deploy.sh
```

### Other Tools (Planned)

- Claude Code: Convert agent prompts to CLAUDE.md sections
- Qoder: Direct file copy (compatible format)
- Cursor: Generate .mdc rules from agent definitions

## Agent Categories

### Primary Agents

- `project-manager`: Delegates tasks, never does direct implementation

### Sub-agents

- `debugger`: Error analysis and fix suggestions
- `documenter`: Creates structured documentation with Mermaid diagrams

### Templates

- `builder`: Configurable build command executor

## Constraints

- All diagrams must use Mermaid (no ASCII art)
- Agents must declare `mode: primary|subagent` in frontmatter
- Templates use Handlebars-style `{{variables}}`
- No tool-specific syntax in shared agent definitions

## Future Work

- [ ] Deployment tools for all supported tools
- [ ] Format converters (OpenCode ↔ Cursor ↔ Qoder)
- [ ] Preset template library
- [ ] CI validation for agent file syntax
