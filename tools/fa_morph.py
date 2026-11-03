"""페르시아어 형태소 분석(일본어식 교착어 토큰) — 절벽 산정(2026-11-03)과 문장 레마(tools/add_lemmas_fa.py)가 같이 쓴다.

analyse(낱말) → 토큰 목록: 동사 = 부정사 + 접두 می-/ب-/ن- + 인칭 어미, 명사 = 어간 + 접사(-م·-ت·-ش·-hā·-e·-i …).
필요: hazm(파이썬 3.12 이하 venv).
"""
import re

from hazm import Lemmatizer
from hazm.utils import words_list

lem = Lemmatizer()
LEX = {w for w, _, _ in words_list()}
TR = str.maketrans({'ي': 'ی', 'ك': 'ک', 'ى': 'ی', 'ە': 'ه', 'ً': None, 'ٌ': None, 'ٍ': None, 'َ': None, 'ُ': None, 'ِ': None, 'ّ': None, 'ْ': None, 'ـ': None, '‏': None, '‎': None})
SPLIT = re.compile(r'[^؀-ۿ‌]+|[،؛؟٫٬۔]')

CLITICS = ['شان', 'تان', 'مان', 'ش', 'ت', 'م']
ENDINGS = ['یم', 'ید', 'ند', 'ین', 'ن', 'م', 'ی', 'د', 'ه']


def known(w):
    return w in LEX


def split_nominal(w):
    """명사·형용사 쪽: 어간 + 접사 토큰들."""
    toks = []
    base = w.replace('ٔ', '')  # ـهٔ 의 함자(에자페)
    if base != w:
        toks.append('-e')
    b = base.rstrip('‌')
    if known(b):
        return [b] + toks
    # 대명 접미사(사전에 없는 꼴일 때만)
    for c in CLITICS:
        for sep in ('‌', ''):
            for glue in ('ا', ''):  # 모음 뒤 ‑ام ‑ات ‑اش
                suf = sep + glue + c
                if b.endswith(suf) and len(b) > len(suf) + 1:
                    stem = b[: -len(suf)]
                    r = split_nominal(stem)
                    if known(r[0]):
                        return r + ['-' + c] + toks
    # 복수 ها(+ 에자페 ی)
    for suf, extra in (('‌های', ['-hā', '-e']), ('های', ['-hā', '-e']), ('‌ها', ['-hā']), ('ها', ['-hā'])):
        if b.endswith(suf) and len(b) > len(suf) + 1:
            stem = b[: -len(suf)]
            if known(stem):
                return [stem] + extra + toks
    # 에자페(‑ه‌ی, 모음 뒤 ی) / 부정관사 ی
    for suf, tag in (('‌ی', '-e'), ('ی', '-i')):
        if b.endswith(suf) and len(b) > 2:
            stem = b[: -len(suf)]
            if known(stem):
                if tag == '-i' and stem[-1] in 'اوه':
                    tag = '-e'
                return [stem, tag] + toks
    l = lem.lemmatize(b)
    if '#' not in l and l != b and known(l):
        return [l] + toks
    return [b] + toks


STANDALONE = {'می': ['می-'], 'نمی': ['ن-', 'می-'], 'هی': ['هی'], 'کن': ['کردن'], 'نکن': ['کردن', 'ن-'], 'بکن': ['کردن', 'ب-']}
STEM_INF = {'باش': 'بودن', 'هست': 'بودن', 'کن': 'کردن'}
COLLOQ_END = [('ین', 'ید', '-ین'), ('ن', 'ند', '-ن'), ('ه', 'د', '-ه')]


SPECIAL = {
    'نیست': ['بودن', 'ن-'], 'نیستم': ['بودن', 'ن-', '-م'], 'نیستی': ['بودن', 'ن-', '-ی'], 'نیستیم': ['بودن', 'ن-', '-یم'], 'نیستید': ['بودن', 'ن-', '-ید'], 'نیستن': ['بودن', 'ن-', '-ن'], 'نیستند': ['بودن', 'ن-', '-ند'],
    'هست': ['بودن'], 'هستم': ['بودن', '-م'], 'هستی': ['بودن', '-ی'], 'هستیم': ['بودن', '-یم'], 'هستید': ['بودن', '-ید'], 'هستن': ['بودن', '-ن'], 'هستند': ['بودن', '-ند'],
    'منو': ['من', 'را'], 'تورو': ['تو', 'را'], 'اونو': ['اون', 'را'], 'اینو': ['این', 'را'], 'مارو': ['ما', 'را'], 'چیو': ['چی', 'را'],
}
for _c in ('م', 'ت', 'ش', 'مون', 'تون', 'شون'):
    SPECIAL['به' + _c] = ['به', '-' + _c]
    SPECIAL['از' + _c] = ['از', '-' + _c]
    SPECIAL['باه' + _c] = ['با', '-' + _c]
