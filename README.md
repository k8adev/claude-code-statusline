# claude-code-statusline

![screenshot](screenshot.png)

Status line for Claude Code: project and branch, context window, session time, usage limits.

1. `project (branch) +added -removed`
2. `model  context bar  %  · session time`
3. `5h N% reset · 7d N% reset` — hidden inside tmux when [tmux-vitals](https://github.com/k8adev/tmux-vitals) already shows it

## Install

```sh
git clone https://github.com/k8adev/claude-code-statusline ~/Projects/k8adev/claude-code-statusline
```

`~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/Projects/k8adev/claude-code-statusline/statusline.sh"
  }
}
```

Requires [bash](https://www.gnu.org/software/bash/), [jq](https://jqlang.github.io/jq/),
[git](https://git-scm.com/), a [truecolor](https://github.com/termstandard/colors) terminal and a
[Nerd Font](https://www.nerdfonts.com/).

## Options

All via environment variables.

| Variable | Default | What |
|---|---|---|
| `CLAUDE_STATUSLINE_LIMITS` | `auto` | Line 3: `auto` (hide when tmux-vitals shows it), `always`, `never` |
| `CLAUDE_STATUSLINE_CTX_WARN` / `_CTX_CRIT` | `30` / `60` | Context bar turns yellow / red above these % |
| `CLAUDE_STATUSLINE_LIMIT_WARN` / `_LIMIT_CRIT` | `50` / `80` | Usage limits turn yellow / red above these % |
| `CLAUDE_STATUSLINE_ICON_DIR` | `󰉋` | Folder icon |
| `CLAUDE_STATUSLINE_ICON_CLOCK` | `󰥔` | Session time icon |
| `CLAUDE_STATUSLINE_ICON_RESET` | `󰑐` | Reset countdown icon |
| `CLAUDE_STATUSLINE_RL_CACHE` | `~/.claude/cache/rate-limits.json` | Where the rate limits are written for tmux-vitals |

Context thresholds are low on purpose: Anthropic's [best practices](https://code.claude.com/docs/en/best-practices)
say performance degrades as the window fills, and `used_percentage` counts input tokens only.

Colors follow the Anthropic palette (Clay, Olive, Kraft, Deep).

## License

MIT © k8adev. See [LICENSE](LICENSE).
