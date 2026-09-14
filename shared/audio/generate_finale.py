"""Original nursery-bell cues and short accelerating steam-train departure."""
from pathlib import Path
import math, random, struct, wave
root=Path(__file__).parent
rate=22050
def save(name, samples):
    with wave.open(str(root/name),'wb') as f:
        f.setparams((1,2,rate,0,'NONE','not compressed'))
        f.writeframes(b''.join(struct.pack('<h',int(max(-.9,min(.9,v))*32767)) for v in samples))
for index,freq in enumerate([392,523.25,329.63,440]):
    samples=[]
    for i in range(int(rate*.9)):
        t=i/rate
        tone=sum(math.sin(t*math.tau*freq*o)*a for o,a in [(1,.32),(2.76,.1),(4.07,.045)])
        samples.append(tone*min(1,t/.005)*math.exp(-t*5))
    save(f'memory_{index}.wav',samples)
rng=random.Random(1863)
samples=[]
low=0
for i in range(rate*7):
    t=i/rate
    low+=(rng.uniform(-1,1)-low)*.16
    phase=t*2+t*t*.24
    chuff=max(0,math.sin(math.tau*phase))**7
    sound=low*(.2+.75*chuff)+math.sin(math.tau*46*t)*.055
    if t<1.3:
        sound+=math.sin(math.tau*580*t)*.09*math.sin(math.pi*t/1.3)**2
    samples.append(sound*min(1,t/.2)*min(1,(7-t)/.7))
save('train_departure.wav',samples)
