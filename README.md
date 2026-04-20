# Agent Feedback

Agent Feedback is a small Neovim plugin for leaving line-anchored feedback on code
changes made by an AI agent. Feedback can be exported to a flat Markdown file
that a coding agent can read and turn into follow-up code changes.

By default, feedback is written to `.agent-feedback/feedback.md` in the current
Git repository.

## Neovim Setup

Install the plugin with your preferred plugin manager.

### lazy.nvim

```lua
{
  "gcorne/agent-feedback",
  config = function()
    require("agent_feedback").setup()
  end,
}
```

### packer.nvim

```lua
use({
  "gcorne/agent-feedback",
  config = function()
    require("agent_feedback").setup()
  end,
})
```

### vim-plug

```vim
Plug 'gcorne/agent-feedback'
```

Then configure the plugin from Lua:

```lua
require("agent_feedback").setup()
```

The plugin also calls `setup()` automatically from `plugin/agent_feedback.lua`,
so explicit setup is only required when you want to override defaults.

## Configuration

```lua
require("agent_feedback").setup({
  feedback_path = ".agent-feedback/feedback.md",
  history_path = ".agent-feedback/history",
  autosave = true,
  sign_text = ">>",
  virtual_text = "review",
  line_hl_group = nil,
})
```

Options:

- `feedback_path`: Markdown file used for import and export.
- `history_path`: Directory where old feedback files are archived.
- `autosave`: Save feedback automatically after changes.
- `sign_text`: Text shown in the sign column for commented lines.
- `virtual_text`: Inline text shown beside commented lines.
- `line_hl_group`: Optional highlight group for commented lines.

## Commands

| Command | Description |
| --- | --- |
| `:AgentFeedback` | Add or edit feedback for the current line. Also works with a visual range. |
| `:AgentFeedbackExport` | Export current feedback to `.agent-feedback/feedback.md`. |
| `:AgentFeedbackImport` | Import comments from `.agent-feedback/feedback.md`. |
| `:AgentFeedbackList` | Show feedback comments in the quickfix list. |
| `:AgentFeedbackDelete` | Delete feedback for the current line. |
| `:AgentFeedbackNew` | Start a new feedback file and archive the previous one. |

Typical flow:

1. Open a changed file in Neovim.
2. Place the cursor on a line, or select a range in visual mode.
3. Run `:AgentFeedback` and write the review note in the floating editor.
4. Run `:AgentFeedbackExport`.
5. Ask a coding agent to address `.agent-feedback/feedback.md`.

## Skill Setup

This repository includes an `address-feedback` skill at:

```text
skills/address-feedback/SKILL.md
```

To use it, make the skill available to your coding agent by copying,
symlinking, or importing the `skills/address-feedback` directory wherever that
agent loads custom skills or project instructions.

For example, with an agent that reads skills from a local skills directory:

```sh
mkdir -p "<agent-skills-dir>"
ln -s "$PWD/skills/address-feedback" "<agent-skills-dir>/address-feedback"
```

After the skill is available, ask your agent to use it with a prompt like:

```text
/address-feedback
```

or:

```text
Read .agent-feedback/feedback.md and address the feedback.
```

The skill reads feedback blocks, inspects each referenced file and line range,
applies focused fixes, and reports which comments were resolved.
