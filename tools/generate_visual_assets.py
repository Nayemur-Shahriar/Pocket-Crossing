from pathlib import Path
import random
r=Path(__file__).resolve().parents[1] / 'assets' / 'art'
def svg(name,w,h,body):
 (r/name).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'+body+'</svg>\n')
svg('car.svg',116,58,'''
<defs><linearGradient id="paint" x2="0" y2="1"><stop stop-color="#ffffff"/><stop offset="1" stop-color="#b6c3ca"/></linearGradient><linearGradient id="glass" x2="1" y2="1"><stop stop-color="#789baa"/><stop offset="1" stop-color="#253a48"/></linearGradient></defs>
<rect x="5" y="12" width="106" height="43" rx="15" fill="#101e28" opacity=".28"/>
<path d="M21 2h19v11H21zM77 2h19v11H77zM21 43h19v11H21zM77 43h19v11H77z" fill="#1c2933"/>
<rect x="4" y="6" width="106" height="43" rx="14" fill="#64717b"/>
<rect x="4" y="5" width="106" height="40" rx="14" fill="url(#paint)"/>
<path d="M16 9h72q15 0 17 12M14 41h73" fill="none" stroke="#fff" opacity=".6" stroke-width="2"/>
<path d="m31 10 42 0 11 9v13l-11 9H31l-7-9V19Z" fill="#20333e"/>
<path d="M36 11h31v29H36z" fill="#edf1f2"/>
<path d="m70 12 10 8v11l-10 8Z" fill="url(#glass)"/>
<path d="m32 13-5 7v11l5 7Z" fill="url(#glass)"/>
<path d="m73 16 4 5v8" fill="none" stroke="#cce6ec" opacity=".7"/>
<path d="M40 14h23M40 37h23M89 15h10M89 35h10" stroke="#fff" stroke-width="2" opacity=".65"/>
<path d="M50 8h7M50 43h7" stroke="#71808b" stroke-width="2"/>
<rect x="104" y="12" width="5" height="9" rx="2" fill="#fff3cc"/><rect x="104" y="30" width="5" height="9" rx="2" fill="#fff3cc"/>
<path d="M6 13v7M6 31v7" stroke="#e07569" stroke-width="3"/><path d="M110 23v6" stroke="#344853" stroke-width="2"/>
''')
svg('van.svg',140,58,'''
<defs><linearGradient id="body" x2="0" y2="1"><stop stop-color="#fff"/><stop offset="1" stop-color="#b6c1c6"/></linearGradient><linearGradient id="glass" x2="1" y2="1"><stop stop-color="#94b6c5"/><stop offset="1" stop-color="#304854"/></linearGradient></defs>
<rect x="6" y="12" width="130" height="43" rx="8" fill="#10212c" opacity=".3"/>
<path d="M20 2h20v12H20zM108 2h17v12h-17zM20 42h20v12H20zM108 42h17v12h-17z" fill="#1e2c36"/>
<rect x="4" y="6" width="132" height="43" rx="7" fill="#6d7d86"/>
<rect x="4" y="5" width="87" height="39" rx="5" fill="url(#body)"/>
<path d="M96 7h26q13 0 13 13v13q0 11-13 11H96Z" fill="url(#body)"/>
<path d="M93 11v29" stroke="#334751" stroke-width="4"/>
<path d="m110 10 11 4v23l-11 4Z" fill="url(#glass)"/><path d="m113 14 5 3v15" fill="none" stroke="#cfe5ea" opacity=".6"/>
<rect x="98" y="13" width="10" height="24" rx="2" fill="#ecf1f1"/>
<path d="M13 11v27M24 11v27M35 11v27M46 11v27M57 11v27M68 11v27M79 11v27" stroke="#889da7" opacity=".26"/>
<path d="M11 9h72M11 40h72" stroke="#fff" stroke-width="2" opacity=".8"/>
<rect x="35" y="17" width="26" height="16" rx="3" fill="#fff" opacity=".75"/>
<path d="m40 25 6 4 10-9" stroke="#7b9095" fill="none" stroke-width="2"/>
<rect x="130" y="11" width="5" height="9" rx="2" fill="#fff2c4"/><rect x="130" y="31" width="5" height="9" rx="2" fill="#fff2c4"/>
<path d="M5 13v7M5 31v7" stroke="#e37e70" stroke-width="3"/>
''')
svg('courier.svg',52,60,'''
<defs><linearGradient id="jacket" x2="0" y2="1"><stop stop-color="#ecb64c"/><stop offset="1" stop-color="#c88835"/></linearGradient><linearGradient id="cap" x2="0" y2="1"><stop stop-color="#ffdc82"/><stop offset="1" stop-color="#e7ae40"/></linearGradient></defs>
<path d="M14 47h10v10H13zM29 47h10l1 10H29z" fill="#203941"/>
<path d="M14 54h10M30 54h9" stroke="#6a8588" stroke-width="2"/>
<rect x="8" y="25" width="36" height="28" rx="12" fill="#785338"/>
<rect x="7" y="24" width="38" height="25" rx="11" fill="url(#jacket)"/>
<path d="M11 32v12M41 32v12" stroke="#f6d17c" stroke-width="4" stroke-linecap="round"/>
<rect x="16" y="28" width="21" height="22" rx="6" fill="#254a4c"/>
<rect x="18" y="29" width="17" height="17" rx="4" fill="#507876"/>
<path d="M21 31v-4h10v4M19 39h15" fill="none" stroke="#a7c2ad" stroke-width="2"/>
<rect x="24" y="36" width="5" height="3" rx="1" fill="#f5d68a"/>
<ellipse cx="26" cy="20" rx="16" ry="16" fill="#c28d5b"/>
<ellipse cx="26" cy="19" rx="15" ry="15" fill="#efc594"/>
<path d="M10 20v-4C10-3 42-3 42 16v4Z" fill="url(#cap)"/>
<path d="M13 12q11-10 23-2" fill="none" stroke="#ffecb2" stroke-width="2.5" stroke-linecap="round"/>
<path d="M10 17h32v5H10z" fill="#bc8530"/>
<path d="M10 17h33q3 0 3 4H11Z" fill="#f3cb69"/>
<path d="M15 24h9M29 24h8" stroke="#344b4e" stroke-width="2" stroke-linecap="round"/>
<circle cx="20" cy="25" r="1.4" fill="#243840"/><circle cx="32" cy="25" r="1.4" fill="#243840"/>
<path d="M24 30h5" stroke="#a66f4e" stroke-width="1.6" stroke-linecap="round"/>
''')
svg('tree.svg',100,100,'''
<ellipse cx="55" cy="70" rx="33" ry="21" fill="#183e35" opacity=".18"/>
<path d="M46 57h9v28h-9z" fill="#847456"/><path d="m50 67-15-18m16 13 17-18" stroke="#847456" stroke-width="5"/>
<path d="M17 53Q8 33 29 22 35 1 57 10 81 6 87 30 99 48 79 65 59 80 40 67 21 75 17 53Z" fill="#326758"/>
<path d="M17 43Q15 26 32 22 38 3 58 13 78 10 83 29 90 45 73 55 51 67 37 54 21 60 17 43Z" fill="#4c8668"/>
<path d="M24 32Q29 19 40 23 42 12 57 17 68 15 73 29 64 41 48 37 35 45 24 32Z" fill="#77a17b"/>
<path d="M32 29q8-9 17-8M61 22l5 3" stroke="#a4bf8b" stroke-width="3" fill="none" stroke-linecap="round"/>
<path d="m65 48 8-4M29 46l5 3" stroke="#94b186" stroke-width="2" opacity=".7"/>
''')
rng=random.Random(24)
dots=''.join(f'<rect x="{rng.randrange(64)}" y="{rng.randrange(64)}" width="1" height="1" fill="#b0bdbe" opacity=".09"/>' for _ in range(35))
svg('asphalt.svg',64,64,'<rect width="64" height="64" fill="#34434b"/>'+dots)
svg('pavement.svg',128,64,'''
<rect width="128" height="64" fill="#c8cebF"/>
<path d="M0 0h128v32H0Z" fill="#d7d7c4"/><path d="M0 33h128v31H0Z" fill="#d0d2bf"/>
<path d="M0 0h128M0 32h128M32 0v32M96 0v32M64 32v32M0 32v32" stroke="#a8b5a7"/>
<path d="M1 2h29M34 2h60M98 2h28M2 34h60M66 34h60" stroke="#eef0d9" opacity=".55"/>
''')
svg('grass.svg',64,64,'''
<rect width="64" height="64" fill="#9ab991"/>
<path d="m8 15 2-4 2 4m31 20 2-4 3 4M23 53l2-3 2 3" fill="none" stroke="#709b79" opacity=".4"/>
<path d="M30 9h3M53 52h4M8 39h3" stroke="#c5d2a4" opacity=".5"/>
''')
