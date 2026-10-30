#!/bin/sh
# R Slack - Slack in R Chromium, the Chromium port for Haiku, as its own app.
#
# Signing in works the way it does with Slack's desktop app: the sign-in
# happens in the web browser, at slack.com/ssb/signin, and when it is done
# the browser opens a slack:// link that hands the session to the app.
#
#   slack://<TEAM>/magic-login/<token>[?host=<workspace>.slack.com]
#
# R Slack is the handler for slack:// (it registers itself as the preferred
# application of application/x-vnd.Be.URL.slack every time it starts), so
# Haiku starts this script with that link as $1. The token becomes
# z-app-<TEAM>-<token> and goes to auth.loginMagicBulk, which sets the
# session cookies in R Slack's own profile. R Chromium loads that out of
# sight (--rch-load-first) and then opens app.slack.com/client. The same conversion is described in
# https://github.com/sanguneo/zlack/pull/14, which does this for a Tauri app.
#
#   R Slack                 the client, or the sign-in prompt the first time
#   R Slack --sign-in       sign in (another workspace) in the web browser
#   R Slack slack://...     what the browser opens after signing in

APP_TITLE="R Slack"
APP_SIG="application/x-vnd.rainygirl-RSlack"
PROFILE="$HOME/config/settings/RSlack"
CLIENT_URL="https://app.slack.com/client"
SIGNIN_URL="https://slack.com/ssb/signin"
# content_shell opens 800x600 otherwise; this fits a 1600x768 VAIO P screen.
WINDOW_SIZE="--content-shell-host-window-size=1100x700"

# Deskbar starts us through a symlink; the MIME database wants the real file.
SELF=$(readlink -f "$0" 2>/dev/null || echo "$0")

# Where R Chromium may be: the package, then a hand-installed copy.
#
# RSLACK_RCHROMIUM names another copy, which is how to try a new build.
for dir in \
	${RSLACK_RCHROMIUM:+"$RSLACK_RCHROMIUM"} \
	"/boot/system/apps/RChromium" \
	"$HOME/config/non-packaged/apps/RChromium" \
	"$HOME/RChromium"
do
	if [ -x "$dir/content_shell" ]; then
		APPDIR="$dir"
		break
	fi
done

if [ -z "$APPDIR" ]; then
	# 32-bit x86 Haiku calls the package rchromium_x86; everywhere else it is
	# rchromium.
	case "$(uname -m)" in
		BePC|i*86) package="rchromium_x86" ;;
		*)         package="rchromium" ;;
	esac
	alert --stop "$APP_TITLE needs R Chromium, which is not installed.

pkgman install $package" "OK" > /dev/null
	exit 1
fi

mkdir -p "$PROFILE"

# Make this script the handler of slack:// links. setmime is cheap and the
# MIME database is the user's, so doing it on every start also repairs it
# after the package moves or another app takes the type. The app hint is
# what the roster follows from our signature to this file.
setmime -set "$APP_SIG" -preferredApp "$SELF" > /dev/null 2>&1
setmime -set application/x-vnd.Be.URL.slack -short "Slack link" \
	-preferredAppSig "$APP_SIG" > /dev/null 2>&1

# Keep what the browser says about itself: Tracker gives a launched
# application no terminal. Two runs are kept. Not when stderr is a terminal.
if [ ! -t 2 ]; then
	LOG="$PROFILE/rslack.log"
	[ -f "$LOG" ] && mv -f "$LOG" "$LOG.1"
	exec >> "$LOG" 2>&1
	echo "=== $APP_TITLE $(date)"
fi

open_window()
{
	# Blink aborts without a fontconfig file and Haiku ships no /etc/fonts.
	if [ -z "$FONTCONFIG_FILE" ] && [ -r "$APPDIR/rchromium-fonts.conf" ]; then
		FONTCONFIG_FILE="$APPDIR/rchromium-fonts.conf"
		export FONTCONFIG_FILE
	fi

	# R Chromium's own libraries (the Haiku shim among them) are in its lib/.
	# A session started over ssh has LIBRARY_PATH unset, which would also
	# hide /boot/system/lib, so the defaults are spelled out.
	LIBRARY_PATH="$APPDIR/lib:${LIBRARY_PATH:-/boot/home/config/non-packaged/lib:/boot/home/config/lib:/boot/system/non-packaged/lib:/boot/system/lib}"
	export LIBRARY_PATH

	# No toolbar, and the window carries this app's name.
	RCH_NO_TOOLBAR=1
	RCH_APP_NAME="$APP_TITLE"
	export RCH_NO_TOOLBAR RCH_APP_NAME

	# Haiku's default of 256 descriptors is not enough once renderers run in
	# their own processes.
	ulimit -n 8192 2>/dev/null

	# Slack lists the media devices for huddles, and with no video capture
	# backend R Chromium 154 on arm64 crashed doing that (see R Twitter).
	FAKE_CAPTURE=
	case "$(uname -m)" in
		arm64|aarch64) FAKE_CAPTURE="--use-fake-device-for-media-stream" ;;
	esac

	# No WebAuthn: R Chromium says a platform authenticator may be there and
	# then never answers, so a passkey prompt would spin for ever. Without
	# window.PublicKeyCredential Slack offers its other ways in.
	#
	# Both profile switches: 114's content_shell reads --data-path, 154's
	# --user-data-dir; each ignores the other.
	#
	# Not exec: when Haiku starts R Slack (Deskbar, Tracker, or a slack://
	# link), the roster has registered this team under R Slack's signature
	# before the script runs. content_shell's own BApplication in that team
	# never finished registering, and its looper spun at 100% of a core while
	# the window stayed white. A child team of its own has no such past.
	# From R Chromium's own folder, as its launcher does; started by the
	# roster the working directory is elsewhere.
	cd "$APPDIR" || exit 1
	"$APPDIR/content_shell" \
		--ozone-platform=haiku \
		--disable-gpu \
		--in-process-gpu \
		--disable-gpu-compositing \
		$FAKE_CAPTURE \
		--disable-blink-features=WebAuth \
		"$WINDOW_SIZE" \
		--data-path="$PROFILE" \
		--user-data-dir="$PROFILE" \
		$LOAD_FIRST \
		"$1" &
	exit 0
}

