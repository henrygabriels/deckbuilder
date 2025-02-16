local BasicAudio = {}

-- Sound effect configuration
local SOUNDS = {
    CARD_PLAY = {
        frequency = 440,  -- A4 note
        duration = 0.1,
        volume = 0.3
    },
    CARD_DISCARD = {
        frequency = 330,  -- E4 note
        duration = 0.1,
        volume = 0.2
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

-- Generate a simple sine wave sound
local function generateSound(freq, duration, volume)
    local sampleRate = 44100
    local samples = math.floor(duration * sampleRate)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local value = math.sin(2 * math.pi * freq * t) * volume
        soundData:setSample(i, value)
    end
    
    return love.audio.newSource(soundData)
end

-- Generate a chord sound
local function generateChord(frequencies, duration, volume)
    local sampleRate = 44100
    local samples = math.floor(duration * sampleRate)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local value = 0
        for _, freq in ipairs(frequencies) do
            value = value + math.sin(2 * math.pi * freq * t)
        end
        value = (value / #frequencies) * volume
        soundData:setSample(i, value)
    end
    
    return love.audio.newSource(soundData)
end

-- Initialize sound effects
function BasicAudio.init()
    BasicAudio.sounds = {}
    
    for name, config in pairs(SOUNDS) do
        if type(config.frequency) == "table" then
            BasicAudio.sounds[name] = generateChord(config.frequency, config.duration, config.volume)
        else
            BasicAudio.sounds[name] = generateSound(config.frequency, config.duration, config.volume)
        end
    end
end

-- Play a sound effect
function BasicAudio.play(soundName)
    if BasicAudio.sounds and BasicAudio.sounds[soundName] then
        BasicAudio.sounds[soundName]:stop() -- Stop if already playing
        BasicAudio.sounds[soundName]:play()
    end
end

return BasicAudio 