#!/usr/bin/python3
"""회화 장면 컷(만화 1컷, A·B 한 쌍 = 1컷, 글자·말풍선 없음)을 Grok 방에 편마다 4장씩 요청하고,
받은 그림을 1168×784 로 맞춰 data/scene/<편id>/cut<N>.jpg 에 둔다(로컬, 커밋 안 함). --push 면 tools/scene_upload.py 로 R2·D1(lang fa).
  GROK_CDP_PORT=<M4 포트> GROK_ROOM=<방 주소> GROK_ATT_DIR=<M4 첨부 폴더> /usr/bin/python3 tools/grok_scene_batch.py <편id> ... [--push] [--female]
일본어앱 tools/grok_scene_batch.py 를 옮김(2026-11-22, uk 「장면 컷 10장」). 첨부 = 인물 기준 그림 data/review/art/chars_fa_v1.jpg."""
import base64, glob, json, os, re, subprocess, sys, time
sys.path.insert(0, '/Users/talkverse/Hanja/tools'); import grok_cdp as g
g.BASE = 'http://127.0.0.1:' + os.environ.get('GROK_CDP_PORT', '9244')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, 'data/scene')
ATT_DIR = os.environ.get('GROK_ATT_DIR', os.path.join(ROOT, 'data/review/art'))
SHEET = os.path.join(ATT_DIR, 'chars_fa_v1.jpg')
CAST_WORK, CAST_SCHOOL, CAST_SHEETS = {}, {}, {}
ROOM = os.environ.get('GROK_ROOM', '')
a = sys.argv[1:]
if not ROOM and '--fetch-only' not in a: sys.exit('GROK_ROOM(이어 쓸 대화 주소)을 지정하세요 — 요청마다 새 방 금지')
tab = a[a.index('--tab') + 1] if '--tab' in a else 'grok.com'
push = '--push' in a
fetch_only = '--fetch-only' in a
ids = [x for x in a if not x.startswith('--') and x != tab]
# `편id:N` = 그 편은 앞 N컷만(uk 11-22 「장면 컷 딱 10장」)
MAXCUT = {x.split(':')[0]: int(x.split(':')[1]) for x in ids if ':' in x}
ids = [x.split(':')[0] for x in ids]
# 인물 기준 그림 chars_fa_v1(왼쪽부터 1~6번) — data/review/art/chars_fa_v1.md
CAST = {'سارا': '시트 1번 사라(연한 하늘색 루사리를 느슨하게, 휴대폰, 밝게 웃는 얼굴)',
        'نگار': '시트 2번 네가르(남색 루사리, 올리브색 롱 코트, 안경, 스케치북 든 토트백)',
        'آرش': '시트 3번 아라시(키 큼, 흰 셔츠·갈색 앞치마, 작은 찻잔)',
        'رضا': '시트 4번 레자(빨간 트랙 재킷, 해바라기씨 봉지, 장난스러운 표정)',
        '{name}': '시트 5번 남자 학습자(보라빛 인디고 후드티, 갈색 백팩, 국적이 드러나지 않는 얼굴)'}
FEMALE = '--female' in sys.argv[1:]
if FEMALE:
    CAST['{name}'] = '시트 6번 여자 학습자(크림색 루사리를 느슨하게, 남색 롱 재킷) — 남자 학습자 대신 이 여자 학습자로'

def who(name):
    if name in CAST: return CAST[name]
    if name in CAST_WORK: return CAST_WORK[name]
    if name in CAST_SCHOOL: return CAST_SCHOOL[name]
    return f'{name}(시트에 없는 조연 — 이름·직업에 맞는 차림의 이란인, 여성은 루사리, 같은 톤, 실존 인물 닮지 않게)'

def find(eid):
    if eid.endswith('.json'): return eid
    fs = glob.glob(os.path.join(ROOT, f'assets/data/dialogues/R*/*/{eid}.json'))
    return fs[0] if fs else None

def cast_kinds(ep):
    sp = set(ep['speakers'].values())
    return [k for k, m in (('work', CAST_WORK), ('school', CAST_SCHOOL)) if sp & set(m)]

def att_note(ep):
    ks = cast_kinds(ep); n = 3; out = []
    for k in ks:
        out.append(f", 첨부 {n} = 조연 시트({'직장' if k == 'work' else '학교·오사카'}, 왼쪽부터 1~4번 — 그 조연의 얼굴·머리·옷도 그대로)"); n += 1
    return ''.join(out)

def attachments(ep):
    return SHEET

