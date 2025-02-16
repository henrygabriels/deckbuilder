local BasicAudio = {}

-- Sound effect configuration
local SOUNDS = {
    CARD_PLAY = {
        frequency = 440,  -- A4 note
        duration = 0.1,
        volume = 0.3
    },
    CORRUPTION = {
        frequency = 220,  -- A3 note
        duration = 0.2,
        volume = 0.4
    },
    LEVEL_UP = {
        frequency = {440, 550, 660},  -- A4, C#5, E5
        duration = 0.15,
        volume = 0.5
    },
    GAME_OVER = {
        frequency = {330, 262},  -- E4, C4
        duration = 0.3,
        volume = 0.4
    },
    ROUND_START = {
        frequency = {523, 659, 784},  -- C5, E5, G5
        duration = 0.2,
        volume = 0.4
    }
}

-- Hand-specific chord frequencies (in C major, moved down octaves)
local HAND_CHORDS = {
    ["Royal Flush"] = {
        frequencies = {261.63, 329.63, 392.00, 523.25},  -- C4, E4, G4, C5 (C major with octave)
        duration = 0.8,
        volume = 0.8
    },
    ["Straight Flush"] = {
        frequencies = {261.63, 329.63, 392.00},  -- C4, E4, G4 (C major)
        duration = 0.7,
        volume = 0.75
    },
    ["Four of a Kind"] = {
        frequencies = {261.63, 329.63, 392.00, 466.16},  -- C4, E4, G4, Bb4 (C dominant 7)
        duration = 0.7,
        volume = 0.7
    },
    ["Full House"] = {
        frequencies = {261.63, 311.13, 392.00},  -- C4, Eb4, G4 (C minor)
        duration = 0.6,
        volume = 0.7
    },
    ["Flush"] = {
        frequencies = {261.63, 329.63, 440.00},  -- C4, E4, A4 (C major add 6)
        duration = 0.6,
        volume = 0.65
    },
    ["Straight"] = {
        frequencies = {261.63, 311.13, 392.00, 440.00},  -- C4, Eb4, G4, A4 (C minor add 6)
        duration = 0.6,
        volume = 0.65
    },
    ["Three of a Kind"] = {
        frequencies = {261.63, 311.13, 349.23},  -- C4, Eb4, F4 (C minor no 5)
        duration = 0.5,
        volume = 0.6
    },
    ["Two Pair"] = {
        frequencies = {261.63, 293.66, 349.23},  -- C4, D4, F4 (C sus2 no 5)
        duration = 0.5,
        volume = 0.6
    },
    ["One Pair"] = {
        frequencies = {261.63, 293.66},  -- C4, D4 (Major 2nd)
        duration = 0.4,
        volume = 0.55
    },
    ["High Card"] = {
        frequencies = {261.63},  -- C4 (single note)
        duration = 0.4,
        volume = 0.5
    }
}

-- C major scale frequencies (all moved down an octave for more pleasant tones)
local CARD_NOTES = {
    [2] = 130.81,  -- C3 (root)
    [3] = 146.83,  -- D3
    [4] = 164.81,  -- E3
    [5] = 174.61,  -- F3
    [6] = 196.00,  -- G3
    [7] = 220.00,  -- A3
    [8] = 246.94,  -- B3
    [9] = 261.63,  -- C4
    [10] = 293.66, -- D4
    ["JACK"] = 392.00,   -- G4
    ["QUEEN"] = 440.00,  -- A4
    ["KING"] = 493.88,   -- B4
    ["ACE"] = 523.25     -- C5
}

-- Generate a pleasant sound with envelope shaping and harmonics
local function generateSound(freq, duration, volume)
    local sampleRate = 44100
    local samples = math.floor(duration * sampleRate)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    -- Envelope parameters
    local attack = 0.02  -- 20ms attack
    local decay = 0.1   -- 100ms decay
    local sustain = 0.7  -- 70% sustain level
    local release = 0.1  -- 100ms release
    
    -- Harmonic ratios and their volumes
    local harmonics = {
        {ratio = 1.0, vol = 1.0},    -- Fundamental
        {ratio = 2.0, vol = 0.3},    -- Octave
        {ratio = 3.0, vol = 0.15},   -- Fifth
        {ratio = 4.0, vol = 0.1}     -- Second octave
    }
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local envelope = 0
        
        -- Calculate envelope
        if t < attack then
            envelope = t / attack
        elseif t < attack + decay then
            envelope = 1.0 - (1.0 - sustain) * (t - attack) / decay
        elseif t < duration - release then
            envelope = sustain
        else
            envelope = sustain * (1.0 - (t - (duration - release)) / release)
        end
        
        -- Generate harmonics
        local value = 0
        for _, harmonic in ipairs(harmonics) do
            value = value + math.sin(2 * math.pi * freq * harmonic.ratio * t) * harmonic.vol
        end
        
        -- Apply envelope and volume
        value = value * envelope * volume * 0.25  -- Reduced overall volume for pleasantness
        
        -- Soft clipping for a warmer sound
        value = math.tanh(value)
        
        soundData:setSample(i, value)
    end
    
    return love.audio.newSource(soundData)
