#!/usr/bin/python3
"""Gemini 검수 여러 건 동시 전송. 목록 파일 한 줄 = <프롬프트>\t<저장>.
  /usr/bin/python3 tools/gemini_batch.py <목록> [-j 1]   건마다 최대 4번, 줄마다 OK/FAIL 출력. BADMODEL·BLOCKED 면 전부 멈춘다."""
import subprocess, sys, threading, time
from concurrent.futures import ThreadPoolExecutor
jobs = [l.rstrip('\n').split('\t') for l in open(sys.argv[1], encoding='utf-8') if l.strip()]
n = int(sys.argv[sys.argv.index('-j') + 1]) if '-j' in sys.argv else 1
gap = int(sys.argv[sys.argv.index('--gap') + 1]) if '--gap' in sys.argv else 60  # 건 사이 쉬는 초(Google 로봇 확인이 뜨지 않게 천천히)
stop = threading.Event()


def one(j):
    r = ''
    for t in range(1, 5):
        if stop.is_set(): return
        t0 = time.time()
        p = subprocess.run(['/usr/bin/python3', 'tools/gemini_send.py', j[0], j[1]], capture_output=True, text=True)
        r = (p.stdout.strip().splitlines() or [p.stderr.strip()[-120:]])[-1]
        if r.startswith('OK'):
            print(f'OK {j[1]} try={t} {time.time() - t0:.0f}s', flush=True); time.sleep(gap); return
        print(f'  try{t} {j[1].split("/")[-1]}: {r[:90]} {time.time() - t0:.0f}s', flush=True)
        if r.startswith(('BADMODEL', 'BLOCKED')): stop.set(); return
    print(f'FAIL {j[1]} {r[:90]}', flush=True)


with ThreadPoolExecutor(n) as ex: list(ex.map(one, jobs))
