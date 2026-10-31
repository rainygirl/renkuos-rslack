# R Slack

[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md)

Slack in its own window on RenkuOS (Haiku), on R Chromium without the browser
toolbar. It signs in the way Slack's desktop app does: in the web browser,
which then hands the session to R Slack.

## Install with pkgman

| Haiku | Commands |
| --- | --- |
| 32-bit x86 (x86_gcc2) | `pkgman add-repo https://pkgman.rainygirl.com/x86_gcc2`<br>`pkgman install rslack_x86` |
| x86_64 | `pkgman add-repo https://pkgman.rainygirl.com/x86_64`<br>`pkgman install rslack` |
| arm64 | `pkgman add-repo https://pkgman.rainygirl.com/arm64`<br>`pkgman install rslack` |

R Chromium comes with it. Then start **R Slack** from Deskbar -> Applications,
choose **Open the browser**, and sign in there; at the end the browser hands
you over to R Slack.

On 32-bit x86 Slack takes a minute or two to load; the window shows a grey
outline until it is ready.

## Install from source

On the Haiku machine:

```sh
make install     # ~/config/non-packaged/apps/RSlack, and a Deskbar entry
```

## AI disclosure

Parts of R Slack were developed with the assistance of AI coding tools
(Anthropic's Claude). All code has been reviewed and tested by the author.

## License

MIT. Slack and its logo are trademarks of Slack Technologies, LLC; R Slack is
not made or endorsed by Slack, see [NOTICE](assets/NOTICE). Development notes
are in [AGENTS.md](AGENTS.md).
