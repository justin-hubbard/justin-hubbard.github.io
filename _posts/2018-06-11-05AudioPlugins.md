---
layout: post
title: "Audio Plugins in C++"
date:   2018-06-11 20:29:18 -0100
tags: personal
---

#### Delay, chorus, and flanger audio effects written in C++ using the JUCE framework

I've played musical instruments all my life, and I've been in love with digital music production
goin back to the days of pirating early versions of FL Studio back in highschool. Once I began studying
software development, I became hungry to understand how the plugins I use every day are made. I joined an
online course on the JUCE framework which gave me the knowledge to build these surprisingly great-sounding
plugins, and will be helpful for projects to come in the future.




{% highlight python %}
import math
import gmpy

def main():
    ciph = {'A': 1, 'E': 2, 'G': 3, 'I': 4, 'O': 5,
    		'R': 6, 'T': 7, 'X': 8, '!': 9, '0': 0}
    ncrpt = "ITG!AAEXEX IRRG!IGRXI OIXGEREAGO"
    e = 49
    n = 10539750919

    message = [{v:k for k,v in ciph.items()}[int(x)] 
	    		for x in ''.join([str(num) 
	    		for num in [int(pow(x,PKey(e, n),n)) 
	    		for x in [int(''.join(list(map(str, st)))) 
	    		for st in [[ciph[x] for x in xs] 
	    		for xs in ncrpt.split()]]]])]
    print(message)

def PKey(e, n):
    for i in range(math.floor(math.sqrt(n)), 0, -2):
        if n % i == 0:
            p = i
            break
    return gmpy.invert(e, (p-1)*(math.floor(n/p)-1))

if __name__ == '__main__':
    main()
{% endhighlight %}

This was a simple assignment meant to introduce us to codex concepts, but what it really introduced me to how fun Python is. I'd used it plenty, but
hadn't explored the "Pythonic" ways of doing things, so taking it to the extreme like I did here was a goofy way to get more familiar with the power
of list comprehensions.