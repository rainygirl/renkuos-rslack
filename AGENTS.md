# R Slack - development notes

R Slack is a launcher script for R Chromium in the shape of R Twitter
(`../rtwitter`): `src/RSlack.sh` starts `content_shell` at
`https://app.slack.com/client` with `RCH_NO_TOOLBAR=1`, `RCH_APP_NAME="R Slack"`
and the profile `~/config/settings/RSlack`. Read R Twitter's AGENTS.md for why
the launcher is a script, why both `--data-path` and `--user-data-dir` are
passed, and why WebAuthn is turned off.

## Browser sign-in, as Slack's desktop app does it

The desktop app opens `https://slack.com/ssb/signin` in the web browser. When
the sign-in is done the page opens

	slack://<TEAM>/magic-login/<token>[?host=<workspace>.slack.com]

and the app consumes it. The web equivalent, from Zlack
(https://github.com/sanguneo/zlack/pull/14), is a top-level load of

	https://<host>/api/auth.loginMagicBulk?magic_tokens=z-app-<TEAM>-<token>&ssb=1

with `<host>` = `app.slack.com` unless the link names a `*.slack.com` host.
That response sets the session cookies. Team IDs are upper case; some openers
lower-case the authority part of the URL, so the script upper-cases it back.

### Why a second window (`src/login.html`)

The cookies are SameSite and count only from a top-level navigation. An iframe
or a fetch() from the local page does not set them. A script cannot drive
content_shell from outside. So `login.html` opens the API URL with
`window.open` and, after 8 s, closes that window and goes to the client. The
answer cannot be read across origins, so a refused token shows up as Slack's
sign-in page in the client.

The script validates the team, the token and the host against the characters
each may hold before building the URL. `login.html` accepts only that exact
URL shape after the `#`.

### Handler registration

On every start the script runs

	setmime -set application/x-vnd.rainygirl-RSlack -preferredApp <this script>
	setmime -set application/x-vnd.Be.URL.slack -preferredAppSig application/x-vnd.rainygirl-RSlack

The first gives our signature an app hint pointing at the script. The second
makes R Slack the application for `slack://`. `BUrl::OpenWithPreferredApplication`
and `/bin/open` launch the preferred application of
`application/x-vnd.Be.URL.<scheme>` with the URL as `argv[1]`. The packaged
script carries `BEOS:APP_SIG`, so the roster also finds it by query.

### The browser has to hand the link on

- WebPositive: `BrowserWindow::MainDocumentError` launches the URL type's
  preferred application for a scheme it does not handle.
- R Chromium: content_shell inherited `HandleExternalProtocol`, which does
  nothing. `port-shell-external-protocol.py` (154 port and 114 port) makes it
  run `/bin/open <url>` for the main frame or a click. That is in R Chromium
  154.0.8036.0-15 and 114.0.5735.199-15.

## Status

Written 2026-10-30 while every Haiku test machine was offline: the parts that
need a machine are untested. Those are the handler launch from a browser,
`window.open` from a `file://` page in content_shell, and Slack's answer to
the token.
