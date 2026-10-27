"""Original project-owned synthesis; requires numpy. No third-party samples."""
from pathlib import Path
import numpy as np, wave
p=Path(__file__).resolve().parents[1]/'assets/audio';sr=22050;rng=np.random.default_rng(2114)
def save(name,a,loop=False):
 a=np.asarray(a);a=a/max(1,np.max(np.abs(a))/.80)
 if not loop:a[:64]*=np.linspace(0,1,64);a[-128:]*=np.linspace(1,0,128)
 with wave.open(str(p/(name+'.wav')),'wb') as w:w.setparams((1,2,sr,0,'NONE','not compressed'));w.writeframes((a*32767).astype('<i2').tobytes())
for i,(name,hz,life,metal) in enumerate([('rickshaw',570,.28,.65),('cng',260,.36,.4),('car',145,.4,.20),('van',105,.48,.27),('bus',78,.55,.45),('truck',52,.60,.33),('train',66,.68,.85)]):
 t=np.arange(int(sr*life))/sr;n=rng.normal(0,.35,len(t));smooth=np.convolve(n,np.ones(7+i*3)/(7+i*3),'same')
 a=.45*np.sin(2*np.pi*(hz*t+22*(1-np.exp(-t*20))))*np.exp(-t*(10+i*.4))
 a+=metal*.24*(np.sin(2*np.pi*(hz*3.73)*t)+.5*np.sin(2*np.pi*(hz*5.19)*t))*np.exp(-t*(15-i))
 a+=smooth*np.exp(-t*9)+n*.25*np.exp(-t*90)
 if name in ['rickshaw','train']:a+=.10*np.sin(2*np.pi*1250*t)*np.exp(-np.maximum(t-.07,0)*16)*(t>.07)
 save('impact_'+name,a)
t=np.arange(int(sr*.85))/sr;n=rng.normal(0,.5,len(t));low=np.convolve(n,np.ones(22)/22,'same')
a=.4*n*np.exp(-t*13)*(1-np.exp(-t*130))+.7*low*np.exp(-t*3)
for at,hz in [(.12,380),(.21,290),(.33,470),(.49,240)]:
 u=np.maximum(t-at,0);a+=.11*np.sin(2*np.pi*(hz*u-90*u*u))*np.exp(-u*22)*(t>=at)
save('water_entry',a)
for name,life in [('dog_bark',.48),('dog_catch',.38)]:
 t=np.arange(int(sr*life))/sr;a=np.zeros_like(t)
 for at in ([0,.23] if name=='dog_bark' else [0,.14]):
  u=np.maximum(0,t-at);env=(1-np.exp(-u*160))*np.exp(-u*24)*(t>=at)
  a+=env*(.27*np.sin(2*np.pi*180*u)+.15*np.sin(2*np.pi*430*u)+rng.normal(0,.12,len(t)))
 if name=='dog_catch':a+=.27*np.sin(2*np.pi*90*t)*np.exp(-t*25)
 save(name,a)
n=sr*32;a=np.zeros(n)
for bar,chord in enumerate([(48,55,60),(45,52,57),(53,60,65),(55,62,67)]*2):
 t=np.arange(sr*5)/sr;env=np.sin(np.pi*t/5)**2
 for midi in chord:
  hz=440*2**((midi-69)/12);tone=.035*env*(np.sin(2*np.pi*hz*t)+.22*np.sin(2*np.pi*hz*2*t))
  np.add.at(a,(np.arange(len(t))+bar*4*sr)%n,tone)
for k,midi in enumerate([72,76,79,76,74,72,69,72,77,79,81,79,74,76,79,74,72,79,76,72,69,72,76,74,77,81,79,77,74,72,67,71]):
 t=np.arange(int(sr*1.8))/sr;hz=440*2**((midi-69)/12);env=(1-np.exp(-t*60))*np.exp(-t*3.5)
 np.add.at(a,(np.arange(len(t))+k*sr)%n,.11*env*(np.sin(2*np.pi*hz*t)+.15*np.sin(2*np.pi*hz*3*t)))
save('morning_walk',a,True)
(p/'REFINEMENT_AUDIO_LICENSE.txt').write_text('Original Pocket Crossing synthesis. No recordings, samples or third-party compositions. Morning Walk: 32-second periodic celesta/pad loop. Effects: non-graphic mechanical impacts, water entry/bubbles, dog bark/catch. Source: tools/generate_refinement_audio.py.\n')
