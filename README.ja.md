# R Slack

[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md)

RenkuOS(Haiku)で Slack を専用ウィンドウで開くアプリです。ブラウザーのツールバーを
外した R Chromium で動き、Slack のデスクトップアプリと同じくウェブブラウザーで
サインインしてから、セッションを R Slack に引き継ぎます。

## pkgman でインストール

| Haiku | コマンド |
| --- | --- |
| 32 ビット x86 (x86_gcc2) | `pkgman add-repo https://pkgman.rainygirl.com/x86_gcc2`<br>`pkgman install rslack` |
| x86_64 | `pkgman add-repo https://pkgman.rainygirl.com/x86_64`<br>`pkgman install rslack` |
| arm64 | `pkgman add-repo https://pkgman.rainygirl.com/arm64`<br>`pkgman install rslack` |

R Chromium も一緒に入ります。インストール後、Deskbar -> Applications から
**R Slack** を起動し、**Open the browser** を選んでそのブラウザーでサインイン
してください。終わるとブラウザーが R Slack に引き継ぎます。

32 ビット x86 では Slack の表示まで 1、2 分かかります。準備ができるまでウィンドウには
灰色の枠だけが出ます。

## ソースからインストール

Haiku のマシンで:

```sh
make install     # ~/config/non-packaged/apps/RSlack と Deskbar の項目
```

## AI 利用の告知

R Slack の一部は AI コーディングツール(Anthropic の Claude)の支援を受けて開発しました。
すべてのコードは作者がレビューし、テストしています。

## ライセンス

MIT。Slack とそのロゴは Slack Technologies, LLC の商標で、R Slack は Slack が作成・
保証したものではありません。[NOTICE](assets/NOTICE) を参照してください。開発メモは
[AGENTS.md](AGENTS.md) にあります。
