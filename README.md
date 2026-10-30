# claude-config

My global [Claude Code](https://code.claude.com) setup: instructions, settings, status line, output styles, skills and hooks.

This repo is `~/.claude` itself. The `.gitignore` is an allowlist, so sessions, history, caches and credentials in the same folder stay out of git.

## New machine

Before the first start of Claude Code:

```sh
git clone <this repo> ~/.claude
```

If `~/.claude` already exists:

```sh
cd ~/.claude
git init
git remote add origin <this repo>
git fetch origin
git checkout -f -B main origin/main
```

Then install the plugins that `settings.json` enables:

```
/plugin install mattpocock-skills@claude-plugins-official
/plugin install pr-review-toolkit@claude-plugins-official
/plugin install atlassian@claude-plugins-official
```

The status line needs `jq`, and its cost segment needs `bun` (for `ccusage`).

## Not in this repo

Work-specific auto mode context (`autoMode.environment`) lives in an untracked JSON file next to `settings.json`, loaded with a shell alias:

```sh
alias claude='claude --settings ~/.claude/<work>.json'
```

Auto mode reads `autoMode` only from user settings, managed settings and `--settings`, not from project settings, so it cannot move into the work repo.
