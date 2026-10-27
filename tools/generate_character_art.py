"""Original vector character art. All assets share the same 52x60 canvas only."""
from pathlib import Path
p=Path(__file__).resolve().parents[1]/'assets/art'
specs=[('courier','#c98c60','#392d29','#edbc56','#35526a','boy'),('courier_mint','#edbd94','#46332c','#68bca8','#3e5672','girl'),('courier_coral','#8b573d','#282526','#da8266','#30454c','man'),('courier_violet','#b87753','#332a2a','#9f87c5','#343b59','woman'),('courier_elder_man','#c08a68','#c9c7be','#71949c','#4b5059','older_man'),('courier_elder_woman','#a56b4f','#d3d0c6','#c28c99','#4a6269','older_woman')]
for name,skin,hair,shirt,pants,kind in specs:
 young=kind in ['boy','girl'];female=kind in ['girl','woman','older_woman'];old=kind.startswith('older')
 head_y=17 if young else 12;head_r=8.6 if young else 8
 shoulder=27 if young else 23;hip=43 if young else 41
 s=[f'<svg xmlns="http://www.w3.org/2000/svg" width="52" height="60" viewBox="0 0 52 60">',f'<defs><linearGradient id="cloth" x2="0.4" y2="1"><stop stop-color="{shirt}"/><stop offset="1" stop-color="{shirt}" stop-opacity=".78"/></linearGradient></defs>']
 # Separate trousers, shoes, sleeves and hands; posture is visual only.
 s += [f'<path d="M17 {hip-2}h18l-1 14h-7l-1-11-1 11h-8Z" fill="{pants}" stroke="#243b42" stroke-width="1.2"/>','<path d="M17 52h8v5H14q-1-3 3-5ZM28 52h6q5 1 5 5H28Z" fill="#23373e"/>','<path d="M15 56h9m5 0h9" stroke="#aec3bf" stroke-width="1.2"/>']
 if female and not young:s += [f'<path d="M17 33h18l4 13q-13 4-26 0Z" fill="{shirt}" stroke="#3d4c57" stroke-width="1.2"/>']
 if female:s += [f'<path d="M17 {head_y-3}q-3 12-1 18l5-3h10l5 3q3-14-3-20Z" fill="{hair}"/>']
 s += [f'<path d="M17 {shoulder}q-5 1-6 8l-1 10 5 1 4-14m16-5q5 2 6 8l1 10-5 1-4-14" fill="{shirt}" stroke="#394a4d" stroke-width="1.1"/>',f'<ellipse cx="12.7" cy="45" rx="3.4" ry="3.7" fill="{skin}"/><ellipse cx="39.3" cy="45" rx="3.4" ry="3.7" fill="{skin}"/>',f'<path d="M18 {shoulder}q8-5 16 0l2 {hip-shoulder}q-10 4-20 0Z" fill="url(#cloth)" stroke="#3b4e52" stroke-width="1.2"/>',f'<path d="M22 {shoulder-5}h8v7q-4 4-8 0Z" fill="{skin}"/>']
 if young:s += [f'<path d="M18 {shoulder+6}h16m-16 4h16" stroke="#fff1cf" stroke-width="2.3" opacity=".8"/>']
 elif old:s += [f'<path d="M18 {shoulder}l8 6 8-6-2 19H20Z" fill="#e1d9bd"/>',f'<path d="M19 {shoulder+1}l7 7 7-7v20H19Z" fill="{shirt}"/>',f'<path d="M26 {shoulder+8}v14" stroke="#334851" stroke-width="1"/>','<circle cx="27" cy="37" r=".8" fill="#f1dcad"/>']
 else:s += [f'<path d="M22 {shoulder}l4 4 4-4m-4 5v12" fill="none" stroke="#eee1cd" stroke-width="1.3"/>',f'<path d="M29 {shoulder+8}h4v5h-4Z" fill="#ffffff" opacity=".18"/>']
 s += [f'<ellipse cx="17.9" cy="{head_y+2}" rx="2" ry="3" fill="{skin}"/><ellipse cx="34.1" cy="{head_y+2}" rx="2" ry="3" fill="{skin}"/>',f'<ellipse cx="26" cy="{head_y}" rx="{head_r}" ry="{head_r+1.8}" fill="{skin}" stroke="#695448" stroke-width=".7"/>']
 if kind=='older_man':s += [f'<path d="M18 12q-2-10 8-10t8 10l-3-7q-5-3-10 1Z" fill="{hair}"/>','<path d="M21 17q5 4 10 0l-2 4h-6Z" fill="#d2c9b9"/>']
 else:s += [f'<path d="M17 {head_y+1}q-2-12 9-12t9 12l-4-7q-6 5-12 1Z" fill="{hair}"/>',f'<path d="M20 {head_y-6}q6-5 11-1" fill="none" stroke="#fff4df" stroke-opacity=".25" stroke-width="1.3"/>']
 if kind=='girl':s += [f'<circle cx="16" cy="{head_y+2}" r="4" fill="{hair}"/><circle cx="36" cy="{head_y+2}" r="4" fill="{hair}"/>',f'<path d="M14 {head_y+1}h4m16 0h4" stroke="#e7b56b" stroke-width="2"/>']
 if kind=='older_woman':s += ['<circle cx="26" cy="2.8" r="3" fill="#c9c7bc"/>']
 s += [f'<path d="M21 {head_y}h3m4 0h3" stroke="#3c3330" stroke-width="1" stroke-linecap="round"/>',f'<circle cx="22.5" cy="{head_y+2}" r="1.1" fill="#20383d"/><circle cx="29.5" cy="{head_y+2}" r="1.1" fill="#20383d"/>',f'<path d="M26 {head_y+3}l-1 2h2m-4 2q3 2 6 0" fill="none" stroke="#794d3e" stroke-width=".8" stroke-linecap="round"/>']
 if old:s += [f'<path d="M19 {head_y+4}l2 1m10 0 2-1m-10-8h6" stroke="#806759" stroke-width=".6"/>',f'<g fill="none" stroke="#44595d" stroke-width=".8"><rect x="19.5" y="{head_y+.3}" width="6" height="4" rx="1.5"/><rect x="27" y="{head_y+.3}" width="6" height="4" rx="1.5"/><path d="M25.5 {head_y+2}H27"/></g>']
 s+=['</svg>'];(p/(name+'.svg')).write_text('\n'.join(s))