end

-- Generate a retro-style deal sound (8-bit like, shorter, crunchy)
local function generateDealSound(freq, duration, volume)
    local sampleRate = 44100
    local samples = math.floor(duration * sampleRate)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    -- Shorter envelope for snappier sound
    local attack = 0.01
    local decay = 0.05
    local sustain = 0.4
    local release = 0.05
    
    -- Simplified harmonics for more "8-bit" sound
    local harmonics = {
        {ratio = 1.0, vol = 1.0},    -- Fundamental
        {ratio = 2.0, vol = 0.5},    -- First octave (stronger for bit-crushed sound)
        {ratio = 4.0, vol = 0.3}     -- Second octave
    }
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local envelope = 0
        
        -- Calculate envelope
        if t < attack then
            envelope = t / attack
        elseif t < attack + decay then
            envelope = 1.0 - (1.0 - sustain) * (t - attack) / decay
        elseif t < duration - release then
            envelope = sustain
        else
            envelope = sustain * (1.0 - (t - (duration - release)) / release)
        end
        
        -- Generate basic waveform
        local value = 0
        for _, harmonic in ipairs(harmonics) do
            value = value + math.sin(2 * math.pi * freq * harmonic.ratio * t) * harmonic.vol
        end
        
        -- Add bit-crushing effect
        local crushFactor = 8  -- Reduce bit depth for retro sound
        value = math.floor(value * crushFactor) / crushFactor
        
        -- Apply envelope and volume (quieter than normal notes)
        value = value * envelope * volume * 0.15
        
        soundData:setSample(i, value)
    end
    
    return love.audio.newSource(soundData)
end

-- Generate a card sliding sound (white noise with envelope shaping)
local function generateCardSlideSound()
    local sampleRate = 44100
    local duration = 0.15  -- Short duration for the slide
    local samples = math.floor(duration * sampleRate)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    -- Envelope for the sliding sound
    local attack = 0.02
    local decay = 0.08
    local sustain = 0.5
    local release = 0.05
    
    -- Noise parameters
    local volume = 0.2
    local filterStrength = 0.7  -- Higher values = more high-frequency filtering
    
    -- Previous sample for filtering
    local prevSample = 0
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local envelope = 0
        
        -- Calculate envelope
        if t < attack then
            envelope = t / attack
        elseif t < attack + decay then
            envelope = 1.0 - (1.0 - sustain) * (t - attack) / decay
        elseif t < duration - release then
            envelope = sustain
        else
            envelope = sustain * (1.0 - (t - (duration - release)) / release)
        end
        
        -- Generate filtered noise
        local noise = love.math.random() * 2 - 1
        local filteredNoise = noise * (1 - filterStrength) + prevSample * filterStrength
        prevSample = filteredNoise
        
        -- Shape the noise with the envelope
        local value = filteredNoise * envelope * volume
        
        soundData:setSample(i, value)
    end
    
    return love.audio.newSource(soundData)
end

