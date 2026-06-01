# Grok Memory Context

This repository serves as the persistent, versioned memory / context store for Grok sessions.

## Structure

- `backups/` — Dated memory snapshots and exports (auto-pruned after 30 days by cron)
- `snapshots/` — Optional additional snapshot location
- `sessions/` — (future) per-session context
- Other files as needed by the memory system

## Automation

A cron job runs `~/.grok/bin/update-mem-context.sh` hourly. It:
1. Pulls the latest changes
2. Deletes any files in `backups/` and `snapshots/` older than 30 days (by mtime)
3. Commits and pushes any new or pruned content

## Manual usage

```bash
# Run maintenance manually
~/.grok/bin/update-mem-context.sh

# View recent activity
tail -f ~/.grok/logs/mem-context-update.log
tail -f ~/.grok/logs/mem-prune.log
```

## Notes

- The repository is kept in `~/.grok/memory` on the host running the Grok TUI.
- All changes should be committed so they survive container/session restarts.
- Do not store large binary files here unless necessary.

Last initialized: $(date -Iseconds)
