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


## Delay
----

Delay effects essentially take an audio input and loop a portion of it back, creating an echo-like sound.
<div style="width: 100%; margin: auto auto auto auto;">
    <div class="ytcontainer">
        <iframe class="ytframe" src="https://www.youtube.com/embed/avp0D5dOahk"
         frameborder="0" allowfullscreen></iframe>
    </div>
</div>
 

The core concept behind implementing this effect in software is the use of a circular buffer. Basically, the functionality all runs through a function
called processBlock() which provides the AudioBuffer and MidiBuffer for manipulation. This allows the function do iterate over all the samples currently inside the AudioBuffer to change it however you'd like.

The simple explanation for how this delay works is that audio at a point in time is copied and added to the input signal at another point later in time as specified by the user controlling the plugin.


Here's the processBlock() function and an overview of how it works:
{% highlight cpp %}
void DelayAudioProcessor::processBlock (AudioBuffer<float>& buffer, MidiBuffer& midiMessages)
{
    ScopedNoDenormals noDenormals;
    auto totalNumInputChannels  = getTotalNumInputChannels();
    auto totalNumOutputChannels = getTotalNumOutputChannels();
    for (auto i = totalNumInputChannels; i < totalNumOutputChannels; ++i)
        buffer.clear (i, 0, buffer.getNumSamples());
    
    float* leftChannel = buffer.getWritePointer(0);
    float* rightChannel = buffer.getWritePointer(1);
    
    for (int i = 0; i < buffer.getNumSamples(); i++)
    {
        mTimeSmoothed = mTimeSmoothed - 0.0001*(mTimeSmoothed - *mTimeParameter);
        mDelayTimeInSamples =  getSampleRate() * mTimeSmoothed;
        
        mCircularBufferLeft[mCircularBufferWriteHead] = leftChannel[i] + mFeedbackLeft;
        mCircularBufferRight[mCircularBufferWriteHead] = rightChannel[i] + mFeedbackRight;
        
        mDelayReadHead = mCircularBufferWriteHead - mDelayTimeInSamples;
        
        if (mDelayReadHead < 0)
        {
            mDelayReadHead += mCircularBufferLength;
        }
{% endhighlight %}
 

The above code begins the processing. First, a loop clears the existing buffer which removes a backlog of audio data that can linger when playback in ended and restarted, resulting in leftover audio that you don't want in your projects.

Next, the main processing loop begins. This loop iterates over the number of samples in the input audio buffer. The first thing that happens is a smoothing value is determined so that audio doesn't experience artifactring when the delay time doesn't fit nicely within the sample rate. Then the internal circular buffer at the current writehead is set to the float value for the feedback audio added to the input audio. Finally, the the write location for the delay is determined and wrapped around the buffer if that calculated index goes beyond the length of the circular buffer. (The length is predetermined in code based on what a reasonable max delay time should be)

{% highlight cpp %}
        int readHead_x = (int)mDelayReadHead;
        int readHead_x1 = readHead_x + 1;
        float readHeadFloat = mDelayReadHead - readHead_x;
        
        if (readHead_x1 >= mCircularBufferLength)
        {
            readHead_x1 -= mCircularBufferLength;
        }
        
        float delay_sample_left = lin_interp(mCircularBufferLeft[readHead_x], mCircularBufferLeft[readHead_x1], readHeadFloat);
        float delay_sample_right = lin_interp(mCircularBufferRight[readHead_x], mCircularBufferRight[readHead_x1], readHeadFloat);
{% endhighlight %}
 

This section performs interpolation between two points of audio. Sometimes, a delay time value will occur in between samples (because the same rate is an integer division of each second, generally 44.1 kHz) and so we use linear interpolation to determine what the adjacent values should be. This makes the output much smoother and less populated by artifacts.

{% highlight cpp %}
        mFeedbackLeft = delay_sample_left * *mFeedbackParameter;
        mFeedbackRight = delay_sample_right * *mFeedbackParameter;
        
        mCircularBufferWriteHead++;
        
        buffer.setSample(0, i, buffer.getSample(0, i) * (1 - *mDryWetParameter) + delay_sample_left * *mDryWetParameter);
        buffer.setSample(1, i, buffer.getSample(1, i) * (1 - *mDryWetParameter) + delay_sample_right *  *mDryWetParameter);
        
        if (mCircularBufferWriteHead >= mCircularBufferLength)
        {
            mCircularBufferWriteHead = 0;
        }
    }
}
{% endhighlight %}
 
 
In this last portion, the feedback values are calculated, then the delay is added to the input sample and sent to be output. The feedback is calculated by multiplying the delay sample by the feedback parameter, which gives it the falling-off effect that feedback creates over time. This is used on the next iteration in the first code block above. Calling the function buffer.setSample() is what writes audio to the actual output that goes out to the digital audio workstation. Inside of these function calls, one for each of the left and right channels, the input audio and delay audio are added together. The additional parameters in the equation multiply each value by the dry/wet value which is used to control how prominent the delay effect is. The circular buffer write location is incremented, then the process block repeats.


## Chorus/Flanger
----