# Sign-in in the web browser, the way Slack's desktop app does it: R Chromium
# as a browser, toolbar and all, in its own profile.
#
# Not Haiku's preferred browser through `open`: on RENKU arm64 that is
# WebPositive, which has no WebKit there and exits at once. R Chromium is
# installed wherever R Slack is, and it hands the slack:// link at the end
# to Haiku, which starts this script with it.
sign_in_in_browser()
{
	# The browser's launcher: rchromium.sh in the x86 package, where
	# "R Chromium" is the binary itself; "R Chromium" elsewhere.
	for launcher in "$APPDIR/rchromium.sh" "$APPDIR/R Chromium"; do
		if [ -x "$launcher" ]; then
			exec "$launcher" "$SIGNIN_URL"
		fi
	done
	open "$SIGNIN_URL"
}

# The value of "name" in a query string, or nothing.
query_value()
{
	printf '%s\n' "$1" | tr '&' '\n' | sed -n "s/^$2=//p" | head -n 1
}

# slack://<TEAM>/magic-login/<token>[?host=...]: sign the app in, then open
# the client. Every piece is checked against the characters it may hold,
# because they end up in a URL that the browser loads.
magic_login()
{
	rest=${1#slack://}
	team=${rest%%/*}
	tail=${rest#*/magic-login/}
	token=${tail%%\?*}
	query=
	case "$tail" in
		*\?*) query=${tail#*\?} ;;
	esac
	# Some openers lower-case the authority part of a URL, and team IDs are
	# upper case.
	team=$(printf '%s' "$team" | tr 'a-z' 'A-Z')

	case "$team" in
		""|*[!A-Z0-9]*) bad_link ;;
	esac
	case "$token" in
		""|*[!A-Za-z0-9._-]*) bad_link ;;
	esac

	host=$(query_value "$query" host)
	case "$host" in
		""|slack.com)
			host="app.slack.com" ;;
		*[!a-z0-9.-]*)
			bad_link ;;
		*.slack.com)
			;;
		*)
			alert --stop "$APP_TITLE cannot sign in to $host.

Only workspaces on slack.com are supported." "OK" > /dev/null
			exit 1 ;;
	esac

	touch "$PROFILE/.signed-in"
	# The session cookie Slack sets is SameSite=Lax: it counts only from a
	# top-level load, not from an iframe or a fetch(). R Chromium loads the
	# call in a tab that has no window, then opens the client.
	LOAD_FIRST="--rch-load-first=https://$host/api/auth.loginMagicBulk?magic_tokens=z-app-$team-$token&ssb=1"
	open_window "$CLIENT_URL"
}

bad_link()
{
	alert --stop "$APP_TITLE could not read the sign-in link from the
browser. Sign in again with R Slack --sign-in." "OK" > /dev/null
	exit 1
}

case "$1" in
	slack://*/magic-login/*)
		magic_login "$1"
		;;
	slack://channel\?*)
		# slack://channel?team=T...&id=C...: open that conversation.
		query=${1#slack://channel?}
		team=$(query_value "$query" team | tr 'a-z' 'A-Z')
		id=$(query_value "$query" id | tr 'a-z' 'A-Z')
		case "$team$id" in
			""|*[!A-Z0-9]*) open_window "$CLIENT_URL" ;;
		esac
		open_window "$CLIENT_URL/$team/$id"
		;;
	--sign-in)
		sign_in_in_browser
		;;
	*)
		if [ -f "$PROFILE/.signed-in" ]; then
			open_window "$CLIENT_URL"
		fi
		# First start: ask where to sign in. alert's exit status is the
		# index of the button pressed.
		alert --info "Sign in to Slack.

Signing in happens in your web browser. When it is done, the browser
opens Slack here." "Cancel" "Sign in here" "Open the browser" > /dev/null
		case $? in
			2)
				sign_in_in_browser
				;;
			1)
				# Sign in inside the app window instead, for a browser
				# that does not hand slack:// links on.
				touch "$PROFILE/.signed-in"
				open_window "https://slack.com/signin"
				;;
		esac
		;;
esac
exit 0
