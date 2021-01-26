//
//  CustomOscillatorDSP.m
//  VisualizerPlayground
//
//  Created by Matt Pfeiffer on 1/17/21.
//

#include "SoundpipeDSPBase.h"
#include "ParameterRamper.h"
#include "soundpipe.h"
#include "customosc.h"
#include <vector>

enum CustomOscillatorParameter : AUParameterAddress {
    CustomOscillatorParameterFrequency,
    CustomOscillatorParameterAmplitude,
    CustomOscillatorParameterDetuningOffset,
    CustomOscillatorParameterDetuningMultiplier,
};

class CustomOscillatorDSP : public SoundpipeDSPBase {
private:
    sp_customosc *osc = nullptr;    // soundpipe oscillator
    std::vector<float> waveform;    // this seems to translate Table.content into what SoundPipe's table is looking for
    sp_ftbl *ftbl_one = nullptr;    // soundpipe table one
    sp_ftbl *ftbl_two = nullptr;    // soundpipe table two
    bool isSetup = false;           // allows us to use setWavetable for initial setup and for dynamic wavetable setting
    bool isSwapped = false;         // table one = false, table two = true
    bool isFading = false;          // while true, tables won't be set (inc limits how fast new tables can be set)
    float tableOneFactor = 1.0;     // ratio of table one's float value included in output
    float tableTwoFactor = 0.0;     // ratio of table two's float value included in output
    float inc = 0.005;              // how fast should we fade on each frame?
    
    ParameterRamper frequencyRamp;
    ParameterRamper tremoloFrequencyRamp;
    ParameterRamper amplitudeRamp;
    ParameterRamper detuningOffsetRamp;
    ParameterRamper detuningMultiplierRamp;

public:
    CustomOscillatorDSP() : SoundpipeDSPBase(/*inputBusCount*/0) {
        parameters[CustomOscillatorParameterFrequency] = &frequencyRamp;
        parameters[CustomOscillatorParameterAmplitude] = &amplitudeRamp;
        parameters[CustomOscillatorParameterDetuningOffset] = &detuningOffsetRamp;
        parameters[CustomOscillatorParameterDetuningMultiplier] = &detuningMultiplierRamp;
        isStarted = false;
    }

    void setWavetable(const float* table, size_t length, int index) override {
        if (!isSetup) {
            waveform = std::vector<float>(table, table + length);
            reset();
            isSetup = true;
        } else if (!isFading) {
            waveform = std::vector<float>(table, table + length);
            if(isSwapped) {
                sp_ftbl_destroy(&ftbl_one);
                sp_ftbl_create(sp, &ftbl_one, waveform.size());
                std::copy(waveform.cbegin(), waveform.cend(), ftbl_one->tbl);
            } else {
                sp_ftbl_destroy(&ftbl_two);
                sp_ftbl_create(sp, &ftbl_two, waveform.size());
                std::copy(waveform.cbegin(), waveform.cend(), ftbl_two->tbl);
            }
            isFading = true;
        }
    }

    void init(int channelCount, double sampleRate) override {
        SoundpipeDSPBase::init(channelCount, sampleRate);
        
        sp_ftbl_create(sp, &ftbl_one, waveform.size());
        std::copy(waveform.cbegin(), waveform.cend(), ftbl_one->tbl);
        sp_ftbl_create(sp, &ftbl_two, waveform.size());
        std::copy(waveform.cbegin(), waveform.cend(), ftbl_two->tbl);
        
        sp_customosc_create(&osc);
        sp_customosc_init(sp, osc, 0);
    }

    void deinit() override {
        SoundpipeDSPBase::deinit();
        sp_customosc_destroy(&osc);
        sp_ftbl_destroy(&ftbl_one);
        sp_ftbl_destroy(&ftbl_two);
    }

    void reset() override {
        SoundpipeDSPBase::reset();
        if (!isInitialized) return;
        sp_customosc_init(sp, osc, 0);
    }

    void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) override {
        for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
            int frameOffset = int(frameIndex + bufferOffset);
            float frequency = frequencyRamp.getAndStep();
            float detuneMultiplier = detuningMultiplierRamp.getAndStep();
            float detuneOffset = detuningOffsetRamp.getAndStep();
            osc->freq = frequency * detuneMultiplier + detuneOffset;
            osc->amp = amplitudeRamp.getAndStep();
            float temp = 0;
            float temp2 = 0;
            
            for (int channel = 0; channel < channelCount; ++channel) {
                float *out = (float *)outputBufferList->mBuffers[channel].mData + frameOffset;
                if (isStarted) {
                    if (channel == 0) {
                        if (isFading) {
                            // get values from both tables
                            sp_customosc_compute(sp, osc, ftbl_one, nil, &temp, false); // does not move phase
                            sp_customosc_compute(sp, osc, ftbl_two, nil, &temp2, true); // does move phase
                            stepFade();
                        }
                        else {
                            // if we are not fading, grab from clean table (other table is dirty - could be overwritten at any moment)
                            if(!isSwapped) {
                                sp_customosc_compute(sp, osc, ftbl_one, nil, &temp, true);
                            } else {
                                sp_customosc_compute(sp, osc, ftbl_two, nil, &temp2, true);
                            }
                        }
                    }
                    *out = temp * tableOneFactor + temp2 * tableTwoFactor; // simple crossfade algorithm
                } else {
                    *out = 0.0;
                }
            }
        }
    }
    
    void stepFade(){
        if(!isSwapped) {
            // table one is fading into two
            tableOneFactor = tableOneFactor - inc;
            tableTwoFactor = tableTwoFactor + inc;
            if( tableTwoFactor >= 1.0){
                endFade();
            }
        } else {
            // table two is fading into one
            tableOneFactor = tableOneFactor + inc;
            tableTwoFactor = tableTwoFactor - inc;
            if( tableOneFactor >= 1.0){
                endFade();
            }
        }
    }
    
    void endFade(){
        tableOneFactor = isSwapped ? 1.0 : 0.0;
        tableTwoFactor = isSwapped ? 0.0 : 1.0;
        isSwapped = !isSwapped;
        isFading = false;
    }
    
};

AK_REGISTER_DSP(CustomOscillatorDSP)
AK_REGISTER_PARAMETER(CustomOscillatorParameterFrequency)
AK_REGISTER_PARAMETER(CustomOscillatorParameterAmplitude)
AK_REGISTER_PARAMETER(CustomOscillatorParameterDetuningOffset)
AK_REGISTER_PARAMETER(CustomOscillatorParameterDetuningMultiplier)