COLLOQ_STEM = {'میتون': 'توانستن', 'نمیتون': 'توانستن', 'میخوا': 'خواستن', 'نمیخوا': 'خواستن', 'میگ': 'گفتن', 'نمیگ': 'گفتن', 'میش': 'شدن', 'نمیش': 'شدن', 'میر': 'رفتن', 'نمیر': 'رفتن', 'بر': 'رفتن', 'بیا': 'آمدن', 'میا': 'آمدن', 'نمیا': 'آمدن', 'بگ': 'گفتن', 'بش': 'شدن'}
PAST = {v[:-1]: v for v in ['کردن', 'شدن', 'گفتن', 'رفتن', 'دادن', 'دیدن', 'خوردن', 'زدن', 'گرفتن', 'آمدن', 'بودن', 'داشتن', 'خواستن', 'رسیدن', 'کشتن', 'دانستن', 'توانستن', 'آوردن', 'بردن', 'گذاشتن', 'ماندن', 'نشستن', 'شنیدن', 'پرسیدن', 'فهمیدن', 'کشیدن', 'افتادن', 'خوابیدن', 'نوشتن', 'خریدن']}
PRES = {'کن': 'کردن', 'ش': 'شدن', 'گو': 'گفتن', 'گ': 'گفتن', 'رو': 'رفتن', 'ر': 'رفتن', 'ده': 'دادن', 'د': 'دادن', 'بین': 'دیدن', 'خور': 'خوردن', 'زن': 'زدن', 'گیر': 'گرفتن', 'آی': 'آمدن', 'یا': 'آمدن', 'دار': 'داشتن', 'خواه': 'خواستن', 'خوا': 'خواستن', 'رس': 'رسیدن', 'کش': 'کشتن', 'دان': 'دانستن', 'دون': 'دانستن', 'توان': 'توانستن', 'تون': 'توانستن', 'آر': 'آوردن', 'بر': 'بردن', 'گذار': 'گذاشتن', 'مان': 'ماندن', 'مون': 'ماندن', 'نشین': 'نشستن', 'شنو': 'شنیدن', 'پرس': 'پرسیدن', 'فهم': 'فهمیدن', 'خواب': 'خوابیدن', 'نویس': 'نوشتن', 'خر': 'خریدن'}
NOPREFIX_OK = {'کن', 'دار', 'خواه', 'خوا', 'توان', 'تون', 'دان', 'دون'}
PERS = ['یم', 'ید', 'ین', 'ند', 'ن', 'م', 'ی', 'ه', 'د', '']


def analyse(w):
    if w in STANDALONE:
        return STANDALONE[w]
    if w in SPECIAL:
        return SPECIAL[w]
    # 자주 쓰는 동사 어간 + 인칭 어미(사전이 명사로 읽는 꼴: کردی·کرده·شده·کنه·بده)
    for pre_s, pre_t in (('نمی‌', ['ن-', 'می-']), ('می‌', ['می-']), ('نمی', ['ن-', 'می-']), ('می', ['می-']), ('ب', ['ب-']), ('ن', ['ن-']), ('', [])):
        if not w.startswith(pre_s):
            continue
        rest = w[len(pre_s):]
        for e in PERS:
            st = rest[: len(rest) - len(e)] if e else rest
            if e and not rest.endswith(e):
                continue
            inf = PAST.get(st) if (pre_s in ('', 'ن') ) else None
            inf = inf or (PRES.get(st) if (pre_s or (e and st in NOPREFIX_OK)) else None)
            if inf and not (pre_s == '' and e == '' ):
                return [inf] + pre_t + (['-' + e] if e else [])
    # 입말 동사(반띄어쓰기 없이·입말 어간): میتونم · میخوام · میشه · بریم · بگو
    for stem, inf in COLLOQ_STEM.items():
        for e in PERS:
            if w == stem + e or w == stem + 'و' + e and stem.endswith(('گ', 'ش', 'ر')):
                pre = ['ن-', 'می-'] if stem.startswith('نمی') else ['می-'] if stem.startswith('می') else ['ب-'] if stem.startswith('ب') and inf not in ('رفتن',) or stem == 'بر' else []
                return [inf] + pre + (['-' + e] if e else [])
    for pre in ('نمی', 'می'):
        if w.startswith(pre) and not w.startswith(pre + '‌') and len(w) > len(pre) + 1:
            r = analyse(pre + '‌' + w[len(pre):])
            if r and r[0].endswith('ن') and r[0] != pre + '‌' + w[len(pre):]:
                return r
    l = lem.lemmatize(w)
    if '#' not in l:
        # 입말 인칭 어미(‑ه = ‑د, ‑ن = ‑ند, ‑ین = ‑ید): 문어 꼴로 바꿔 동사로 읽히면 동사로
        for col, lit, tag in COLLOQ_END:
            if w.endswith(col) and len(w) > len(col) + 1:
                l2 = lem.lemmatize(w[: -len(col)] + lit)
                stem = w[: -len(col)].replace('‌', '')
                pres2 = l2.split('#')[1] if '#' in l2 else ''
                if '#' in l2 and (stem.startswith(('می', 'نمی', 'ب', 'ن')) or stem == pres2):
                    toks = analyse(w[: -len(col)] + lit)
                    return [t if t != '-' + lit else tag for t in toks]
    if '#' in l:  # 동사
        past, pres = l.split('#')
        inf = STEM_INF.get(pres) or ((past + 'ن') if past and not past.startswith(pres + 'ید') else w)
        if pres in STEM_INF:
            past = past if past and not past.startswith(pres) else ''
        toks = [inf]
        rest = w.replace('‌', '')
        if rest.startswith('نمی'):
            toks += ['ن-', 'می-']
            rest = rest[3:]
        elif rest.startswith('می'):
            toks.append('می-')
            rest = rest[2:]
        elif rest.startswith('ن') and not inf.startswith('ن'):
            toks.append('ن-')
            rest = rest[1:]
        elif rest.startswith('ب') and not inf.startswith('ب'):
            toks.append('ب-')
            rest = rest[1:]
        for stem in sorted({past, pres}, key=len, reverse=True):
            if stem and rest.startswith(stem):
                end = rest[len(stem):]
                if end in ENDINGS:
                    toks.append('-' + end)
                break
        return toks
    return split_nominal(w)




def words(line):
    """문장 → 낱말(페르시아 문자만)."""
    return [t.strip('‌') for t in SPLIT.split(line.translate(TR)) if t.strip('‌')]
