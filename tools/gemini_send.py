#!/usr/bin/python3
"""Gemini(M4 Chrome, GEMINI_CDP_PORT 기본 9226 — ssh -L 터널)에 프롬프트 파일을 보내고 답을 저장한다.
  /usr/bin/python3 tools/gemini_send.py <프롬프트> <저장>
건마다 전용 백그라운드 탭을 열고 끝나면 닫는다(새 창은 M4 화면을 가린다) — 그래서 여러 건을 동시에 돌릴 수 있다(tools/gemini_batch.py).
마지막 줄: OK <저장> | TIMEOUT | NOINPUT | BLOCKED(Google 로봇 확인) | NOSEND | BADMODEL <모델> | REFUSED <답 앞부분>
모델은 Pro 여야 한다(2026-11-06: 기본 Flash-Lite 는 거절·끊긴 답이 많았다 — 화면 왼쪽 아래 선택기에서 3.1 Pro). 저장 파일 첫 줄에 모델을 남긴다.
왜 전용 창인가(2026-11-06): 한 탭을 새 채팅으로 돌리면 옛 채팅이 남은 사이에 글을 넣었다가 화면이 바뀌며 글이 사라져, 질문 없이 5분을 기다리는 TIMEOUT 이 났다."""
import json, os, sys, time, urllib.request
sys.path.insert(0, '/Users/talkverse/Hanja/tools'); import grok_cdp as g
import websocket
PORT = os.environ.get('GEMINI_CDP_PORT', '9226'); g.PORT = PORT; g.BASE = 'http://127.0.0.1:' + PORT
src, dst = sys.argv[1], sys.argv[2]
ANS = "[...document.querySelectorAll('model-response')].map(e=>e.innerText)"
BOX = "document.querySelector('rich-textarea .ql-editor, div[contenteditable=true]')"
BUSY = "!!document.querySelector('button[aria-label*=\"중지\"], button[aria-label*=\"Stop\"]')"
SEND = "(()=>{const b=document.querySelector('button.send-button, button[aria-label*=\"보내기\"], button[aria-label*=\"Send\"]');if(b)b.click()})()"
# 2026-11-22: 선택기가 「모드 선택 도구 열기, 현재 Neon 모드 사용 중」(Gemini 4 Hydrogen·Neon·카본)으로 바뀜 — aria-label 도 읽는다.
MODEL = "(()=>{const m=document.querySelector('[aria-label*=\\\"모드 선택 도구\\\"]');if(m){const a=m.getAttribute('aria-label').match(/현재 (.+?) 모드/);if(a)return a[1]}return [...document.querySelectorAll('button')].map(b=>b.innerText.trim()).filter(t=>/Flash|Pro|Argon/.test(t))[0]||''})()"


def browser(method, **params):
    v = json.load(urllib.request.urlopen(g.BASE + '/json/version'))['webSocketDebuggerUrl']
    ws = websocket.create_connection(v.replace(':9222/', ':' + PORT + '/').replace('localhost', '127.0.0.1'), timeout=30, suppress_origin=True)
    ws.send(json.dumps({'id': 1, 'method': method, 'params': params}))
    while True:
        m = json.loads(ws.recv())
        if m.get('id') == 1:
            ws.close(); return m.get('result', m)


def run(c):
    for _ in range(40):  # 입력창·모델 단추가 뜰 때까지
        time.sleep(0.5)
        model = (c.ev(MODEL) or '').strip()
        if model and c.ev("!!" + BOX): break
    else:
        return 'BLOCKED' if 'google.com/sorry' in (c.ev('location.href') or '') else 'NOINPUT'
    if 'Lite' in model or model.startswith(('Hydrogen', '자동')): return 'BADMODEL ' + model
    c.ev(BOX + ".focus()")
    c.call('Input.insertText', text=open(src, encoding='utf-8').read().strip()); time.sleep(1)
    for _ in range(5):
        c.ev(SEND); time.sleep(3)
        if c.ev("document.querySelectorAll('user-query').length"): break
    else:
        return 'NOSEND'
    last, stable, blank = '', 0, 0
    for k in range(60):
        time.sleep(5)
        path = c.ev('location.pathname') or ''
        busy = c.ev(BUSY)
        els = [x for x in (c.ev(ANS) or []) if len(x.strip()) > 40]
        cur = els[-1] if els else ''
        # 생성이 끝났는데 본문이 비면 바로 새로 고친다. 채팅 주소(/app/…)가 생기기 전에 고치면 채팅이 사라진다.
        blank = blank + 1 if not busy and not cur and '/app/' in path else 0
        if blank >= 2:
            blank = 0; c.call('Page.reload'); time.sleep(6); continue
        if cur and cur == last and not busy:
            stable += 1
            if stable >= 2: break
        else: stable = 0
        last = cur
    if not last:
        return 'TIMEOUT %s q %s r %s' % (c.ev('location.pathname'), c.ev("document.querySelectorAll('user-query').length"), c.ev("document.querySelectorAll('model-response').length"))
    if sum(m in last for m in '①②③④⑤') < 5:  # 검수 항목이 없는 답은 저장하지 않는다
        return 'REFUSED ' + last.strip()[:60].replace('\n', ' ')
    open(dst, 'w', encoding='utf-8').write(f'<!-- Gemini 모델: {model} -->\n' + last.strip() + '\n')
    return 'OK ' + dst


tid = browser('Target.createTarget', url='https://gemini.google.com/app', background=True)['targetId']
try:
    r = run(g.CDP({'webSocketDebuggerUrl': f'ws://127.0.0.1:{PORT}/devtools/page/{tid}'}))
finally:
    urllib.request.urlopen(g.BASE + '/json/close/' + tid).read()
print(r); sys.exit(0 if r.startswith('OK') else 1)
