"""회화 턴에 문장 내용어(레마) 붙이기 — 일본어앱 tools/add_lemmas.py 의 페르시아어판(2026-11-04).

각 턴에 "lemmas": [[표면형, 기본형, 한글 읽기], …] 를 쓴다. 기본형 = tools/fa_morph.py 의 첫 토큰(동사는 부정사).
접사 토큰(می-·-م …)과 기능어(대명사·전치사·접속사 등)는 빼고 내용어만. 읽기는 단어 그림 리스트(data/words_art/fa.csv)에 있으면 그 독음.
단어장(assets/data/vocab/travel_words.json)에 없는 기본형은 빈도순으로 data/review/write/missing_lemmas.csv — uk 세션에 넘겨 단어·그림을 만든다.
사용: <hazm venv>/bin/python -I tools/add_lemmas_fa.py   (저장소 루트에서)
"""
import csv, json, os, sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__))))
from fa_morph import analyse, words  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLG = os.path.join(ROOT, 'assets/data/dialogues/L1.json')
VOCAB = os.path.join(ROOT, 'assets/data/vocab/travel_words.json')
CLIFF = os.path.join(ROOT, 'data/words_art/fa.csv')
OUT_MISSING = os.path.join(ROOT, 'data/review/write/missing_lemmas.csv')

FUNCTION = set('''و به در از که این آن اون را رو با برای تا هم یا اما ولی اگر اگه چون پس هر همه یه یک من تو او ما شما آنها اونا ایشان
خود خودم خودت خودش هیچ چه چی کی کجا چرا چطور چند نه بله آره هی ای اوه خب دیگه دیگر فقط هنوز الان حالا اینجا اونجا آنجا
بودن شدن است هست نیست باید'''.split())
NAMES = {'مینجون', 'سارا', 'نگار', 'آرش', 'رضا'}  # 인물 이름은 단어장 대상이 아님
FUNCTION |= NAMES

reading, rank = {}, {}
if os.path.exists(CLIFF):
    for r in csv.DictReader(open(CLIFF, encoding='utf-8')):
        reading.setdefault(r['word'], r['reading'])
        rank.setdefault(r['word'], int(r['rank']))

vocab = set()
v = json.load(open(VOCAB, encoding='utf-8'))
for t in v.get('themes', []):
    for sec in t.get('sections', []):
        for w in sec.get('words', []):
            vocab.add(w.get('tx', '').strip())

d = json.load(open(DLG, encoding='utf-8'))
missing = {}
n_turns = n_lem = 0
for ep in d.get('episodes', []):
    for t in ep.get('turns', []):
        out, seen = [], set()
        for w in words(t.get('es', '')):
            toks = analyse(w)
            base = toks[0] if toks else w
            if base.startswith('-') or base.endswith('-') or base in FUNCTION or len(base) < 2:
                continue
            if base in seen:
                continue
            seen.add(base)
            out.append([w, base, reading.get(base, '')])
            if base not in vocab:
                m = missing.setdefault(base, {'count': 0, 'rank': rank.get(base, 99999), 'example': w})
                m['count'] += 1
        t['lemmas'] = out
        n_turns += 1
        n_lem += len(out)

with open(DLG, 'w', encoding='utf-8') as f:
    json.dump(d, f, ensure_ascii=False, indent=1)
    f.write('\n')
os.makedirs(os.path.dirname(OUT_MISSING), exist_ok=True)
with open(OUT_MISSING, 'w', encoding='utf-8', newline='') as f:
    w = csv.writer(f, lineterminator='\n')
    w.writerow(['base', 'reading', 'cliff_rank', 'count_in_dialogues', 'example_surface'])
    for b, m in sorted(missing.items(), key=lambda kv: (kv[1]['rank'], -kv[1]['count'])):
        w.writerow([b, reading.get(b, ''), m['rank'] if m['rank'] < 99999 else '', m['count'], m['example']])
print(f'turns {n_turns} · lemmas {n_lem} · missing {len(missing)} → {OUT_MISSING}')
