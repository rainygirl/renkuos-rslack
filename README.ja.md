# R Slack

[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md)

RenkuOS (Haiku) で Slack をブラウザーのツールバーのない専用ウィンドウで開きます。
R Chromium を使います。サインインは Slack のデスクトップアプリと同じ方式です。
Web ブラウザーでサインインすると、ブラウザーがセッションを R Slack に渡します。

## pkgman でインストール

```sh
pkgman add-repo https://pkgman.rainygirl.com/x86_64    # または arm64、x86_gcc2
pkgman install rslack                                   # R Chromium も一緒に入ります
```

32 ビット x86 (x86_gcc2) ではブラウザーのパッケージは `rchromium_x86` で、pkgman
が選びます。

## サインイン

1. Deskbar -> アプリケーションから **R Slack** を起動します。
2. 初回はどこでサインインするかを尋ねます。**Open the browser** を選ぶと、Web
   ブラウザーで `slack.com/ssb/signin` が開きます。
3. そこでサインインします。メール、Google、SSO など、ワークスペースで使っている
   方法でかまいません。
4. 最後にブラウザーが `slack://` リンクを開き、R Slack がワークスペースと一緒に
   開きます。

ワークスペースを追加するには `"/boot/system/apps/RSlack/R Slack" --sign-in` を
実行して、もう一度サインインします。

**Sign in here** を選ぶと R Slack のウィンドウの中でサインインします。ブラウザー
が `slack://` リンクを渡せないときに使ってください。

ブラウザーが `slack://` リンクを Haiku に渡す必要があります。

- WebPositive は、知らないスキームへ進むページを Haiku に渡します。
- R Chromium は、このアプリと一緒に出たビルド (154.0.8036.0-15、
  114.0.5735.199-15) から渡します。

## しくみ

`R Slack` は R Twitter と同じくシェルスクリプトです。R Chromium の
`content_shell` を `https://app.slack.com/client` で起動し、次のように設定します。

- ツールバーを消します。
- ウィンドウ名を R Slack にします。
- プロファイルを別に `~/config/settings/RSlack` に置きます。

起動のたびに `setmime` で `application/x-vnd.Be.URL.slack` の既定アプリケー
ションとして自分を登録します。Haiku が `slack://` リンクを開くときに探すのは
この型です。

ブラウザーでのサインインは `slack://<TEAM>/magic-login/<token>[?host=...]` で
終わります。R Slack はこれを
`https://app.slack.com/api/auth.loginMagicBulk?magic_tokens=z-app-<TEAM>-<token>&ssb=1`
に変え、別のウィンドウで開きます。すると Slack が R Slack のプロファイルに
セッションの Cookie を保存し、そのあとクライアントが開きます。

この変換は [Zlack](https://github.com/sanguneo/zlack/pull/14) が自分の
クライアントのために見つけた方法です。`slack://channel?team=...&id=...` リンクは
その会話を開きます。

ブラウザーの出力は `~/config/settings/RSlack/rslack.log` に残り、直前の実行分は
`.log.1` として残ります。

## ソースからビルド

Haiku で:

```sh
make install     # ~/config/non-packaged/apps/RSlack と Deskbar の項目
```

`python3 tools/make_icon.py` でアイコンを描き直します。

## ライセンス

MIT。Slack とそのロゴは Slack Technologies, LLC の商標です。R Slack は Slack が
作ったものでも保証したものでもありません。`assets/NOTICE` を見てください。
