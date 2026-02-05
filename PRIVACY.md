# Privacy Policy

## Whoop.nvim Privacy Policy

**Last Updated:** February 5, 2026

### Overview

Whoop.nvim is a Neovim plugin designed for personal use to display your own Whoop fitness data. This privacy policy explains how we handle your data.

### Data Collection

**We do not collect, store, or share any personal data.**

This plugin:
- Only accesses your own Whoop fitness data through the official Whoop API
- Stores authentication tokens **locally** on your device only
- Caches fitness data **locally** on your device only
- Does not transmit any data to external servers
- Does not share data with third parties

### Local Storage

All data is stored locally in:
- `~/.local/share/nvim/whoop/` (Linux/Mac)
- `%LOCALAPPDATA%\nvim-data\whoop\` (Windows)

This includes:
- OAuth tokens (encrypted/authenticated by Whoop)
- Cached fitness data (recovery, sleep, workouts)

### Third-Party Services

The only external service contacted is:
- **Whoop API** (api.prod.whoop.com) - for retrieving your fitness data

### Your Rights

You can:
- Revoke access anytime via Whoop Developer Dashboard
- Delete local data by removing `~/.local/share/nvim/whoop/`
- Uninstall the plugin to remove all data

### Contact

For questions about this privacy policy:
- GitHub Issues: https://github.com/idossha/whoop.nvim/issues

### Changes

We may update this privacy policy from time to time. Changes will be posted on this page.
