"""Original static SVG source for the focused post-M14 art pass; run from any cwd.
The M12 generator lived outside the shipped project. This generator owns only
these eight new/revised assets; it does not rewrite other vehicles or game data.
"""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'assets'
def svg(path,w,h,body):
 p=ROOT/path;p.parent.mkdir(parents=True,exist_ok=True)
 p.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>\n')
svg('vehicles/rickshaw.svg',116,58,'''
<ellipse cx="55" cy="34" rx="53" ry="22" fill="#162d38" opacity=".18"/>
<!-- Paired rear wheels, single exposed bicycle front wheel. -->
<g fill="#203843" stroke="#a7b9b5" stroke-width="1.5"><rect x="15" y="2" width="20" height="8" rx="4"/><rect x="15" y="48" width="20" height="8" rx="4"/><ellipse cx="100" cy="29" rx="13" ry="6"/></g>
<g fill="none" stroke="#243e48" stroke-width="3" stroke-linejoin="round"><path d="M24 6V51M26 29H99M56 14L80 29L56 44M68 29L79 20L94 29M91 20V38"/></g>
<path d="M8 11Q5 29 8 47H51L63 40V18L51 11Z" fill="#bd4d61" stroke="#263c46" stroke-width="2"/>
<path d="M12 15H49V43H12Z" fill="#f1c266"/><path d="M15 18H36V40H15Z" fill="#377c81"/>
<!-- Rounded scalloped passenger hood, open seat and colorful painted panel. -->
<path d="M8 13Q21 1 43 10L42 48Q20 54 8 45Z" fill="#23867c" stroke="#203b44" stroke-width="2"/>
<path d="M13 14Q25 7 37 13M13 22Q25 15 37 21M13 30Q25 23 37 29M13 38Q25 31 37 37" fill="none" stroke="#edbf5a" stroke-width="2"/>
<path d="M38 11Q48 12 48 17V41Q48 46 38 47" fill="none" stroke="#f7d97f" stroke-width="3"/>
<path d="M49 17H57V41H49Z" fill="#8c3e56"/><path d="M53 21V37" stroke="#f3a284" stroke-width="2"/>
<path d="M11 46L38 48" stroke="#f2ca6e" stroke-width="3"/><circle cx="21" cy="43" r="2" fill="#ec816c"/>
<!-- Rider shoulders, head, hands at the handlebar, pedal crank. -->
<path d="M68 20L74 15M68 38L75 44" stroke="#9b7158" stroke-width="3"/>
<ellipse cx="71" cy="29" rx="9" ry="7" fill="#40709a" stroke="#263d47" stroke-width="1.5"/>
<circle cx="80" cy="29" r="4.5" fill="#e5b480"/>
<path d="M77 22L89 20M77 36L89 38" stroke="#deb180" stroke-width="2.5"/>
<path d="M97 26L108 29L97 32" fill="none" stroke="#d2d9c6" stroke-width="1"/>
<circle cx="66" cy="29" r="3" fill="#e8c788"/>
''')
svg('vehicles/cng.svg',116,58,'''
<ellipse cx="56" cy="34" rx="53" ry="22" fill="#162d38" opacity=".2"/>
<g fill="#20323c" stroke="#93a8a4" stroke-width="1"><rect x="18" y="1" width="19" height="9" rx="4"/><rect x="18" y="48" width="19" height="9" rx="4"/><rect x="98" y="24" width="17" height="10" rx="4"/></g>
<!-- Wide passenger shell tapers to one front wheel and compact scooter nose. -->
<path d="M8 9Q3 29 8 49H60Q78 47 96 38L108 33V25L96 20Q78 11 60 9Z" fill="#328960" stroke="#203b40" stroke-width="2"/>
<path d="M10 10H57L69 14V44L57 48H10Q4 29 10 10Z" fill="#164f43"/>
<path d="M15 15H51L58 18V40L51 43H15Z" fill="#263f43"/>
<!-- Cream canvas roof, dark open doors and warm rear bench. -->
<path d="M12 14Q8 29 12 44H44Q52 29 44 14Z" fill="#ded2a1" stroke="#a89b78" stroke-width="1.5"/>
<path d="M15 17Q11 29 15 41M19 16H40M19 42H40" fill="none" stroke="#fff0c3" stroke-width="2"/>
<path d="M47 15H59V23H47ZM47 35H59V43H47Z" fill="#112f35"/>
<path d="M48 24H57V34H48Z" fill="#ce7853"/>
<path d="M63 14L83 21V37L63 44Z" fill="#719fac" stroke="#203b40" stroke-width="2"/>
<path d="M67 18L78 23V33" stroke="#c0e0dc" stroke-width="2" fill="none"/>
<path d="M86 23L99 26V32L86 35Z" fill="#53b576"/>
<path d="M88 28H97" stroke="#20674f" stroke-width="2"/>
<ellipse cx="103" cy="29" rx="3" ry="4" fill="#fff0b1"/>
<path d="M63 13L65 8M63 45L65 50" stroke="#203b40" stroke-width="2"/>
<path d="M9 15V22M9 36V43" stroke="#fa816c" stroke-width="3"/>
<path d="M15 48H56L87 38" stroke="#efc568" stroke-width="2" fill="none"/>
''')
# Each facade fits the existing destination garden margin. All use the same
# bright finish crest and open arch above the unchanged highlighted goal pad.
common='<circle cx="80" cy="18" r="9" fill="#f8dc89" stroke="#35554d" stroke-width="2"/><path d="M75 18L79 22L86 14" fill="none" stroke="#35554d" stroke-width="2.5"/>'
styles={
'park':'''<path d="M15 62V32Q80 -4 145 32V62" fill="none" stroke="#476c54" stroke-width="8"/><path d="M24 62V33Q80 5 136 33V62" fill="none" stroke="#d6c389" stroke-width="3"/><g fill="#58966c"><circle cx="20" cy="37" r="12"/><circle cx="13" cy="51" r="10"/><circle cx="140" cy="37" r="12"/><circle cx="147" cy="51" r="10"/></g><g fill="#f0aa82"><circle cx="15" cy="37" r="3"/><circle cx="145" cy="46" r="3"/></g>''',
'plaza':'''<path d="M8 62V13H152V62H112V33H48V62Z" fill="#819794" stroke="#344f58" stroke-width="3"/><path d="M4 10H156V22H4Z" fill="#ccba8b"/><path d="M17 29H34V42H17ZM126 29H143V42H126Z" fill="#aad1d8" stroke="#405a63" stroke-width="2"/><path d="M43 62V31H117V62" fill="none" stroke="#e5d6b2" stroke-width="5"/>''',
'courtyard':'''<path d="M14 61V23H146V61H107V34H53V61Z" fill="#c79a69" stroke="#635951" stroke-width="2"/><path d="M3 27L34 5H126L157 27Z" fill="#ac6155" stroke="#624e47" stroke-width="2"/><path d="M26 19H134" stroke="#dd9a75" stroke-width="3"/><path d="M24 36H38V53H24ZM122 36H136V53H122Z" fill="#346e69"/><path d="M10 63H150" stroke="#e3bd84" stroke-width="5"/>''',
'station':'''<path d="M8 60H152" stroke="#a3b5b2" stroke-width="7"/><path d="M18 58V26M142 58V26" stroke="#66838d" stroke-width="8"/><path d="M4 25L26 6H134L156 25Z" fill="#5d8795" stroke="#2b505b" stroke-width="2"/><path d="M23 35H49V51H23ZM111 35H137V51H111Z" fill="#d7be82" stroke="#3d5e65" stroke-width="2"/><path d="M29 42H43M117 42H131" stroke="#4b6971" stroke-width="2"/>''',
'landing':'''<path d="M8 63H152M18 56H142M28 49H132" stroke="#ae926a" stroke-width="6"/><path d="M25 49V23M135 49V23" stroke="#755f49" stroke-width="6"/><path d="M11 24L36 6H124L149 24Z" fill="#bfa15e" stroke="#6a644a" stroke-width="2"/><path d="M34 29H126" stroke="#dec694" stroke-width="3"/><path d="M2 66Q20 60 38 66M122 66Q140 60 158 66" fill="none" stroke="#61b9bd" stroke-width="3"/>''',
'rest_stop':'''<path d="M19 63V27M141 63V27" stroke="#667c79" stroke-width="7"/><path d="M5 27V10H155V27Z" fill="#477b73" stroke="#294b50" stroke-width="2"/><path d="M10 14H65M95 14H150" stroke="#a7c7a2" stroke-width="2"/><path d="M8 59H40M120 59H152" stroke="#bba579" stroke-width="5"/><path d="M13 61V67M35 61V67M125 61V67M147 61V67" stroke="#6d755f" stroke-width="3"/>'''
}
for name,body in styles.items():svg('environment/destinations/'+name+'.svg',160,68,body+common)