def prompt(ep, cuts, part):
    sp = ep['speakers']
    lines = []
    for n, pair in cuts:
        ds = ' / '.join(f"{t['speaker']}「{t['tl_col']}」({t['ko']})" for t in pair)
        lines.append(f'컷{n}: {ds}')
    cast = ', '.join(f'{k} = {who(v)}' for k, v in sp.items())
    return (f"[SC-{ep['id']}{'-F' if FEMALE else ''}-{part}] **이미지 {len(cuts)}장을 생성해 주세요**(글 설명 없이 그림만, 컷마다 한 장씩 따로 {len(cuts)}장). 페르시아어 학습 앱 회화의 장면 컷입니다.\n"
            f"첨부 1 = 우리 앱 인물 기준 그림(이 인물들의 얼굴·머리·옷·그림 톤을 그대로).\n"
            f"톤: 첨부 그림과 같은 부드러운 일러스트, 따뜻한 조명, 이란(테헤란)의 실제 장소 느낌, 여성 인물은 루사리 착용. 3:2 가로. "
            f"**그림 안에 글자·말풍선·간판 글씨·로고 없음**(말풍선은 앱이 얹습니다). 실존 인물·브랜드 금지.\n"
            f"장면: {ep['scene']}\n등장: {cast}\n"
            f"각 컷은 아래 두 대사가 오가는 순간의 표정·동작·장소를 한 장으로(대사는 그리지 말고 상황만):\n" + '\n'.join(lines) +
            f"\n지금 바로 이미지 {len(cuts)}장을 생성하세요.")

def imgs_ready(c, want):
    srcs = c.ev("(()=>{const r=[...document.querySelectorAll('.response-content-markdown')];const e=r[r.length-1];if(!e)return [];return [...e.closest('[class*=message],[class*=response]')?.querySelectorAll('img')||e.querySelectorAll('img')].map(i=>i.src)})()") or []
    busy = c.ev("!![...document.querySelectorAll('button')].find(e=>(e.getAttribute('aria-label')||'')==='응답 중지')")
    real = [s for s in srcs if s.startswith('http') and 'assets.grok.com' in s]
    data = [s for s in srcs if s.startswith('data:')]
    return real, (busy or data)

def last_imgs(c):
    # 마지막 답 근처의 생성 그림(assets.grok.com) — 답 요소 밖 갤러리에 붙는 경우가 있어 문서 전체에서 마지막 것들을 본다
    # 첨부 썸네일(64px 안팎)은 빼고, 생성 그림(가로 300px 이상)만. 새 방에서는 첨부도 같은 주소·크기로 떠서 '/generated/' 만(2026-11-22 첨부가 컷1·2 로 저장됨)
    return c.ev("[...document.querySelectorAll('img')].filter(i=>i.src.includes('assets.grok.com')&&i.src.includes('/generated/')&&i.naturalWidth>=300).map(i=>i.src)") or []

def fetch_b64(c, url):
    js = ("fetch(%s,{credentials:'include'}).then(r=>r.blob()).then(b=>new Promise(ok=>{const f=new FileReader();f.onload=()=>ok(f.result);f.readAsDataURL(b)}))" % json.dumps(url))
    d = c.ev(js)
    return base64.b64decode(d.split(',', 1)[1]) if isinstance(d, str) and d.startswith('data:') else None

def fit(src, dst):
    # 3:2 로 가운데 자르고 1168×784
    w = int(subprocess.run(['sips', '-g', 'pixelWidth', src], capture_output=True, text=True).stdout.split()[-1])
    h = int(subprocess.run(['sips', '-g', 'pixelHeight', src], capture_output=True, text=True).stdout.split()[-1])
    if w / h > 1.5: cw, ch = int(h * 1.5), h
    else: cw, ch = w, int(w / 1.5)
    subprocess.run(['sips', '-s', 'format', 'jpeg', '-s', 'formatOptions', '88', '--cropToHeightWidth', str(ch), str(cw), src, '--out', dst], capture_output=True)
    subprocess.run(['sips', '-z', '784', '1168', dst], capture_output=True)

