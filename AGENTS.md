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

### Loading the sign-in call out of sight (`--rch-load-first`)

Slack's session cookie `d` is SameSite=Lax (checked in the profile's cookie
database, 2026-10-30). It counts only from a top-level navigation: an iframe or
a fetch() from a local page does not keep it.

The first version loaded the call in a `window.open` popup from a local
`login.html`. That showed the user Slack's JSON answer for 8 s. R Chromium now
takes `--rch-load-first=<https URL>`
(`port-shell-load-first.py`). It loads that URL in a WebContents with no
window, in the same profile, and opens the startup window when the load stops
(or after 30 s). The script passes the API URL there and starts the client.

The script validates the team, the token and the host against the characters
each may hold before building the URL. A refused token shows up as Slack's
sign-in page in the client.

### content_shell is a child, not exec'd

When Haiku starts R Slack (Deskbar, Tracker, a slack:// link), the roster has
pre-registered the script's team under R Slack's signature. content_shell
exec'd into that team never finished its own BApplication registration. Its
`HaikuApp` looper spun at a full core and the window stayed white
(2026-10-30, found with `top` in the arm64 guest). Started as a child team, it
does not, and the script exits.

The Slack client takes about a minute to its first paint in the arm64 guest.
The window is white until then; that is the client booting, not a hang.

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

### The sign-in browser is R Chromium

`--sign-in` and "Open the browser" start `$APPDIR/R Chromium` (the browser
launcher, with toolbar and its own default profile) at slack.com/ssb/signin.
They do not use `open`, because Haiku's preferred browser on RENKU arm64 is
WebPositive. It has no WebKit there and exits at once (2026-10-30).

## Tested (2026-10-30, RENKU arm64 in QEMU on the Mac, R Chromium 154 with the patch)

- `--sign-in` registers the handler (`META:PREF_APP` of
  `application/x-vnd.be.url.slack` = our signature; our type's `META:PPATH` =
  the script). It opens slack.com/ssb/signin in an R Chromium window.
- A page in that R Chromium going to `slack://t0test123/magic-login/fakeToken.123`
  started R Slack through /bin/open. R Slack opened login.html, and the popup
  called auth.loginMagicBulk for `z-app-T0TEST123-fakeToken.123` (team upper
  cased). Slack answered `{"ok":true,"token_results":{...:{"ok":false,"error":"invalid_token"}}}`.
  After 8 s the window went to the client, which showed Slack's sign-in.
- Not tested: a real token, since there was no account to sign in with.

`RSLACK_RCHROMIUM=<dir>` makes the script use another R Chromium copy, which
is how the patched build was tried before packaging.
