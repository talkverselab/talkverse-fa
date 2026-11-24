#!/usr/bin/env python3
"""페르시아어 회화 검사기(2026-11-07, 일본어앱 check_dialogues.py 의 페르시아어판). 오류가 있으면 종료 코드 1.
사용: python3 tools/check_dialogues_fa.py [파일…]  (없으면 assets/data/dialogues/R*/ 전부), --stats 로 묶음 통계만."""
import csv, glob, json, re, sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TURNS = {'R0': (6, 8), 'R1': (6, 8), 'R2': (8, 12), 'R3': (12, 16)}
WORDS = {'R0': (2, 8), 'R1': (2, 9), 'R2': (2, 13), 'R3': (2, 17)}
NEW = {'R0': 3, 'R1': 3, 'R2': 4, 'R3': 4}
EMOTIONS = set('neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle'.split())
TWISTS = {'chaos', 'slip', 'reveal', 'emotion', 'ignore'}
NEED = 'id region island kind purpose domain title emoji scene speakers register twist twist_type flags goal expressions turns'.split()
RD_OK = re.compile(r'^[가-힣0-9 ,.!?…"·~\-{}_a-z()]*$')
BANNED = re.compile(r'[يكة]')  # 아랍 글자 형태
LATIN = re.compile(r'[A-Za-z]')
NAMES = {'سارا', 'نگار', 'آرش', 'رضا'}


def wc(s):
    return len([w for w in re.sub(r'\{[a-z_]+\}', 'X', s).split() if re.search(r'[؀-ۿX0-9]', w)])


def expr_pool():
    p = ROOT / 'data/expressions/top_expressions.csv'
    rows = list(csv.DictReader(open(p, encoding='utf-8')))
    return {r['expr'] for r in rows} | {r['written'] for r in rows}


def check(path, pool):
    d = json.load(open(path, encoding='utf-8'))
    err, warn = [], []
    for k in NEED:
        if k not in d:
            err.append(f'칸 없음 {k}')
    if err:
        return d, err, warn
    reg = d['region']
    if d['id'] != Path(path).stem:
        err.append('id ≠ 파일 이름')
    if d['twist_type'] not in TWISTS:
        err.append(f"twist_type {d['twist_type']}")
    t = d['turns']
    lo, hi = TURNS[reg]
    if not lo <= len(t) <= hi:
        err.append(f'턴 수 {len(t)} (기준 {lo}~{hi})')
    if not 2 <= d['twist'] <= len(t):
        err.append('twist 턴 번호')
    if d['speakers'].get('A') != '{name}':
        err.append('A 는 {name}')
    used = 0
    lo, hi = WORDS[reg]
    for i, u in enumerate(t, 1):
        tag = f"턴{u.get('num')}"
        if u.get('num') != i:
            err.append(f'{tag}: num 순서')
        for k in ('speaker', 'tl', 'tl_col', 'rd', 'ko', 'note'):
            if not str(u.get(k, '')).strip():
                err.append(f'{tag}: {k} 빈칸')
        tl, col, rd = u.get('tl', ''), u.get('tl_col', ''), u.get('rd', '')
        if u.get('emotion') not in EMOTIONS:
            err.append(f"{tag}: emotion {u.get('emotion')}")
        for k, s in (('tl', tl), ('tl_col', col)):
            s2 = re.sub(r'\{[a-z_]+\}', '', s)
            if BANNED.search(s2):
                err.append(f'{tag}: {k} 아랍 글자(ي ك ة)')
            if LATIN.search(s2):
                err.append(f'{tag}: {k} 라틴 문자')
            if '?' in s2 or ',' in s2:
                err.append(f'{tag}: {k} 라틴 문장부호(؟ ، 사용)')
        if re.search(r'می [؀-ۿ]', tl + ' ' + col):
            warn.append(f'{tag}: می 뒤 ZWNJ 확인')
        if not RD_OK.match(rd):
            err.append(f'{tag}: rd 허용 밖 문자 {rd}')
        n = wc(col)
        one_ok = d['kind'] == 'chat' or i == len(t) or i == d['twist'] or u.get('short_ok')  # short_ok: 한 단어가 장면의 장치인 줄(검수 판단, 11-22)
        if col.strip('. …') == '':  # 침묵 턴
            pass
        elif n < lo and not (one_ok and n >= 1):
            err.append(f'{tag}: 단어 {n} (최소 {lo})')
        if n > hi:
            err.append(f'{tag}: 단어 {n} (최대 {hi})')
        if len(u.get('new', [])) > NEW[reg]:
            err.append(f"{tag}: 새 단어 {len(u['new'])}")
        if '=' not in u.get('note', ''):
            warn.append(f'{tag}: note 에 = 없음')
        if d['kind'] == 'chat' and u.get('ui') != 'bubble':
            err.append(f'{tag}: 채팅 편 ui=bubble')
        if any(e in col or e in tl for e in pool):
            used += 1
    if used < 2:
        err.append(f'표현 풀 턴 {used}개(최소 2)')
    for e in d['expressions']:
        if e not in pool:
            warn.append(f'풀에 없는 표현 {e}')
    return d, err, warn


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    files = args or sorted(glob.glob(str(ROOT / 'assets/data/dialogues/R*/*/*.json')))
    pool = expr_pool()
    rank = {}
    for r in csv.DictReader(open(ROOT / 'assets/data/freq/lang_es_top.csv', encoding='utf-8')):
        rank.setdefault(r['word'], int(r['rank']) if r['rank'].isdigit() else 9999)
    bad = 0
    tw, regs, isl, lead = Counter(), Counter(), Counter(), Counter()
    turns = 0
    for f in files:
        d, err, warn = check(f, pool)
        tw[d.get('twist_type')] += 1
        regs[d.get('region')] += 1
        isl[d.get('island')] += 1
        turns += len(d.get('turns', []))
        if err:
            bad += 1
        if '--stats' not in sys.argv:
            for e in err:
                print(f"✗ {Path(f).stem}: {e}")
            for w in warn:
                print(f"  ! {Path(f).stem}: {w}")
    n = len(files)
    print(f'편 {n} · 턴 {turns} · 오류 편 {bad} · 레벨 {dict(regs)} · 주제 {dict(isl)}')
    print(f"반전 {dict(tw)} · chaos {tw['chaos'] / max(n, 1):.0%}")
    sys.exit(1 if bad else 0)


main()
