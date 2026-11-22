# -*- coding: utf-8 -*-
"""회화 대사 Grok 작성 일괄(2026-11-18 원칙: Claude 초안 → Grok 이 대사를 처음부터, 그대로 붙임).
  GROK_CDP_PORT=9244 python3 tools/grok_write_batch.py <편 id 목록 파일> [--chat <방>] [--per-room 25]
편마다: 뼈대(data/grok/skel/<id>.txt) 첨부 + 파일 이름 한 줄 → 답 data/grok/w/<id>.md
→ 초안 입말과 0.9 이상 같은 줄(표현 하나뿐인 짧은 줄 제외)이 있으면 그 줄 번호를 대고 한 번 더 요청(두 번째 답을 그대로 씀).
방은 per-room 편마다 새로(첫 메시지 = 규칙 파일 첨부). 한도 문구(종료 코드 3)면 멈춤. 진행은 data/grok/w/progress.tsv.
"""
import glob, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fa_grok_io as IO

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W = os.path.join(ROOT, 'data/grok/w')
RULES = os.path.join(ROOT, 'tools/prompts/write_grok_fa.md')


def ep_json(i):
    return glob.glob(os.path.join(ROOT, 'assets/data/dialogues/R*/*/%s.json' % i))[0]


def grok(args):
    r = subprocess.run([sys.executable, os.path.join(ROOT, 'tools/grok_text.py')] + args, capture_output=True, text=True)
    print(r.stdout.strip().splitlines()[-1] if r.stdout.strip() else r.stderr[-300:], flush=True)
    if r.returncode == 3:
        sys.exit('Grok 한도 — 멈춤')
    chat = [l[5:] for l in r.stdout.splitlines() if l.startswith('CHAT ')]
    return r.returncode, (chat[0] if chat else '')


def bad_lines(out, path):
    d = json.load(open(path, encoding='utf-8'))
    _, turns = IO.parse(open(out, encoding='utf-8').read())
    if len(turns) != len(d['turns']):
        return None
    sims = IO.similar(out, path)
    exprs = set(d.get('expressions', []))
    return [k + 1 for k, (s, t) in enumerate(zip(sims, turns)) if s >= 0.9 and t['tl_col'].strip(' .!؟?…') not in exprs and len(t['tl_col']) > 14]


import json


def main():
    a = sys.argv[1:]
    chat = a[a.index('--chat') + 1] if '--chat' in a else ''
    per = int(a[a.index('--per-room') + 1]) if '--per-room' in a else 25
    ids = [x.strip() for x in open(a[0]) if x.strip()]
    os.makedirs(W, exist_ok=True)
    log = open(os.path.join(W, 'progress.tsv'), 'a')
    n_room = 0 if not chat else 1
    for i in ids:
        out = os.path.join(W, i + '.md')
        if os.path.exists(out) and os.path.getsize(out) > 200:
            continue
        path, skel = ep_json(i), os.path.join(ROOT, 'data/grok/skel/%s.txt' % i)
        if not chat or n_room >= per:
            first = os.path.join(W, '_first.txt')
            open(first, 'w', encoding='utf-8').write('첨부한 write_grok_fa.md 가 이 방의 규칙이야. 꼭 지켜 줘. 앞으로는 파일 이름 한 줄만 보낼게 — 그때마다 첨부된 뼈대로 대사를 처음부터 써서 코드 블록 하나로만 답해. 첫 편: %s.txt' % i)
            rc, chat = grok([first, out, RULES, skel])
            n_room = 1
        else:
            rc, c2 = grok(['-m', i + '.txt', out, skel, '--chat', chat])
            n_room += 1
        b = bad_lines(out, path) if rc == 0 else None
        retry = ''
        if b is None:
            rc, _ = grok(['-m', '%s.txt — 형식이 틀렸어(줄 수·화자 순서가 뼈대와 같아야 해). 같은 편을 처음부터 다시, 코드 블록 하나로.' % i, out, '--chat', chat])
            b = bad_lines(out, path) or []
            retry = 'format'
        if b:
            rc, _ = grok(['-m', '%s.txt — %s번째 줄이 너무 흔한 말이야. 표현은 남기고 그 줄들을 네 말로 더 구체적으로 다시 써서 편 전체를 다시 줘.' % (i, ','.join(map(str, b))), out, '--chat', chat])
            retry += ' lines' + ','.join(map(str, b))
        log.write('%s\t%s\t%s\t%s\n' % (i, IO.similar(out, path) if os.path.exists(out) else '', retry.strip(), chat))
        log.flush()


if __name__ == '__main__':
    main()
