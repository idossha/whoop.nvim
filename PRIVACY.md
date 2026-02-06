# Privacy Policy

**Effective Date:** February 6, 2026

## Summary

whoop.nvim is a local Neovim plugin that accesses your personal WHOOP fitness data. **All data remains on your device.** No information is collected, transmitted to third parties, or stored on external servers.

## Data Handling

### What We Access
- WHOOP fitness metrics (recovery, sleep, workouts) via official WHOOP API
- OAuth authentication tokens provided by WHOOP

### Where Data Is Stored
All data is stored **locally** on your device:

```
~/.local/share/nvim/whoop/          (Linux/macOS)
%LOCALAPPDATA%\nvim-data\whoop\     (Windows)
```

### What We Do NOT Do
- Collect or store data on external servers
- Share data with third parties
- Track usage or analytics
- Display advertisements

## Third-Party Services

| Service | Purpose | Data Shared |
|---------|---------|-------------|
| WHOOP API | Retrieve fitness data | Authenticated API requests only |

## Your Control

You may:
- Revoke API access via [WHOOP Developer Dashboard](https://developer-dashboard.whoop.com)
- Delete local data by removing the plugin directory
- Uninstall the plugin to remove all associated data

## Changes

This policy may be updated periodically. Changes will be reflected in this document.

## Contact

Questions or concerns: [GitHub Issues](https://github.com/idossha/whoop.nvim/issues)
