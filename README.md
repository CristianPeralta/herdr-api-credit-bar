# API Credit Bar

Herdr plugin. Shows remaining credit for pay-as-you-go API providers in a small persistent
pane. Starts with Alibaba Cloud Model Studio (DashScope). Add more providers as scripts under
`providers/`.

## Install (local dev)

```bash
herdr plugin link ~/code/herdr-api-credit-bar
```

## Usage

```bash
herdr plugin action invoke api-credit-bar.open-alibaba
```

Opens (or reuses, if already open) a small pane below the current one, refreshing every 30
minutes. Press `r` inside the pane to refresh now, `q` to stop.

No API key is stored by this plugin. `providers/alibaba.sh` shells out to the `aliyun` CLI, so
it needs `aliyun` on `PATH` and already authenticated (`aliyun configure`, or credentials
resolved by whatever wrapper you already use). Linux only for now.

## Adding a provider

Drop a new script in `providers/<name>.sh` (same loop-and-print shape as `alibaba.sh`). Add an
`[[actions]]` entry in `herdr-plugin.toml` pointing an `actions/open-<name>.sh` wrapper at it
(copy `actions/open-alibaba.sh`, change the label and script path). No shared credential
storage: each provider script reads its own already-configured CLI or keyring.

## License

MIT
