# API Credit Bar

Herdr plugin. Shows remaining credit for pay-as-you-go API providers in a small persistent
pane. Starts with Alibaba Cloud Model Studio (DashScope). Add more providers as scripts under
`providers/`.

## Requirements

- Linux (the credential wrapper this plugin relies on is Linux-specific for now)
- `aliyun` CLI on `PATH`, already authenticated (`aliyun configure`, or credentials resolved
  by whatever wrapper you already use)

No API key is stored by this plugin. If `aliyun` is missing or not authenticated, the pane
shows the real error instead of staying blank, and you can retry with `r` once it's fixed.

## Install

```bash
herdr plugin install CristianPeralta/herdr-api-credit-bar
```

For local dev (edits reflect without reinstalling):

```bash
herdr plugin link ~/code/herdr-api-credit-bar
```

## Usage

```bash
herdr plugin action invoke api-credit-bar.open-alibaba
```

Opens (or reuses, if already open) a small pane below the current one, refreshing every 30
minutes. Press `r` inside the pane to refresh now, `q` to stop.

## Adding a provider

Drop a new script in `providers/<name>.sh` (same loop-and-print shape as `alibaba.sh`). Add an
`[[actions]]` entry in `herdr-plugin.toml` pointing an `actions/open-<name>.sh` wrapper at it
(copy `actions/open-alibaba.sh`, change the label and script path). No shared credential
storage: each provider script reads its own already-configured CLI or keyring.

## License

MIT
