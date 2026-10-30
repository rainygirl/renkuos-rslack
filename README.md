# R Slack

[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md)

Slack in its own window on RenkuOS (Haiku), using R Chromium without the
browser toolbar. It signs in the way Slack's desktop app does: in the web
browser (R Chromium, toolbar and all), which then hands the session to
R Slack.

## Install with pkgman

```sh
pkgman add-repo https://pkgman.rainygirl.com/x86_64    # or arm64, x86_gcc2
pkgman install rslack                                   # also installs R Chromium
```

On 32-bit x86 (x86_gcc2) R Chromium is Chromium 114, which Slack no longer
supports. The windows R Slack opens, the app and the sign-in browser, say a
newer Chrome in their user agent; this needs rchromium_x86 114.0.5735.199-16
or later.

## Signing in

1. Start **R Slack** from Deskbar -> Applications.
2. The first time, it asks where to sign in. Choose **Open the browser**: an
   R Chromium browser window opens `slack.com/ssb/signin`.
3. Sign in there -- email, Google, SSO, whichever your workspace uses.
4. At the end the browser opens a `slack://` link, and R Slack opens with
   your workspace.

To add another workspace, run `"/boot/system/apps/RSlack/R Slack" --sign-in`
and sign in again.

**Sign in here** instead signs in inside the R Slack window.

The sign-in uses R Chromium rather than Haiku's preferred web browser. On
RENKU arm64 that is WebPositive, which has no WebKit there and does not start.
R Chromium passes the `slack://` link to Haiku from 154.0.8036.0-15 on.
WebPositive does the same when a page goes to a scheme it does not know.

## How it works

`R Slack` is a shell script, like R Twitter. It starts R Chromium's
`content_shell` at `https://app.slack.com/client` with:

- the toolbar off;
- the window named R Slack;
- a profile of its own in `~/config/settings/RSlack`.

Every time it starts it registers itself, with `setmime`, as the preferred
application of `application/x-vnd.Be.URL.slack`. That is the type Haiku looks
up for a `slack://` link.

The browser sign-in ends with
`slack://<TEAM>/magic-login/<token>[?host=...]`. R Slack turns that into
`https://app.slack.com/api/auth.loginMagicBulk?magic_tokens=z-app-<TEAM>-<token>&ssb=1`
and has R Chromium load it out of sight (`--rch-load-first`), so that Slack
sets the session cookies in R Slack's profile. Then it opens the client.

The conversion is the one
[Zlack](https://github.com/sanguneo/zlack/pull/14) worked out for its own
client. `slack://channel?team=...&id=...` links open that conversation.

What the browser says about itself goes to
`~/config/settings/RSlack/rslack.log`. The run before is kept as `.log.1`.

## Build from source

On Haiku:

```sh
make install     # ~/config/non-packaged/apps/RSlack, and a Deskbar entry
```

`python3 tools/make_icon.py` redraws the icon.

## License

MIT. Slack and its logo are trademarks of Slack Technologies, LLC; R Slack is
not made or endorsed by Slack. See `assets/NOTICE`.