-- Generate a chord with retro arpeggiation and bit-crushing
local function generateChord(frequencies, duration, volume)
    local sampleRate = 44100
    local samples = math.floor(duration * sampleRate)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    -- Retro envelope parameters
    local attack = 0.02
    local decay = 0.1
    local sustain = 0.8  -- Increased sustain
    local release = 0.2  -- Longer release
    
    -- Arpeggiation parameters
    local arpeggioRate = 0.08  -- Time between notes in arpeggio
    local arpeggioAttack = 0.01
    local arpeggioDecay = 0.05
    
    -- Simplified harmonics for more retro sound
    local harmonics = {
        {ratio = 1.0, vol = 1.0},    -- Fundamental
        {ratio = 2.0, vol = 0.4},    -- Octave
        {ratio = 3.0, vol = 0.2}     -- Fifth
    }
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local envelope = 0
        
        -- Calculate main envelope
        if t < attack then
            envelope = t / attack
        elseif t < attack + decay then
            envelope = 1.0 - (1.0 - sustain) * (t - attack) / decay
        elseif t < duration - release then
            envelope = sustain
        else
            envelope = sustain * (1.0 - (t - (duration - release)) / release)
        end
        
        -- Generate arpeggiated notes
        local value = 0
        for noteIndex, freq in ipairs(frequencies) do
            local noteStartTime = (noteIndex - 1) * arpeggioRate
            local noteTime = t - noteStartTime
            
            if noteTime >= 0 then
                -- Calculate note envelope
                local noteEnvelope = 0
                if noteTime < arpeggioAttack then
                    noteEnvelope = noteTime / arpeggioAttack
                elseif noteTime < arpeggioAttack + arpeggioDecay then
                    noteEnvelope = 1.0 - (1.0 - 0.7) * (noteTime - arpeggioAttack) / arpeggioDecay
                else
                    noteEnvelope = 0.7
                end
                
                -- Add harmonics for this note
                for _, harmonic in ipairs(harmonics) do
                    value = value + math.sin(2 * math.pi * freq * harmonic.ratio * noteTime) 
                        * harmonic.vol * noteEnvelope
                end
            end
        end
        
        -- Apply bit-crushing effect
        local crushFactor = 12  -- Adjust for desired retro feel
        value = math.floor(value * crushFactor) / crushFactor
        
        -- Apply main envelope and volume
        value = value * envelope * volume * 0.25
        
        -- Soft clipping
        value = math.tanh(value)
        
        soundData:setSample(i, value)
    end
    
    return love.audio.newSource(soundData)
end

-- Initialize sound effects
function BasicAudio.init()
    BasicAudio.sounds = {}
    
    -- Initialize standard sound effects
    for name, config in pairs(SOUNDS) do
        if type(config.frequency) == "table" then
            BasicAudio.sounds[name] = generateChord(config.frequency, config.duration, config.volume)
        else
            BasicAudio.sounds[name] = generateSound(config.frequency, config.duration, config.volume)
        end
    end
    
    -- Initialize card selection notes
    for value, freq in pairs(CARD_NOTES) do
        local noteName = "CARD_" .. tostring(value)
        BasicAudio.sounds[noteName] = generateSound(freq, 0.25, 0.4)  -- Longer duration, moderate volume
        
        -- Also create retro deal sounds for each note
        local dealNoteName = "DEAL_" .. tostring(value)
        BasicAudio.sounds[dealNoteName] = generateDealSound(freq, 0.12, 0.5)  -- Increased volume from 0.3 to 0.5
    end
    
    -- Initialize card slide sound for discards
    BasicAudio.sounds["CARD_SLIDE"] = generateCardSlideSound()
end

-- Play a sound effect
function BasicAudio.play(soundName)
    if BasicAudio.sounds and BasicAudio.sounds[soundName] then
        BasicAudio.sounds[soundName]:stop() -- Stop if already playing
        BasicAudio.sounds[soundName]:play()
    end
end

-- Play note for card value
function BasicAudio.playCardNote(value)
    local noteName = "CARD_" .. tostring(value)
    BasicAudio.play(noteName)
end

-- Play deal note for card value
function BasicAudio.playDealNote(value)
    local dealNoteName = "DEAL_" .. tostring(value)
    BasicAudio.play(dealNoteName)
end

-- Play card slide sound
function BasicAudio.playCardSlide()
    BasicAudio.play("CARD_SLIDE")
end

-- Play chord for poker hand
function BasicAudio.playHandChord(handType)
    local chordConfig = HAND_CHORDS[handType]
    if chordConfig then
        -- Create a unique name for this chord
        local chordName = "HAND_" .. handType
        
        -- Generate the chord if we haven't already
        if not BasicAudio.sounds[chordName] then
            BasicAudio.sounds[chordName] = generateChord(
                chordConfig.frequencies,
                chordConfig.duration,
                chordConfig.volume
            )
        end
        
        -- Play the chord
        BasicAudio.play(chordName)
    end
end

return BasicAudio 