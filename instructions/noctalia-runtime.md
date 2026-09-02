# Noctalia Runtime

## Scope

This runbook validates the single-owner desktop path:

```text
greetd -> Noctalia Greeter -> direct Hyprland -> Noctalia Shell
```

Noctalia owns the bar, launcher, notifications, lock screen, idle behavior,
monitor power actions, wallpaper, OSD, and control center. Hyprland owns the
compositor and its native keybindings. Do not add Hyprlock, Hypridle, UWSM, or a
second Noctalia process to this profile.

Keep `Ctrl+Alt+F3` available before changing the login or lock configuration.
Run display, authentication, idle, and suspend tests from the graphical session,
not through SSH.

## 1. Install and Apply

Install the official desktop packages and the separately built Greeter:

```bash
cd ~/src/deomarchyfy
./scripts/01-install-packages.sh --no-upgrade
./scripts/04-install-noctalia-greeter.sh
```

Configure the root-owned greetd path only after reviewing the Greeter procedure:

```bash
./scripts/05-configure-greetd.sh --dry-run
./scripts/05-configure-greetd.sh --write
```

Apply the user packages and inspect the planned links first:

```bash
./scripts/03-stow-configs.sh --dry-run hyprland noctalia
./scripts/03-stow-configs.sh --restow hyprland noctalia
```

If an existing Noctalia file is customized, use
`--replace-noctalia`; the script backs it up before replacing it. Never use
`stow --adopt`.

## 2. Validate Noctalia Configuration

The repository configuration enables Noctalia's lock screen, locks after five
minutes of inactivity, and powers off monitors after five and a half minutes:

```toml
[lockscreen]
enabled = true

[idle.behavior.lock]
enabled = true
timeout = 300
action = "lock"

[idle.behavior.screen-off]
enabled = true
timeout = 330
action = "screen_off"
```

Validate the merged configuration. GUI-managed state under
`~/.local/state/noctalia/settings.toml` loads after the Stow file and can
override it:

```bash
noctalia config validate
noctalia config export merged | python3 -c '
import sys
import tomllib

config = tomllib.load(sys.stdin.buffer)
paths = (
    ("lockscreen", "enabled"),
    ("idle", "behavior", "lock", "enabled"),
    ("idle", "behavior", "screen-off", "enabled"),
)
for path in paths:
    value = config
    for part in path:
        if not isinstance(value, dict) or part not in value:
            value = None
            break
        value = value[part]
    if value is not True:
        raise SystemExit("must be true: " + ".".join(path))
print("Noctalia lock and idle behavior are enabled")
'
```

If GUI state disables one of these settings, enable it through Noctalia
Settings. If the override cannot be cleared there, back it up before editing:

```bash
mkdir -p ~/.config/deomarchyfy-backup
cp ~/.local/state/noctalia/settings.toml \
  ~/.config/deomarchyfy-backup/noctalia-settings-$(date +%Y%m%d-%H%M%S).toml
```

Reload after changing either configuration layer:

```bash
noctalia msg config-reload
noctalia config validate
```

## 3. Start and Test IPC

Hyprland starts Noctalia once through its `hyprland.start` hook. Log out and
back in after changing the startup path, then verify:

```bash
hyprctl reload
hyprctl configerrors
pgrep -cx noctalia
```

The expected results are an empty config-error response and exactly one
Noctalia process. Test representative IPC actions before testing the physical
bindings:

```bash
noctalia msg panel-toggle launcher
noctalia msg panel-toggle session
noctalia msg panel-toggle wallpaper
noctalia msg panel-toggle control-center audio
noctalia msg notification-dnd-toggle
noctalia msg notification-dnd-toggle
```

The important lock command is:

```bash
noctalia msg session lock
```

It should return successfully and open the Noctalia lock surface.

## 4. Test Physical Bindings and Locking

From the graphical session, test the bindings in
`dotfiles/hyprland/.config/hypr/bindings.lua`:

| Binding | Expected result |
| --- | --- |
| `SUPER + SPACE` | Toggle the Noctalia launcher |
| `ALT + TAB` | Open the Noctalia window switcher |
| `SUPER + ESCAPE` | Toggle the Noctalia session panel |
| `SUPER + SHIFT + SPACE` | Toggle the Noctalia bar |
| `SUPER + CTRL + SPACE` | Open the wallpaper panel |
| `SUPER + CTRL + A/B/D/M/P/T/W` | Open the corresponding Control Center tab |
| `SUPER + CTRL + E` | Open the launcher emoji query |
| `SUPER + CTRL + Q` | Open the launcher calculator query |
| `SUPER + CTRL + V` | Open the clipboard panel |
| `SUPER + CTRL + SHIFT + S` | Start the region screenshot picker |
| `SUPER + CTRL + C` | Toggle Noctalia caffeine |
| `SUPER + CTRL + N` | Toggle Noctalia night light |
| `SUPER + CTRL + L` | Open the Noctalia lock screen |

For the lock test, verify that the Noctalia surface covers every monitor, the
normal password works, fingerprint authentication works if configured, and
unlocking returns to the same Hyprland session. No second lock surface should
appear and `pgrep -cx noctalia` should remain `1`.

Also test the logind path from the graphical session:

```bash
loginctl lock-session
```

Unlock physically and confirm that the Noctalia lock screen handled the event.

## 5. Test Idle, Monitor Power, and Suspend

Disable caffeine, save work, and leave the machine untouched for at least 330
seconds:

```bash
noctalia msg caffeine-disable
```

Verify that the lock screen appears near 300 seconds, the monitors power off
near 330 seconds, input wakes the monitors, and authentication returns to the
same session with no extra daemon. Do not run this timing test over SSH.

If suspend is required, keep the TTY available and trigger it only from the
graphical session. Use Noctalia's `session lock-and-suspend` action or:

```bash
noctalia msg session lock-and-suspend
```

Confirm that the session is locked before sleep and returns to the Noctalia lock
screen after wake.

## 6. Verify and Recover

Run the read-only verifier from the graphical session:

```bash
./scripts/06-verify-setup.sh --pre-greetd
```

Run it without `--pre-greetd` after the greetd login path is active. Add the
machine-specific options selected during installation, such as `--zram`,
`--ssh`, or `--accountsservice`.

If the graphical session or lock surface fails, switch to a TTY and inspect the
session without installing another owner:

```bash
pgrep -a noctalia
sudo journalctl -b --no-pager | grep -E 'Hyprland|noctalia|greetd'
```

Correct the Stow-managed configuration, restow the affected package, and log in
again. Keep TTY access and recovery media available until the Greeter, login,
lock, idle, wake, and suspend tests pass.
