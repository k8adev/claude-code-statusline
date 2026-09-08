# claude-code-statusline

[English](README.md) · **Português (BR)**

![screenshot](screenshot.png)

Status line para o Claude Code: projeto e branch, janela de contexto, tempo de sessão, limites de uso.

1. `projeto (branch) +adicionadas -removidas`
2. `modelo  barra de contexto  %  · tempo de sessão`
3. `5h N% reset · 7d N% reset` — oculta dentro do tmux quando o [tmux-vitals](https://github.com/k8adev/tmux-vitals) já mostra

## Instalação

### Deixe o Claude instalar

Cole isto numa sessão do Claude Code:

```text
Instale https://github.com/k8adev/claude-code-statusline como minha status line:
clone em ~/.claude/claude-code-statusline, aponte o statusLine do
~/.claude/settings.json para o statusline.sh dele e confira se o jq está instalado.
```

### Manual

```sh
git clone https://github.com/k8adev/claude-code-statusline ~/.claude/claude-code-statusline
```

`~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/claude-code-statusline/statusline.sh"
  }
}
```

Requer [bash](https://www.gnu.org/software/bash/), [jq](https://jqlang.github.io/jq/),
[git](https://git-scm.com/), um terminal com [truecolor](https://github.com/termstandard/colors) e uma
[Nerd Font](https://www.nerdfonts.com/).

## Opções

Todas via variáveis de ambiente.

| Variável | Padrão | O que faz |
|---|---|---|
| `CLAUDE_STATUSLINE_LIMITS` | `auto` | Linha 3: `auto` (oculta quando o tmux-vitals mostra), `always`, `never` |
| `CLAUDE_STATUSLINE_CTX_WARN` / `_CTX_CRIT` | `30` / `60` | Barra de contexto fica amarela / vermelha acima destes % |
| `CLAUDE_STATUSLINE_LIMIT_WARN` / `_LIMIT_CRIT` | `50` / `80` | Limites de uso ficam amarelos / vermelhos acima destes % |
| `CLAUDE_STATUSLINE_ICON_DIR` | `󰉋` | Ícone de pasta |
| `CLAUDE_STATUSLINE_ICON_CLOCK` | `󰥔` | Ícone do tempo de sessão |
| `CLAUDE_STATUSLINE_ICON_RESET` | `󰑐` | Ícone da contagem de reset |
| `CLAUDE_STATUSLINE_RL_CACHE` | `~/.claude/cache/rate-limits.json` | Onde os limites são gravados para o tmux-vitals |

Os limiares de contexto são baixos de propósito: as [boas práticas](https://code.claude.com/docs/en/best-practices)
da Anthropic dizem que a performance cai conforme a janela enche, e `used_percentage` conta só tokens de entrada.

As cores seguem a paleta da Anthropic (Clay, Olive, Kraft, Deep).

## Licença

MIT © k8adev. Veja [LICENSE](LICENSE).