def do(eid):
    path = find(eid)
    if not path: print('편 없음', eid); return False
    ep = json.load(open(path, encoding='utf-8'))
    turns = ep['turns']
    cuts = [((i // 2) + 1, turns[i:i + 2]) for i in range(0, len(turns), 2)]
    if eid in MAXCUT: cuts = cuts[:MAXCUT[eid]]
    out = os.path.join(ART, ep['id'] + ('_f' if FEMALE else ''))
    os.makedirs(out, exist_ok=True)
    # 없는 컷만 골라 4장씩 요청(카오스·심쿵으로 바뀐 턴의 컷만 지우고 다시 받을 때 — 2026-11-03)
    missing = [c for c in cuts if not os.path.exists(os.path.join(out, f'cut{c[0]}.jpg'))]
    per = int(os.environ.get('SCENE_PER_REQ', '1'))  # 11-22 페르시아어: Grok 「빠른」이 한 요청에 1장만 줌 → 1장씩
    for part, k in enumerate(range(0, len(missing), per), 1):
        chunk = missing[k:k + per]
        if all(os.path.exists(os.path.join(out, f'cut{n}.jpg')) for n, _ in chunk):
            print('SKIP', ep['id'], part, flush=True); continue
        pf = os.path.join(ROOT, 'data/scene_prompts', f"{ep['id']}{'_f' if FEMALE else ''}_scene{part}_prompt.md")
        open(pf, 'w', encoding='utf-8').write(prompt(ep, chunk, part))
        c = g.CDP(g.tab(tab)); c.call('Page.bringToFront')
        before = set() if fetch_only else set(last_imgs(c))
        if fetch_only:
            last = 'OK'
        else:
          # 한 방에서 이어서(2026-11-06 사용자 지시: 새 방은 통일성이 깨지고 토큰을 많이 씀). 다른 화면에 있을 때만 그 방으로 돌아간다.
          # 긴 방에서 그림 없이 "완료"만 답하면(2026-11-03) FAIL 로 멈춘다 — 그때만 사용자에게 알리고 GROK_ROOM 을 새 방으로 바꾼다.
          if ROOM.rsplit('/', 1)[-1] not in (c.ev('location.href') or ''):
              c.call('Page.navigate', url=ROOM); time.sleep(8)
          r = subprocess.run(['/usr/bin/python3', os.path.join(ROOT, 'tools/grok_send.py'), pf, pf.replace('_prompt.md', '_answer.md'),
                            '--tab', tab, '--wait', '90', '--attach', attachments(ep)], capture_output=True, text=True)
          last = (r.stdout.strip().splitlines() or [''])[-1]
        if last.startswith('LIMIT'):
            print('LIMIT', ep['id'], last, flush=True); return False
        new = []
        idle = 0
        for _ in range(80):  # 그림은 글보다 늦게 온다 — 새 assets 그림이 컷 수만큼 될 때까지(최대 20분)
            c = g.CDP(g.tab(tab))
            cur = [s for s in last_imgs(c) if s not in before]
            seen = []
            for s in cur:
                if s not in seen: seen.append(s)
            busy = c.ev("!![...document.querySelectorAll('button')].find(e=>(e.getAttribute('aria-label')||'')==='응답 중지')") or \
                   c.ev("[...document.querySelectorAll('img')].some(i=>i.src.startsWith('data:image')&&i.naturalWidth>200)")
            new = seen
            if len(new) >= len(chunk) and not busy: break
            # 답이 끝났는데 그림이 1분 넘게 0장이면 그림 없이 끝난 것(2026-11-03 여러 번) → 빨리 실패하고 같은 방에서 재시도
            idle = (idle + 1) if (not busy and not new) else 0
            if idle >= 5: break
            time.sleep(15)
        print(ep['id'], part, 'imgs', len(new), flush=True)
        if len(new) < len(chunk):
            print('FAIL', ep['id'], part, '그림 수 부족', len(new), flush=True); return False
        for (n, _), url in zip(chunk, new[:len(chunk)]):
            b = fetch_b64(c, url)
            if not b: print('FAIL 받기', url[:80]); return False
            tmp = os.path.join(out, f'.raw{n}')
            open(tmp, 'wb').write(b)
            fit(tmp, os.path.join(out, f'cut{n}.jpg')); os.remove(tmp)
        print('OK', ep['id'], part, [n for n, _ in chunk], flush=True)
    return True

def upload(eps):
    eps = [e + ('_f' if FEMALE else '') for e in eps]
    for attempt in (1, 2):
        u = subprocess.run(['/usr/bin/python3', os.path.join(ROOT, 'tools/scene_upload.py')] + eps, capture_output=True, text=True)
        out = (u.stdout.strip().splitlines() or [''])[-1]
        if u.returncode == 0 and out.startswith('DONE'):
            print('UPLOAD', out, flush=True); return
        print(f'UPLOAD FAIL({attempt}) rc={u.returncode} {out} | {(u.stderr.strip().splitlines() or [""])[-1][:200]}', flush=True)
        time.sleep(10)

os.makedirs(os.path.join(ROOT, 'data/scene_prompts'), exist_ok=True)
done, failed = [], []
for eid in ids:
    ok = do(eid) or do(eid)  # 그림이 안 오면 같은 방에서 한 번 더(2026-11-03 r1_culture_b5: 그림 대신 다른 경로로 1장만 옴)
    if ok: done.append(eid)
    else:
        failed.append(eid); print('SKIPFAIL', eid, flush=True)
        if False: break
        if len(failed) >= 5 and not done[-3:]: print('STOP 연속 실패', flush=True); break
        continue
if push and done: upload(done)
print('DONE', len(done), 'FAILED', ' '.join(failed), flush=True)
