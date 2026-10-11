# Contributing

Issues and pull requests are welcome.

## Try a change

```bash
./install.sh
/usr/lib/kscreenlocker_greet --testing --shell ~/.local/share/plasma/shells/yakupemre-lockscreen
```

The test window runs real authentication: typing your password closes it.

## Things that bite

- **Keep the contract in `LockScreen.qml`.** kscreenlocker looks for `root`, `notification`, `clearPassword()` and `viewVisible` by name; `authenticator`, `kscreenlocker_userName` and `kscreenlocker_userImage` are context properties it injects.
- **Relative QML paths stay inside this package.** The fallback to `org.kde.plasma.desktop` covers package lookups, not `source: "Foo.qml"`; a missing file there means a broken lock screen.
- **`X-Plasma-APIVersion` must stay `2`**, otherwise the greeter ignores the package as outdated.
- **Text in a Turkish locale.** `[A-Za-z]` does not match `i` under `tr_TR`; run `sed` with `LC_ALL=C`.

Run `shellcheck install.sh uninstall.sh` before sending changes to the scripts.
