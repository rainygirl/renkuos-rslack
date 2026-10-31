# R Slack

[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md)

RenkuOS(Haiku)에서 Slack을 자체 창으로 띄우는 앱입니다. 브라우저 툴바 없는
R Chromium으로 동작하며, Slack 데스크톱 앱처럼 웹 브라우저에서 로그인한 뒤
세션을 R Slack으로 넘겨받습니다.

## pkgman으로 설치

| Haiku | 명령 |
| --- | --- |
| 32비트 x86 (x86_gcc2) | `pkgman add-repo https://pkgman.rainygirl.com/x86_gcc2`<br>`pkgman install rslack_x86` |
| x86_64 | `pkgman add-repo https://pkgman.rainygirl.com/x86_64`<br>`pkgman install rslack` |
| arm64 | `pkgman add-repo https://pkgman.rainygirl.com/arm64`<br>`pkgman install rslack` |

R Chromium도 함께 설치됩니다. 설치 후 Deskbar -> Applications에서 **R Slack**을
실행하고 **Open the browser**를 골라 그 브라우저에서 로그인하십시오. 로그인이
끝나면 브라우저가 R Slack으로 넘겨줍니다.

32비트 x86에서는 Slack이 뜨기까지 1~2분 걸립니다. 준비될 때까지 창에 회색 틀만
보입니다.

## 소스에서 설치

Haiku 기기에서:

```sh
make install     # ~/config/non-packaged/apps/RSlack, Deskbar 항목
```

## AI 사용 고지

R Slack의 일부는 AI 코딩 도구(Anthropic Claude)의 도움을 받아 개발했습니다.
모든 코드는 작성자가 검토하고 테스트했습니다.

## 라이선스

MIT. Slack과 로고는 Slack Technologies, LLC의 상표이며, R Slack은 Slack이
만들거나 보증한 앱이 아닙니다. [NOTICE](assets/NOTICE)를 참고하십시오. 개발
기록은 [AGENTS.md](AGENTS.md)에 있습니다.
