"""Original Pocket Crossing synthesized scores. No external samples or melodies."""
from pathlib import Path
import numpy as np,wave,json,re
p=Path(__file__).resolve().parents[1];rate=22050;metadata=[]
tracks=[('village_breeze','village',108,60,'Warm plucked major pentatonic'),('city_steps','city',124,62,'Syncopated keyboard and bouncy bass'),('river_drift','river',112,65,'Flowing mallets and offbeat percussion'),('night_rails','railway',120,57,'Electronic pluck and playful minor pulse')]
for name,profile,bpm,key,style in tracks:
 for challenge in [False,True]:
  beat=60/bpm;n=round(64*beat*rate);mix=np.zeros(n);rng=np.random.default_rng(key)
  def add(sig,at):np.add.at(mix,(np.arange(len(sig))+round(at*rate))%n,sig)
  def tone(note,at,duration,amp,kind='pluck'):
   t=np.arange(round(duration*rate))/rate;hz=440*2**((note-69)/12);attack=np.minimum(t/.006,1)
   if kind=='bass':body=np.sin(2*np.pi*hz*t)+.18*np.sin(4*np.pi*hz*t);env=attack*np.exp(-t*7/duration)
   elif kind=='pad':body=np.sin(2*np.pi*hz*t)+.16*np.sin(4*np.pi*hz*t);env=np.sin(np.pi*np.minimum(t/duration,1))**2
   elif kind=='mallet':body=np.sin(2*np.pi*hz*t)+.3*np.sin(4*np.pi*hz*t)*np.exp(-t*13);env=attack*np.exp(-t*7)
   else:body=np.sin(2*np.pi*hz*t)+.22*np.sin(4*np.pi*hz*t)+.08*np.sin(6*np.pi*hz*t);env=attack*np.exp(-t*8)
   add(body*env*amp,at)
  def drum(at,kind,amp):
   t=np.arange(round((.22 if kind=='kick' else .11)*rate))/rate
   if kind=='kick':sig=np.sin(2*np.pi*(50*t+60*(1-np.exp(-t*22))/22))*np.exp(-t*24)
   else:
    noise=rng.normal(0,.35,len(t));noise=np.diff(noise,prepend=noise[0]);sig=noise*np.exp(-t*(80 if kind=='hat' else 36))
    if kind=='snare':sig+=.3*np.sin(2*np.pi*190*t)*np.exp(-t*40)
   add(sig*np.minimum(t/.002,1)*amp,at)
  progression=[0,5,9,7] if profile!='railway' else [0,8,5,7]
  scale=[0,2,4,7,9,12,14,16] if profile!='railway' else [0,2,3,7,10,12,14,15]
  motifs=[[0,2,4,3,2,1],[2,3,5,4,2,0],[0,1,3,4,5,3],[4,3,2,1,0,2]]
  for bar in range(16):
   chord=key+progression[(bar//2)%4];third=3 if profile=='railway' and (bar//2)%4==0 else 4
   for step in [0,2]:
    tone(chord-24,(bar*4+step)*beat,beat*.85,.30,'bass');tone(chord-17,(bar*4+step+.75)*beat,beat*.45,.16,'bass')
   for offset in [0,third,7]:tone(chord+offset,bar*4*beat,beat*3.6,.025,'pad')
   rhythm=[0,.75,1.5,2,2.75,3.5] if profile!='river' else [0,.5,1.25,2,2.5,3.25]
   for j,step in enumerate(rhythm):
    note=key+12+scale[(motifs[(bar//4)%4][j]+(1 if bar%4==3 else 0))%len(scale)]
    tone(note,(bar*4+step)*beat,beat*.7,.16 if profile!='railway' else .13,'mallet' if profile in ['river','village'] else 'pluck')
   for step in [0,2]:drum((bar*4+step)*beat,'kick',.30)
   for step in [1,3]:drum((bar*4+step)*beat,'snare',.13)
   for step in np.arange(.5,4,.5 if challenge or profile in ['city','railway'] else 1):drum((bar*4+step)*beat,'hat',.07)
   if profile=='village':
    for step in [.5,1.5,2.5,3.5]:tone(chord+7,(bar*4+step)*beat,beat*.3,.045,'pluck')
   if profile=='river':
    for step in [.75,2.75]:tone(chord+19,(bar*4+step)*beat,beat*.4,.055,'mallet')
   if challenge:
    drum((bar*4+2.75)*beat,'kick',.09)
    for j,step in enumerate([.25,1.25,2.25,3.25]):tone(chord+[12,19,16,19][j],(bar*4+step)*beat,beat*.35,.055)
   if bar%4==3:drum((bar*4+3.75)*beat,'snare',.06)
  # Gentle transient rounding, equal RMS across maps and challenge variants.
  mix=np.tanh(mix*1.8)/1.8
  mix-=mix.mean()
  mix*=10**(-21/20)/np.sqrt(np.mean(mix**2))
  assert max(abs(mix))<.95, 'Unexpected peak: review arrangement'
  # Tiny endpoint correction preserves the complete beat grid and wrapped tails.
  width=44
  mix[-width:]+=np.linspace(0,mix[0]-mix[-1],width)
  pcm=np.round(mix*32767).astype('<i2');filename=name+('_challenge' if challenge else '')+'.wav'
  with wave.open(str(p/'assets/audio'/filename),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(pcm.tobytes())
  metadata.append(dict(file=filename,bpm=bpm,bars=16,seconds=len(pcm)/rate,style=style,challenge=challenge,peak=float(max(abs(mix))),rms=float(np.sqrt(np.mean(mix**2))),loop_boundary_delta=float(abs(mix[0]-mix[-1]))))

(p/'assets/audio/morning_walk.wav').write_bytes((p/'assets/audio/village_breeze.wav').read_bytes())
(p/'docs/MUSIC_PASS_ANALYSIS.json').write_text(json.dumps(metadata,indent=2)+'\n')
