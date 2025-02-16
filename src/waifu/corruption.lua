local Card = require("src.cards.card")

local Corruption = {}
Corruption.__index = Corruption

-- Corruption thresholds based on total scored value
local THRESHOLDS = {
    LOW = 50,     -- Points scored
    MEDIUM = 100,
    HIGH = 200,
    EXTREME = 300
}

-- Corruption states and their descriptions
local STATES = {
    DATES = {
        [THRESHOLDS.LOW] = {
            multiplier = 1.2,
            description = "She's starting to get picky about restaurants..."
        },
        [THRESHOLDS.MEDIUM] = {
            multiplier = 1.5,
            description = "She's developed expensive taste in wine and won't shut up about it."
        },
        [THRESHOLDS.HIGH] = {
            multiplier = 2.0,
            description = "She's gained weight and blames your date choices. Only Michelin stars will do now."
        },
        [THRESHOLDS.EXTREME] = {
            multiplier = 2.5,
            description = "She's become a full-blown food and wine snob. Your wallet weeps."
        }
    },
    GIFTS = {
        [THRESHOLDS.LOW] = {
            multiplier = 1.2,
            description = "She's started comparing your gifts to her friends' presents..."
        },
        [THRESHOLDS.MEDIUM] = {
            multiplier = 1.5,
            description = "She's following all the luxury brand accounts. Your credit card trembles."
        },
        [THRESHOLDS.HIGH] = {
            multiplier = 2.0,
            description = "She's become a label-obsessed shopaholic. Gucci or go home."
        },
        [THRESHOLDS.EXTREME] = {
            multiplier = 2.5,
            description = "She's turned into a full-blown material girl. Nothing below designer will do."
        }
    },
    COMPLIMENTS = {
        [THRESHOLDS.LOW] = {
            multiplier = 1.2,
            description = "She's starting to expect praise for basic tasks..."
        },
        [THRESHOLDS.MEDIUM] = {
            multiplier = 1.5,
            description = "She calls herself a queen unironically now."
        },
        [THRESHOLDS.HIGH] = {
            multiplier = 2.0,
            description = "She's developed a god complex. Everything is beneath her."
        },
        [THRESHOLDS.EXTREME] = {
            multiplier = 2.5,
            description = "She's become insufferably narcissistic. You're just an NPC in her world."
        }
    },
    SOCIAL = {
        [THRESHOLDS.LOW] = {
            multiplier = 1.2,
            description = "She's posting thirst traps 'for the engagement'..."
        },
        [THRESHOLDS.MEDIUM] = {
            multiplier = 1.5,
            description = "She's started doing questionable sponsored posts."
        },
        [THRESHOLDS.HIGH] = {
            multiplier = 2.0,
            description = "She's become an 'influencer'. God help us all."
        },
        [THRESHOLDS.EXTREME] = {
            multiplier = 2.5,
            description = "She's started an OnlyFans. It's her 'personal brand' now."
        }
    }
}

-- Create a new corruption tracker
function Corruption.new()
    local self = {
        suitValues = {
            [Card.SUITS.DATES] = 0,
            [Card.SUITS.GIFTS] = 0,
            [Card.SUITS.COMPLIMENTS] = 0,
            [Card.SUITS.SOCIAL] = 0
        },
        messages = {}
    }
    return setmetatable(self, Corruption)
end

-- Get the corruption level for scored value
function Corruption.getLevel(value)
    if value >= THRESHOLDS.EXTREME then
        return THRESHOLDS.EXTREME
    elseif value >= THRESHOLDS.HIGH then
        return THRESHOLDS.HIGH
    elseif value >= THRESHOLDS.MEDIUM then
        return THRESHOLDS.MEDIUM
    elseif value >= THRESHOLDS.LOW then
        return THRESHOLDS.LOW
    end
    return 0
end

-- Track a scored hand
function Corruption:trackHand(hand)
    -- Only track if the hand is valid and scored
    if hand.isValid and hand.value > 0 then
        local totalValue = hand.value * hand.multiplier
        self.suitValues[hand.suit] = self.suitValues[hand.suit] + totalValue
        
        -- Check for new corruption level
        local value = self.suitValues[hand.suit]
        local level = Corruption.getLevel(value)
        
        if level > 0 then
            local suitName = hand.suit:upper()
            local corruption = STATES[suitName][level]
            
            -- Add message if it's new
            if not self.messages[hand.suit] or self.messages[hand.suit].level < level then
                self.messages[hand.suit] = {
                    level = level,
                    description = corruption.description
                }
            end
        end
    end
end

-- Get multiplier for a suit
function Corruption:getMultiplier(suit)
    local value = self.suitValues[suit]
    local level = Corruption.getLevel(value)
    
    if level > 0 then
        local suitName = suit:upper()
        return STATES[suitName][level].multiplier
    end
    
    return 1.0
end

-- Get all active corruption messages
function Corruption:getMessages()
    local result = {}
    for suit, message in pairs(self.messages) do
        table.insert(result, {
            suit = suit,
            level = message.level,
            description = message.description
        })
    end
    return result
end

return Corruption 