# -*- coding: utf-8 -*-
"""Gemini 지적(실제 오류) 줄만 Grok 이 다시 쓰게 한다(2026-11-22, uk 「fa 시작」 — 줄 단위, Grok 답 그대로 붙임).
  GROK_CDP_PORT=9244 python3 tools/grok_fix_batch.py [--per-room 20]
입력: data/review/triage/<id>.json 의 rewrite [{line(1부터), why}]
편마다 data/grok/fix/<id>.txt(편 전체 줄 + 다시 쓸 줄·이유) 를 보내고 답 → data/grok/fix/<id>.md
답 형식: `N A | 입말 | 글말 | 한국어 | "페르시아어 = 뜻" | emotion=값` (다시 쓸 줄만). 줄 번호·화자가 안 맞으면 한 번 더 요청.
반영은 --apply: 그 줄의 tl_col·tl·ko·note 만 Grok 답으로 바꾸고 rd 는 비운다(Claude 가 독음만 채움). 기록 data/grok/fix/log.tsv.
"""
import glob, json, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRI = os.path.join(ROOT, 'data/review/triage')
FIX = os.path.join(ROOT, 'data/grok/fix')
LEN = {'R1': '2~9단어(1~2문장)', 'R2': '1~2문장', 'R3': '2문장 이내'}
LINE = re.compile(r'^\s*`*\s*(\d+)\s*[.:)]?\s*([A-E])\s*\|(.*)$')


def ep_json(i):
    return glob.glob(os.path.join(ROOT, 'assets/data/dialogues/R*/*/%s.json' % i))[0]


def jobs():
    for f in sorted(glob.glob(os.path.join(TRI, '*.json'))):
        t = json.load(open(f, encoding='utf-8'))
        rw = sorted({int(r['line']): r['why'] for r in t.get('rewrite', [])}.items())
        if rw:
            yield os.path.basename(f)[:-5], rw


def message(i, rw):
    d = json.load(open(ep_json(i), encoding='utf-8'))
    sp = ', '.join('%s=%s' % (k, v) for k, v in d.get('speakers', {}).items())
    out = ['[%s] 페르시아어(테헤란 입말) 회화 한 편의 몇 줄만 네가 새로 써 줘. 원어민 검수에서 걸린 줄이야.' % i,
           '인물: %s / 장면: %s / 반전(%s): %s' % (sp, d.get('scene', ''), d.get('twist_type', ''), d.get('twist', '')),
           '규칙: 다시 쓸 줄만, 줄 번호와 화자는 그대로. 앞뒤 줄과 이야기가 이어지게. 길이 %s. {name} 은 그대로. 12세 이상. 감정 값은 그대로 둬.' % LEN.get(d['region'], '2문장 이내'),
           '형식(줄마다 한 줄, 코드 블록 하나로만): N A | 입말 | 글말 | 한국어 | "페르시아어 = 뜻" | emotion=값', '',
           '지금 편 전체:']
    for k, t in enumerate(d['turns']):
        out.append('%d %s | %s | %s | %s | %s | emotion=%s' % (k + 1, t['speaker'], t['tl_col'], t['tl'], t['ko'], t.get('note', ''), t.get('emotion', 'neutral')))
    out += ['', '다시 쓸 줄(이유):'] + ['%d — %s' % (n, w) for n, w in rw]
    return '\n'.join(out) + '\n'


def parse(text):
    r = {}
    for ln in text.splitlines():
        m = LINE.match(ln)
        if not m:
            continue
        p = [x.strip() for x in m.group(3).split('|')]
        if len(p) >= 4:
            r[int(m.group(1))] = {'speaker': m.group(2), 'tl_col': p[0], 'tl': p[1], 'ko': p[2], 'note': p[3] if len(p) > 3 else ''}
    return r


def ok(i, rw, path):
    if not os.path.exists(path):
        return False
    d = json.load(open(ep_json(i), encoding='utf-8'))
    got = parse(open(path, encoding='utf-8').read())
    return all(n in got and got[n]['speaker'] == d['turns'][n - 1]['speaker'] and got[n]['tl_col'] for n, _ in rw)


def grok(args):
    r = subprocess.run([sys.executable, os.path.join(ROOT, 'tools/grok_text.py')] + args, capture_output=True, text=True)
    print(r.stdout.strip().splitlines()[-1] if r.stdout.strip() else r.stderr[-300:], flush=True)
    if r.returncode == 3:
        sys.exit('Grok 한도 — 멈춤')
    chat = [l[5:] for l in r.stdout.splitlines() if l.startswith('CHAT ')]
    return r.returncode, (chat[0] if chat else '')


def run(per):
    os.makedirs(FIX, exist_ok=True)
    log = open(os.path.join(FIX, 'log.tsv'), 'a')
    chat, n = '', 0
    for i, rw in jobs():
        out = os.path.join(FIX, i + '.md')
        if ok(i, rw, out):
            continue
        msg = os.path.join(FIX, i + '.txt')
        open(msg, 'w', encoding='utf-8').write(message(i, rw))
        if not chat or n >= per:
            rc, chat = grok([msg, out]); n = 1
        else:
            rc, c2 = grok([msg, out, '--chat', chat]); n += 1
        retry = ''
        if not ok(i, rw, out):
            rc, _ = grok(['-m', '[%s] 형식이 틀렸어. 다시 쓸 줄(%s)만, 줄 번호·화자 그대로, "N A | 입말 | 글말 | 한국어 | 뜻 | emotion=값" 형식 코드 블록 하나로.' % (i, ','.join(str(x) for x, _ in rw)), out, '--chat', chat])
            retry = 'format'
        log.write('%s\t%s\t%s\t%s\t%s\n' % (i, ','.join(str(x) for x, _ in rw), 'OK' if ok(i, rw, out) else 'BAD', retry, chat))
        log.flush()


def apply():
    tot = 0
    for i, rw in jobs():
        out = os.path.join(FIX, i + '.md')
        if not ok(i, rw, out):
            print('건너뜀', i); continue
        p = ep_json(i); d = json.load(open(p, encoding='utf-8'))
        got = parse(open(out, encoding='utf-8').read())
        for n, _ in rw:
            t = d['turns'][n - 1]
            for k in ('tl_col', 'tl', 'ko', 'note'):
                t[k] = got[n][k].replace('؟', '?') if k == 'ko' else got[n][k]
            t['rd'] = ''
            t['grok_fix'] = True
            tot += 1
        json.dump(d, open(p, 'w', encoding='utf-8'), ensure_ascii=False, indent=2); open(p, 'a').write('\n')
    print('반영 줄', tot)


if __name__ == '__main__':
    a = sys.argv[1:]
    if '--apply' in a:
        apply()
    else:
        run(int(a[a.index('--per-room') + 1]) if '--per-room' in a else 20)
