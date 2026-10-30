# R Slack

[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md)

RenkuOS(Haiku)에서 Slack을 브라우저 도구 막대 없는 자기 창으로 엽니다.
R Chromium을 씁니다. 로그인은 Slack 데스크톱 앱과 같은 방식입니다. 웹
브라우저(도구 막대가 있는 R Chromium 창)에서 로그인하면 브라우저가 세션을 R Slack으로
넘깁니다.

## pkgman으로 설치

```sh
pkgman add-repo https://pkgman.rainygirl.com/x86_64    # 또는 arm64, x86_gcc2
pkgman install rslack                                   # R Chromium도 함께 설치
```

32비트 x86(x86_gcc2)에서는 브라우저 패키지가 `rchromium_x86`이고, pkgman이
알아서 고릅니다.

## 로그인

1. Deskbar -> 응용 프로그램에서 **R Slack**을 실행합니다.
2. 처음 실행하면 어디서 로그인할지 묻습니다. **Open the browser**를 고르면 R
   Chromium 브라우저 창에 `slack.com/ssb/signin`이 열립니다.
3. 그곳에서 로그인합니다. 이메일, Google, SSO 등 워크스페이스에서 쓰는 방식이면
   됩니다.
4. 마지막에 브라우저가 `slack://` 링크를 열고, R Slack이 워크스페이스와 함께
   열립니다.

워크스페이스를 더하려면 `"/boot/system/apps/RSlack/R Slack" --sign-in`을 실행해
다시 로그인합니다.

**Sign in here**를 고르면 R Slack 창 안에서 로그인합니다.

로그인에는 Haiku의 기본 웹 브라우저 대신 R Chromium을 씁니다. RENKU arm64의 기본
브라우저는 WebPositive인데, 그곳에는 WebKit이 없어 실행되지 않습니다. R Chromium은
이 앱과 함께 나온 빌드(154.0.8036.0-15, 114.0.5735.199-15)부터 `slack://` 링크를
Haiku에 넘깁니다. WebPositive도 모르는 스킴으로 가는 페이지를 Haiku에 넘깁니다.

## 동작 방식

`R Slack`은 R Twitter처럼 셸 스크립트입니다. R Chromium의 `content_shell`을
`https://app.slack.com/client`로 실행하며, 다음과 같이 설정합니다.

- 도구 막대를 끕니다.
- 창 이름을 R Slack으로 합니다.
- 프로필을 따로 `~/config/settings/RSlack`에 둡니다.

실행할 때마다 `setmime`으로 `application/x-vnd.Be.URL.slack`의 기본 응용
프로그램으로 자신을 등록합니다. Haiku가 `slack://` 링크를 열 때 찾는 형식이 이
형식입니다.

브라우저 로그인은 `slack://<TEAM>/magic-login/<token>[?host=...]`으로 끝납니다.
R Slack은 이것을
`https://app.slack.com/api/auth.loginMagicBulk?magic_tokens=z-app-<TEAM>-<token>&ssb=1`로
바꿔 별도 창에서 엽니다. 그러면 Slack이 R Slack 프로필에 세션 쿠키를 저장하고,
그다음 클라이언트가 열립니다.

이 변환은 [Zlack](https://github.com/sanguneo/zlack/pull/14)이 자기 클라이언트를
위해 알아낸 방식입니다. `slack://channel?team=...&id=...` 링크는 그 대화를 엽니다.

브라우저가 남기는 기록은 `~/config/settings/RSlack/rslack.log`에 쌓이고, 직전
실행분은 `.log.1`로 남습니다.

## 소스에서 빌드

Haiku에서:

```sh
make install     # ~/config/non-packaged/apps/RSlack 와 Deskbar 항목
```

`python3 tools/make_icon.py`로 아이콘을 다시 그립니다.

## 라이선스

MIT. Slack과 그 로고는 Slack Technologies, LLC의 상표이며, R Slack은 Slack이
만들거나 보증한 것이 아닙니다. `assets/NOTICE`를 보세요.
