#!/usr/bin/env python3
"""편 JSON → Gemini 검수 프롬프트 파일 + 목록(list.tsv). python3 tools/gemini_prompts_fa.py <출력폴더> <편.json>...
목록은 gemini_batch.py -j 1 --gap 60 으로 돌린다. Grok 재작성이 끝난 편만 넣는다."""
import json, re, sys
from pathlib import Path
R = Path(__file__).resolve().parents[1]
T = re.search(r'```\n(.*?)\n```', (R / 'tools/prompts/review_gemini_fa.md').read_text(encoding='utf-8'), re.S).group(1)
out = Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
rows = []
for p in sys.argv[2:]:
    e = json.load(open(p, encoding='utf-8'))
    lines = '\n'.join(f"{t['num']} {t['speaker']}: {t['tl_col']} / {t['tl']} / {t['rd']} / {t['ko']}" for t in e['turns'])
    roles = ', '.join(f'{k}={v}' for k, v in e['speakers'].items())
    f = out / f"{e['id']}.txt"
    f.write_text(T.replace('{code}', e['id']).replace('{roles}', roles).replace('{scene}', e['scene']).replace('{lines}', lines), encoding='utf-8')
    rows.append(f"{f}\t{R}/data/review/dialogues/{e['id']}_gemini.md")
(out / 'list.tsv').write_text('\n'.join(rows) + '\n', encoding='utf-8')
print(len(rows), '건')
