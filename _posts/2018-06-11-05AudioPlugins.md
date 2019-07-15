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

Chorus and Flanger effects are variations on taking the original audio and adding a copy that has altered timing, pitch, and/or phase. This makes the signal sound bigger, airier, wider, more interesting. Flangers vary in timing very minimally, just enough to create a space between the signals, while a chorus is a much more drastic effect with the ability for longer delay times between the dry and wet signals.


In the video below, I try to show the more extreme settings for this plugin to emphasize the effect:

<div style="width: 100%; margin: auto auto auto auto;">
    <div class="ytcontainer">
        <iframe class="ytframe" src="https://www.youtube.com/embed/iTT6ywb1PUo"
         frameborder="0" allowfullscreen></iframe>
    </div>
</div>

Like in the delay plugin above, all the magic for this one happens in the processBlock() function. A lot of the same core concepts apply since these are similar effects, but this one relies on low frequency modulation, or LFO. This uses a sine function to alter the input and to create effects from the difference in phases between two channels.

Here, an LFO is established for the left channel. To get the phase of the right channel's LFO, the phase of the left channel is added to the offset amount that the user has specified. Then the right LFO is started with that phase. The time value for both is incremented on every iteration of the loop to move it along.

{% highlight cpp %}
    //LFO start
    // Generate left LFO output
    float lfoOutLeft = sin(2*M_PI * mLFOPhase);

    // Calculate right channel LFO phase
    float lfoPhaseRight = mLFOPhase + *mPhaseOffsetParameter;

    if (lfoPhaseRight > 1) {
        lfoPhaseRight -= 1;
    }
    // Generate right LFO output
    float lfoOutRight = sin(2*M_PI * lfoPhaseRight);

    // Move our LFO phase forward
    mLFOPhase += *mRateParameter / getSampleRate();

    if (mLFOPhase > 1)
        mLFOPhase -= 1;
{% end highlight %}

Next, the LFOs have their amplitude multiplied by the depth parameter set by the user. This parameter at its most extreme makes the sound super whacky.

Next, the distinction is made between chorus and flanger effects. The user selects which effect they want in a dropdown, which directs the control in the if statement. The difference is that the delay for choruses can vary between 0.005 and 0.03 seconds, whereas the flanger spans 0.001 to 0.005 seconds. The chorus effect represents the typical variance in timing across a full choir of people singing, while the flanger is a more subtle, electronic warble effect.

{% highlight cpp %}
    // Control the LFO depth by mult output by depth param
    lfoOutLeft *= *mDepthParameter;
    lfoOutRight *= *mDepthParameter;

    float lfoOutMappedLeft;
    float lfoOutMappedRight;

    // Map LFO outputs to desired delay times (chorus/flanger)
    //
    // Chorus
    if (*mTypeParameter == 0)
    {
        lfoOutMappedLeft = jmap(lfoOutLeft, -1.f, 1.f, 0.005f, 0.03f);
        lfoOutMappedRight = jmap(lfoOutRight, -1.f, 1.f, 0.005f, 0.03f);
    }
    else
    {
        lfoOutMappedLeft = jmap(lfoOutLeft, -1.f, 1.f, 0.001f, 0.005f);
        lfoOutMappedRight = jmap(lfoOutRight, -1.f, 1.f, 0.001f, 0.005f);
    }

    // Calculate delay lengths in samples
    float delayTimeSamplesLeft = getSampleRate() * lfoOutMappedLeft;
    float delayTimeSamplesRight = getSampleRate() * lfoOutMappedRight;
{% endhighlight %}

The mapping functions here take the raw LFO value within the range of -1 to 1 at that time and map it to the appropriate range for the selected effect. In the chorus, the range is mapped to be between 0.005 and 0.03. Then that value is converted to samples by multiplying it by the sample rate (usually 44.1khz). From there, the rest of the function works the exact same as the delay in how it sends the output to be played as audio.

----

Working on these audio plugins was the most fun I've ever had developing software. I spend a large amount of my time interacting with plugins while making my own music, so getting a look under the hood of how these plugins work was fascinating. Not only do I now have a greater understanding of how DSP works, but it has helped me to understand what the plugins I use are doing and what effect different parameters really have at a low level. Whether I can get paid to do this kind of work or it just becomes a new component of my hobby, I'll for sure be studying and creating new software like this as long as I am developer.


