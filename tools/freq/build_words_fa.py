"""절벽 단어 표 — 단어 그림 리스트(data/words_art/fa.csv, 1,500어) + 빈도 통계 → assets/data/freq/lang_es_top.csv,
회화 레마 중 1,500위 밖이면서 단어장에 있는 것 → assets/data/freq/conv_words_fa.json(「회화 단어 포함」 버튼, 2026-11-07).
기존 표의 Conv 행(회화 레마 보충, rank 3001~)은 그대로 둔다.
  python3 tools/freq/build_words_fa.py <순위·단어·횟수 tsv> <전체 토큰 수>   (저장소 루트에서)
"""
import collections, csv, json, sys

TOP = 'assets/data/freq/lang_es_top.csv'
ART = 'data/words_art/fa.csv'
CONV = 'assets/data/freq/conv_words_fa.json'
NAMES = {'مینجون', 'سارا', 'نگار', 'آرش', 'رضا'}
HEAD = ['rank', 'word', 'pos', 'gender', 'ko', 'freq', 'cum_pct', 'region', 'cefr', 'rd']
tsv, total = sys.argv[1], int(sys.argv[2])

counts = {}
for line in open(tsv, encoding='utf-8'):
    rank, word, n = line.rstrip('\n').split('\t')
    counts[int(rank)] = (word, int(n))
old = list(csv.DictReader(open(TOP, encoding='utf-8-sig')))
extra = [r for r in old if int(r['rank']) > 3000]

out, cum = [], 0
for r in csv.DictReader(open(ART, encoding='utf-8')):
    rank = int(r['rank'])
    word, n = counts[rank]
    assert word == r['word'], (rank, word, r['word'])
    cum += n
    out.append([rank, word, r['pos'], '', r['ko'], round(n / total * 100, 4), round(cum / total * 100, 2), r['level'], '', r['reading']])
top = {r[1] for r in out}
with open(TOP, 'w', encoding='utf-8', newline='') as f:
    w = csv.writer(f, lineterminator='\n')
    w.writerow(HEAD)
    w.writerows(out)
    w.writerows([r[h] for h in HEAD] for r in extra)

vocab = {}
for t in json.load(open('assets/data/vocab/travel_words.json', encoding='utf-8'))['themes']:
    for s in t['sections']:
        for x in s['words']:
            vocab.setdefault(x['tx'].strip(), (x.get('rd', ''), x.get('ko', '')))
for r in extra:
    vocab.setdefault(r['word'], (r['rd'], r['ko']))
lem = collections.Counter()
for e in json.load(open('assets/data/dialogues/L1.json', encoding='utf-8'))['episodes']:
    for t in e['turns']:
        for l in t.get('lemmas', []):
            if l[1] not in top and l[1] not in NAMES and l[1] in vocab:
                lem[l[1]] += 1
words = [{'word': b, 'rd': vocab[b][0], 'ko': vocab[b][1], 'n': n} for b, n in lem.most_common()]
json.dump({'_meta': '회화 레마 중 절벽 단어표(1,500위) 밖이면서 단어장에 있는 것 · tools/freq/build_words_fa.py', 'words': words},
          open(CONV, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
print(len(out), len(extra), len(words))
