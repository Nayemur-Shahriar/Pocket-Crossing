from pathlib import Path
import math,random,wave,struct
r=Path(__file__).resolve().parents[1]/'assets/audio';rng=random.Random(149)
def save(name,seconds,fn):
 sr=22050;n=int(sr*seconds);samples=[]
 for i in range(n):
  t=i/sr;v=fn(t,rng.uniform(-1,1));fade=min(1,t/.02,(seconds-t)/.02) if name.startswith('ambience') else 1
  samples.append(v*fade)
 scale=.65/max(abs(v) for v in samples) if name.startswith('ambience') else 1
 data=b''.join(struct.pack('<h',int(max(-.85,min(.85,v*scale))*32767)) for v in samples)
 with wave.open(str(r/(name+'.wav')),'wb') as f:f.setparams((1,2,sr,n,'NONE','not compressed'));f.writeframes(data)

def tone(t,f):return math.sin(2*math.pi*f*t)
save('coin',.18,lambda t,n:.35*math.exp(-22*t)*(tone(t,980)+.3*tone(t,1470)))
save('splash',.35,lambda t,n:.45*math.exp(-12*t)*(n*.7+tone(t,140-120*t)*.3))
save('rail_warning',.5,lambda t,n:.25*(tone(t,700)+.3*tone(t,1100))*math.sin(math.pi*min(1,(t%0.25)/.25))**2)
# All loop tones are integer cycles over eight seconds; quiet original synthesis.
save('ambience_village',8,lambda t,n:.025*n+.08*tone(t,1650+0)*max(0,math.sin(2*math.pi*t/2))**16)
save('ambience_city',8,lambda t,n:.07*tone(t,55)*(0.7+.3*tone(t,.25))+.035*n)
save('ambience_river',8,lambda t,n:.1*n*(.65+.3*tone(t,.5))+.035*tone(t,125)*(.6+.4*tone(t,.25)))
save('ambience_night',8,lambda t,n:.018*n+.065*tone(t,2400)*max(0,tone(t,3))**12+.025*tone(t,65))
