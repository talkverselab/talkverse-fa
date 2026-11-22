# -*- coding: utf-8 -*-
"""회화 편 JSON ↔ Grok 원고(한 줄 형식). Grok 은 입말(tl_col)·한국어·note·감정만 쓴다 — 글말 tl·독음 rd 는 받은 뒤 이 세션이 채운다.
  python3 tools/fa_grok_io.py export <편.json> [...]          → data/grok/src/<id>.txt (첨부용)
  python3 tools/fa_grok_io.py import <답.md> <편.json>         → 편 JSON 에 반영(tl·rd 는 비우고 "fill":true 표시)
  python3 tools/fa_grok_io.py skeleton <편.json> [...]        → data/grok/skel/<id>.txt — 대사 없는 뼈대(2026-11-18 원칙: 대사는 Grok 이 처음부터)
  답이 칸 여섯(입말|글말|한국어|note|emotion)이면 글말 tl 도 Grok 것을 그대로 쓰고, 독음 rd 만 비워 둔다.

원고 형식:
  === r1_friends_b1
  kind: short / title: … / scene: … / where: … / b: سارا / register: casual / twist: 5 slip / goal: … / expressions: آره; خب
  A | 입말 페르시아어 | 한국어 | note | emotion=cheerful+surprised at=21:03 stamp=😂 read=false
emotion 이 여럿이면 문장(. ! ? ؟ … 뒤) 순서대로 붙는다 → JSON segs.
"""
import json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'data/grok/src')
HEAD = ('kind', 'title', 'scene', 'where', 'register', 'goal')


def export(path):
    d = json.load(open(path, encoding='utf-8'))
    L = ['=== ' + d['id']]
    for k in HEAD:
        L.append('%s: %s' % (k, d.get(k, '')))
    for k, v in d['speakers'].items():
        if k != 'A':
            L.append('%s: %s' % (k.lower(), v))
    L.append('twist: %s %s' % (d.get('twist', ''), d.get('twist_type', '')))
    L.append('expressions: ' + '; '.join(d.get('expressions', [])))
    for t in d['turns']:
        emo = '+'.join(s[0] for s in t['segs']) if t.get('segs') else t.get('emotion', 'neutral')
        ex = ['emotion=' + emo]
        for k in ('at', 'stamp'):
            if t.get(k):
                ex.append('%s=%s' % (k, t[k]))
        if t.get('read') is False:
            ex.append('read=false')
        L.append(' | '.join([t['speaker'], t['tl_col'], t['ko'], t.get('note', ''), ' '.join(ex)]))
    os.makedirs(SRC, exist_ok=True)
    out = os.path.join(SRC, d['id'] + '.txt')
    open(out, 'w', encoding='utf-8').write('\n'.join(L) + '\n')
    print(out)


def skeleton(path):
    d = json.load(open(path, encoding='utf-8'))
    L = ['=== ' + d['id'], 'level: ' + d.get('region', '')]
    for k in HEAD:
        L.append('%s: %s' % (k, d.get(k, '')))
    for k, v in d['speakers'].items():
        if k != 'A':
            L.append('%s: %s' % (k.lower(), v))
    L.append('twist: %s %s' % (d.get('twist', ''), d.get('twist_type', '')))
    L.append('expressions: ' + '; '.join(d.get('expressions', [])))
    for t in d['turns']:
        note = t.get('note', '')
        ex = [x for x in t.get('tags', []) if x.startswith('expr:')]
        want = '; '.join(x[5:] for x in ex)
        extra = ['emotion=' + ('+'.join(s[0] for s in t['segs']) if t.get('segs') else t.get('emotion', 'neutral'))]
        for k in ('at', 'stamp'):
            if t.get(k):
                extra.append('%s=%s' % (k, t[k]))
        if t.get('read') is False:
            extra.append('read=false')
        tw = ' | ★반전 줄' if str(t.get('num')) == str(d.get('twist', '')).split()[0] else ''
        L.append('%s | 표현: %s | %s%s' % (t['speaker'], want or '-', ' '.join(extra), tw))
    out = os.path.join(ROOT, 'data/grok/skel', d['id'] + '.txt')
    os.makedirs(os.path.dirname(out), exist_ok=True)
    open(out, 'w', encoding='utf-8').write('\n'.join(L) + '\n')
    print(out)


SENT = re.compile(r'(?<=[.!?؟…])\s+')


def parse(text):
    head, turns = {}, []
    for ln in text.splitlines():
        ln = ln.strip().strip('`')
        if not ln or ln.startswith('==='):
            continue
        if '|' in ln and re.match(r'^[A-E]\s*\|', ln):
            p = [x.strip() for x in ln.split('|')]
            if len(p) >= 6:  # 입말 | 글말 | 한국어 | note | emotion
                ex = dict(re.findall(r'(\w+)=(\S+)', p[5]))
                turns.append({'speaker': p[0], 'tl_col': p[1], 'tl': p[2], 'ko': p[3], 'note': p[4], **ex})
                continue
            p += [''] * (5 - len(p))
            ex = dict(re.findall(r'(\w+)=(\S+)', p[4]))
            turns.append({'speaker': p[0], 'tl_col': p[1], 'ko': p[2], 'note': p[3], **ex})
        elif ':' in ln:
            k, v = ln.split(':', 1)
            head[k.strip()] = v.strip()
    return head, turns


def similar(reply, path):
    """Grok 답과 Claude 초안 입말의 줄별 비슷한 정도(0~1) — 0.6 넘는 줄이 있으면 다시 요청."""
    from difflib import SequenceMatcher
    d = json.load(open(path, encoding='utf-8'))
    _, turns = parse(open(reply, encoding='utf-8').read())
    return [round(SequenceMatcher(None, o.get('tl_col', ''), n['tl_col']).ratio(), 2) for o, n in zip(d['turns'], turns)]


def imp(reply, path):
    d = json.load(open(path, encoding='utf-8'))
    head, turns = parse(open(reply, encoding='utf-8').read())
    old = d['turns']
    if len(turns) != len(old) or [t['speaker'] for t in turns] != [t['speaker'] for t in old]:
        raise SystemExit('턴 수·화자 순서가 다름: %d vs %d' % (len(turns), len(old)))
    for k in ('title', 'scene'):
        if head.get(k):
            d[k] = head[k]
    for o, n in zip(old, turns):
        o['tl_col'], o['ko'], o['note'] = n['tl_col'], n['ko'], n['note'] or o.get('note', '')
        emos = (n.get('emotion') or o.get('emotion', 'neutral')).split('+')
        o.pop('segs', None)
        sents = [s for s in SENT.split(n['tl_col']) if s]
        if len(emos) > 1 and len(sents) == len(emos):
            o['segs'] = [[e, s] for e, s in zip(emos, sents)]
        o['emotion'] = emos[0]
        for k in ('at', 'stamp'):
            if n.get(k):
                o[k] = n[k]
        o['tl'] = n.get('tl', ''); o['rd'] = ''; o['fill'] = True
    d['grok'] = True
    json.dump(d, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('반영', path, len(old), '턴 — tl·rd 채우기 필요')


if __name__ == '__main__':
    a = sys.argv[1:]
    if a[0] == 'export':
        for p in a[1:]:
            export(p)
    elif a[0] == 'skeleton':
        for p in a[1:]:
            skeleton(p)
    elif a[0] == 'similar':
        print(similar(a[1], a[2]))
    elif a[0] == 'import':
        imp(a[1], a[2])
