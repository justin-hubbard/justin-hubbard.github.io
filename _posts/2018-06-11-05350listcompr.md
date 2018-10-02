---
layout: post
title: "Unnecessarily Long Python List Comprehension for Codex Crack"
date:   2018-06-11 20:29:18 -0100
tags: code
---

#### This was an easy assignment that I used to teach myself the abilities of python list comprehensions and to find the limits of code readability.

We were given a string of text, a codex of char:integer pairs, and a public key. I had written out separate lines for each part of the list
comprehension, but quickly realized that I could nest all of them in one statement (obviously on one line, which would have been ugly to have to scroll through down below),
so I proceeded to do so. 

This is not a helpful thing to do, but I did successfully explain it to my non-CS roommate at the time, so I think someone learned something at some point.




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