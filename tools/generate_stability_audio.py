"""Original synthesized map compositions and body-scale water entry. No samples."""
from pathlib import Path
import numpy as np,wave
p=Path(__file__).resolve().parents[1]/'assets/audio';sr=22050;rng=np.random.default_rng(161026)
def save(name,a):
 a=a/max(1,np.max(np.abs(a))/.8)
 with wave.open(str(p/(name+'.wav')),'wb') as w:w.setparams((1,2,sr,0,'NONE','not compressed'));w.writeframes((a*32767).astype('<i2').tobytes())
for name,base,beat,flavor in [('village_breeze',60,.5,0),('city_steps',57,.4,1),('river_drift',62,.75,2),('night_rails',48,.6,3)]:
 n=int(sr*beat*64);a=np.zeros(n)
 def add(at,tone):np.add.at(a,(np.arange(len(tone))+int(at*sr))%n,tone)
 for bar,root in enumerate([0,-3,5,7]*2):
  t=np.arange(int(sr*beat*10))/sr;env=np.sin(np.pi*t/(beat*10))**2
  for note in [0,7,12]:
   hz=440*2**((base-12+root+note-69)/12)
   add(bar*beat*8,.045*env*(np.sin(2*np.pi*hz*t)+.12*np.sin(2*np.pi*hz*2*t)))
 for k in range(32):
  midi=base+[0,4,7,12,7,4,2,7][(k+flavor)%8]+[0,-3,5,7][k//8]
  hz=440*2**((midi-69)/12);t=np.arange(int(sr*beat*4))/sr
  env=(1-np.exp(-t*(25 if flavor==2 else 65)))*np.exp(-t*(2 if flavor==2 else 4))
  add(k*beat*2,.13*env*(np.sin(2*np.pi*hz*t)+.18*np.sin(2*np.pi*hz*(2 if flavor==0 else 3)*t)))
 if flavor in [1,3]:
  for k in range(64):
   t=np.arange(int(sr*.13))/sr
   add(k*beat,.024*rng.normal(size=len(t))*np.exp(-t*60)+(.035*np.sin(2*np.pi*65*t)*np.exp(-t*30) if k%4==0 else 0))
 save(name,a)
t=np.arange(int(sr*1.15))/sr;noise=rng.normal(size=len(t))
low=np.convolve(noise,np.ones(70)/70,'same');mid=np.convolve(noise,np.ones(5)/5,'same')
a=.48*np.sin(2*np.pi*(75*t-23*t*t))*np.exp(-t*19)*(1-np.exp(-t*300))
a+=1.4*low*np.exp(-t*3.7)+.32*mid*(1-np.exp(-t*100))*np.exp(-t*5.4)
a+=.20*noise*(1-np.exp(-t*160))*np.exp(-t*22)
for at,hz in [(.11,190),(.19,240),(.27,145),(.39,180),(.52,110)]:
 u=np.maximum(t-at,0);a+=.075*np.sin(2*np.pi*(hz*u-80*u*u))*np.exp(-u*17)*(t>=at)
a[:64]*=np.linspace(0,1,64);a[-1024:]*=np.linspace(1,0,1024);save('water_entry',a)
(p/'STABILITY_AUDIO_LICENSE.txt').write_text('Original Pocket Crossing synthesized compositions: Village Breeze, City Steps, River Drift, Night Rails. Original layered water impact/splash/turbulence. No third-party samples or compositions. Source: tools/generate_stability_audio.py.\n')
# Two short voiced/noisy woofs with downward pitch and resonant harmonics.
t=np.arange(int(sr*.55))/sr;a=np.zeros_like(t)
for start in [0,.27]:
 u=np.maximum(t-start,0);env=(1-np.exp(-u*150))*np.exp(-u*20)*(t>=start)
 phase=2*np.pi*(135*u+30*(1-np.exp(-u*18))/18)
 voiced=sum(np.sin(phase*k)*np.exp(-((k*150-650)/600)**2)/k for k in range(1,13))
 breath=np.convolve(rng.normal(size=len(t)),np.ones(3)/3,'same')
 a+=env*(.7*voiced+.10*breath)
a[:40]*=np.linspace(0,1,40);a[-256:]*=np.linspace(1,0,256);save('dog_bark',a)
