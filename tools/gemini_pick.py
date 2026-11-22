#!/usr/bin/python3
"""Gemini 모델 선택기를 높은 모델(4 Argon → 3.1 Pro)로 돌린다. 한도 중이면 고르지 않는다.
  GEMINI_CDP_PORT=9226 /usr/bin/python3 tools/gemini_pick.py   출력: PICKED <모델> | LIMIT <문구> | NOBUTTON"""
import json, os, sys, time, urllib.request
sys.path.insert(0, '/Users/talkverse/Hanja/tools'); import grok_cdp as g
import websocket
P = os.environ.get('GEMINI_CDP_PORT', '9226'); g.PORT = P; g.BASE = 'http://127.0.0.1:' + P
v = json.load(urllib.request.urlopen(g.BASE + '/json/version'))['webSocketDebuggerUrl']
ws = websocket.create_connection(v.replace('localhost', '127.0.0.1'), timeout=30, suppress_origin=True)
ws.send(json.dumps({'id': 1, 'method': 'Target.createTarget', 'params': {'url': 'https://gemini.google.com/app', 'background': True}}))
while True:
    m = json.loads(ws.recv())
    if m.get('id') == 1: tid = m['result']['targetId']; break
r = 'NOBUTTON'
try:
    c = g.CDP({'webSocketDebuggerUrl': f'ws://127.0.0.1:{P}/devtools/page/{tid}'})
    time.sleep(8)
    # 2026-11-23 Gemini 화면이 바뀜: 단추 = 「모드 선택 도구 열기, 현재 … 모드」, 메뉴 = 자동 모드 · 일상생활 지원(Hydrogen) · 심층 분석(Neon) · 코드 및 복잡한 작업(카본) → 검수는 「심층 분석」
    if c.ev("(()=>{const b=[...document.querySelectorAll('button')].find(b=>/Flash|Pro|Argon|Lite/.test(b.innerText)||(b.getAttribute('aria-label')||'').includes('모드 선택'));if(b){b.click();return 1}return 0})()"):
        time.sleep(2)
        for name in ('심층 분석', 'Neon', 'Argon', 'Pro'):
            st = c.ev("(()=>{const e=[...document.querySelectorAll('[role=menuitem],[role=menuitemradio],.mat-mdc-menu-item')].find(e=>e.innerText.includes('%s'));if(!e)return 'none';const t=e.innerText.replace(/\\s+/g,' ');if(/한도/.test(t))return 'LIMIT '+t;e.click();return 'PICKED '+t})()" % name)
            r = st
            if st.startswith('PICKED'): break
        time.sleep(2)
finally:
    urllib.request.urlopen(g.BASE + '/json/close/' + tid).read()
print(r[:90])
