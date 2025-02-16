local Card = require("src.cards.card")

local Effects = {}

-- Base Modifier class
local Modifier = {}
Modifier.__index = Modifier

function Modifier.new(id, name, description)
    local self = setmetatable({}, Modifier)
    self.id = id
    self.name = name
    self.description = description
    return self
end

function Modifier:apply(value, card, gameState)
    return value -- Base implementation returns unmodified value
end

function Modifier:affectsCardType(cardType)
    return true -- Base implementation affects all card types
end

-- Personality Trait Modifiers
local HighMaintenanceModifier = setmetatable({}, {__index = Modifier})
HighMaintenanceModifier.__index = HighMaintenanceModifier

function HighMaintenanceModifier.new()
    local self = Modifier.new(
        "high-maintenance",
        "High Maintenance",
        "Doubles gift effectiveness but also their cost"
    )
    return setmetatable(self, HighMaintenanceModifier)
end

function HighMaintenanceModifier:apply(value, card, gameState)
    if card.type == "gift" then
        return value * 2
    end
    return value
end

function HighMaintenanceModifier:affectsCardType(cardType)
    return cardType == "gift"
end

-- Influencer Modifier
local InfluencerModifier = setmetatable({}, {__index = Modifier})
InfluencerModifier.__index = InfluencerModifier

function InfluencerModifier.new()
    local self = Modifier.new(
        "influencer",
        "Influencer",
        "Social media cards are 50% more effective"
    )
    return setmetatable(self, InfluencerModifier)
end

function InfluencerModifier:apply(value, card, gameState)
    if card.type == "social" then
        return value * 1.5
    end
    return value
end

function InfluencerModifier:affectsCardType(cardType)
    return cardType == "social"
end

-- Yandere Modifier
local YandereModifier = setmetatable({}, {__index = Modifier})
YandereModifier.__index = YandereModifier

function YandereModifier.new()
    local self = Modifier.new(
        "yandere",
        "Yandere",
        "Attention cards have random effectiveness (0.5x to 3x)"
    )
    return setmetatable(self, YandereModifier)
end

function YandereModifier:apply(value, card, gameState)
    if card.type == "attention" then
        return value * (0.5 + love.math.random() * 2.5)
    end
    return value
end

function YandereModifier:affectsCardType(cardType)
    return cardType == "attention"
end

-- Kuudere Modifier
local KuudereModifier = setmetatable({}, {__index = Modifier})
KuudereModifier.__index = KuudereModifier

function KuudereModifier.new()
    local self = Modifier.new(
        "kuudere",
        "Kuudere",
        "Reverses positive/negative effects"
    )
    return setmetatable(self, KuudereModifier)
end

function KuudereModifier:apply(value, card, gameState)
    local difference = value - card.baseValue
    return card.baseValue - difference
end

-- Power-up Modifiers
local BoyfriendExperienceModifier = setmetatable({}, {__index = Modifier})
BoyfriendExperienceModifier.__index = BoyfriendExperienceModifier

function BoyfriendExperienceModifier.new()
    local self = Modifier.new(
        "boyfriend-experience",
        "Boyfriend Experience",
        "Basic attention cards gain +3 base value"
    )
    return setmetatable(self, BoyfriendExperienceModifier)
end

function BoyfriendExperienceModifier:apply(value, card, gameState)
    if card.type == "attention" then
        return value + 3
    end
    return value
end

function BoyfriendExperienceModifier:affectsCardType(cardType)
    return cardType == "attention"
end

-- Sugar Daddy Modifier
local SugarDaddyModifier = setmetatable({}, {__index = Modifier})
SugarDaddyModifier.__index = SugarDaddyModifier

function SugarDaddyModifier.new()
    local self = Modifier.new(
        "sugar-daddy",
        "Sugar Daddy",
        "Gift cards cost 1 less and gain +2 base value"
    )
    return setmetatable(self, SugarDaddyModifier)
end

function SugarDaddyModifier:apply(value, card, gameState)
    if card.type == "gift" then
        return value + 2
    end
    return value
end

function SugarDaddyModifier:affectsCardType(cardType)
    return cardType == "gift"
end

-- Social Media Expert Modifier
local SocialMediaExpertModifier = setmetatable({}, {__index = Modifier})
SocialMediaExpertModifier.__index = SocialMediaExpertModifier

function SocialMediaExpertModifier.new()
    local self = Modifier.new(
        "social-media-expert",
        "Social Media Expert",
        "Social media cards gain additional value for each other social card played this turn"
    )
    return setmetatable(self, SocialMediaExpertModifier)
end

function SocialMediaExpertModifier:apply(value, card, gameState)
    if card.type == "social" then
        local socialCardsPlayed = 0
        for _, playedCard in ipairs(gameState.playedCards) do
            if playedCard.type == "social" then
                socialCardsPlayed = socialCardsPlayed + 1
            end
        end
        return value + (socialCardsPlayed * 2)
    end
    return value
end

function SocialMediaExpertModifier:affectsCardType(cardType)
    return cardType == "social"
end

-- Poker hand types with base scores and multipliers (Balatro-style)
Effects.POKER_HANDS = {
    ROYAL_FLUSH = { 
        name = "Royal Flush", 
        baseScore = 1000,
        multiplier = 15
    },
    STRAIGHT_FLUSH = { 
        name = "Straight Flush", 
        baseScore = 750,
        multiplier = 12
    },
    FOUR_OF_A_KIND = { 
        name = "Four of a Kind", 
        baseScore = 600,
        multiplier = 10
    },
    FULL_HOUSE = { 
        name = "Full House", 
        baseScore = 500,
        multiplier = 8
    },
    FLUSH = { 
        name = "Flush", 
        baseScore = 400,
        multiplier = 6
    },
    STRAIGHT = { 
        name = "Straight", 
        baseScore = 300,
        multiplier = 5
    },
    THREE_OF_A_KIND = { 
        name = "Three of a Kind", 
        baseScore = 200,
        multiplier = 4
    },
    TWO_PAIR = { 
        name = "Two Pair", 
        baseScore = 100,
        multiplier = 3
    },
    ONE_PAIR = { 
        name = "One Pair", 
        baseScore = 50,
        multiplier = 2
    },
    HIGH_CARD = {
        name = "High Card",
        baseScore = 10,  -- Will be multiplied by card value
        multiplier = 1
    }
}

-- Helper function to sort cards by value
local function sortByValue(cards)
    table.sort(cards, function(a, b)
        return a:getNumericValue() < b:getNumericValue()
    end)
    return cards
end

-- Check for straight
local function isStraight(cards)
    if #cards < 5 then return false end
    local sorted = sortByValue(cards)
    
    -- Handle Ace-low straight (A,2,3,4,5)
    if sorted[#sorted]:getNumericValue() == 11 then  -- If we have an Ace
        local aceLowStraight = true
        for i = 1, 4 do
            if sorted[i]:getNumericValue() ~= i + 1 then
                aceLowStraight = false
                break
            end
        end
        if aceLowStraight then return true end
    end
    
    -- Check normal straight
    for i = 1, #sorted - 1 do
        if sorted[i+1]:getNumericValue() ~= sorted[i]:getNumericValue() + 1 then
            return false
        end
    end
    return true
end

-- Check for flush
local function isFlush(cards)
    if #cards < 5 then return false end
    local suit = cards[1].suit
    for _, card in ipairs(cards) do
        if card.suit ~= suit then
            return false
        end
    end
    return true
end

-- Count value occurrences
local function countValues(cards)
    local counts = {}
    for _, card in ipairs(cards) do
        local value = card:getNumericValue()
        counts[value] = (counts[value] or 0) + 1
    end
    return counts
end

-- Get cards that form a specific hand
local function getHandCards(cards, handType)
    local sorted = sortByValue(cards)
    local valueCounts = countValues(sorted)
    
    if handType == "FOUR_OF_A_KIND" then
        -- Find the value that appears 4 times
        local fourValue
        for value, count in pairs(valueCounts) do
            if count == 4 then
                fourValue = value
                break
            end
        end
        if fourValue then
            local handCards = {}
            for _, card in ipairs(sorted) do
                if card:getNumericValue() == fourValue then
                    table.insert(handCards, card)
                end
            end
            return handCards
        end
    elseif handType == "THREE_OF_A_KIND" then
        -- Find the value that appears 3 times
        local threeValue
        for value, count in pairs(valueCounts) do
            if count == 3 then
                threeValue = value
                break
            end
        end
        if threeValue then
            local handCards = {}
            for _, card in ipairs(sorted) do
                if card:getNumericValue() == threeValue then
                    table.insert(handCards, card)
                end
            end
            return handCards
        end
    elseif handType == "ONE_PAIR" or handType == "TWO_PAIR" then
        -- Find all pairs
        local pairValues = {}
        for value, count in pairs(valueCounts) do
            if count == 2 then
                table.insert(pairValues, value)
            end
        end
        
        -- Get cards that form the pairs
        local handCards = {}
        for _, card in ipairs(sorted) do
            for _, pairValue in ipairs(pairValues) do
                if card:getNumericValue() == pairValue then
                    table.insert(handCards, card)
                end
            end
        end
        return handCards
    end
    
    -- For other hands (Flush, Straight, etc.), all cards are part of the hand
    return cards
end

-- Helper function to find best subset of cards that form a hand
local function findBestHand(cards)
    if #cards < 1 then return nil end
    
    -- Try all possible combinations of cards for each hand type
    local function getCombinations(arr, k)
        local result = {}
        local function combine(start, combo)
            if #combo == k then
                table.insert(result, {unpack(combo)})
                return
            end
            for i = start, #arr do
                table.insert(combo, arr[i])
                combine(i + 1, combo)
                table.remove(combo)
            end
        end
        combine(1, {})
        return result
    end
    
    -- Check each possible combination for each hand type
    local bestHand = nil
    local bestScore = -1
    
    -- Try combinations of different sizes (2-5 cards)
    for size = math.min(5, #cards), 2, -1 do
        local combinations = getCombinations(cards, size)
        for _, combo in ipairs(combinations) do
            local sorted = sortByValue(combo)
            local straight = isStraight(sorted)
            local flush = isFlush(sorted)
            local valueCounts = countValues(sorted)
            
            -- Check each hand type in order of value
            if straight and flush and sorted[#sorted]:getNumericValue() == 11 then
                return {
                    handType = Effects.POKER_HANDS.ROYAL_FLUSH,
                    scoringCards = combo
                }
            elseif straight and flush then
                return {
                    handType = Effects.POKER_HANDS.STRAIGHT_FLUSH,
                    scoringCards = combo
                }
            end
            
            -- Check for Four of a Kind
            for value, count in pairs(valueCounts) do
                if count == 4 then
                    return {
                        handType = Effects.POKER_HANDS.FOUR_OF_A_KIND,
                        scoringCards = getHandCards(combo, "FOUR_OF_A_KIND")
                    }
                end
            end
            
            -- Check for Full House
            local hasThree = false
            local hasTwo = false
            for value, count in pairs(valueCounts) do
                if count == 3 then hasThree = true
                elseif count == 2 then hasTwo = true end
            end
            if hasThree and hasTwo then
                return {
                    handType = Effects.POKER_HANDS.FULL_HOUSE,
                    scoringCards = combo
                }
            end
            
            -- Check for Flush
            if flush then
                return {
                    handType = Effects.POKER_HANDS.FLUSH,
                    scoringCards = combo
                }
            end
            
            -- Check for Straight
            if straight then
                return {
                    handType = Effects.POKER_HANDS.STRAIGHT,
                    scoringCards = combo
                }
            end
            
            -- Check for Three of a Kind
            if hasThree then
                return {
                    handType = Effects.POKER_HANDS.THREE_OF_A_KIND,
                    scoringCards = getHandCards(combo, "THREE_OF_A_KIND")
                }
            end
            
            -- Check for Two Pair
            local pairCount = 0
            for value, count in pairs(valueCounts) do
                if count == 2 then pairCount = pairCount + 1 end
            end
            if pairCount == 2 then
                return {
                    handType = Effects.POKER_HANDS.TWO_PAIR,
                    scoringCards = getHandCards(combo, "TWO_PAIR")
                }
            end
            
            -- Check for One Pair
            if pairCount == 1 then
                return {
                    handType = Effects.POKER_HANDS.ONE_PAIR,
                    scoringCards = getHandCards(combo, "ONE_PAIR")
                }
            end
        end
    end
    
    -- If no poker hand found, find highest card
    local highestCard = nil
    local highestValue = -1
    
    for _, card in ipairs(cards) do
        local value = card:getNumericValue()
        if value > highestValue then
            highestValue = value
            highestCard = card
        end
    end
    
    -- Return high card result
    local highCardType = {
        name = Effects.POKER_HANDS.HIGH_CARD.name,
        baseScore = highestValue * 10,  -- Adjust base score based on card value
        multiplier = Effects.POKER_HANDS.HIGH_CARD.multiplier
    }
    
    return {
        handType = highCardType,
        scoringCards = {highestCard}
    }
end

-- Detect poker hand and return scoring info
function Effects.detectPokerHand(cards)
    if #cards < 1 then return nil end
    return findBestHand(cards)
end

-- Combination Detection
Effects.detectCombinations = function(playedCards, gameState)
    local combinations = {}
    
    -- Check for Perfect Date
    local hasAttention = false
    local hasGift = false
    local hasCompliment = false
    
    for _, card in ipairs(playedCards) do
        if card.type == "attention" then hasAttention = true end
        if card.type == "gift" then hasGift = true end
        if card.type == "compliment" then hasCompliment = true end
    end
    
    if hasAttention and hasGift and hasCompliment then
        table.insert(combinations, {
            name = "Perfect Date",
            multiplier = 3,
            description = "Activity + Gift + Compliment = Perfect Date!"
        })
    end
    
    -- Check for Social Media Spree
    local socialCount = 0
    for _, card in ipairs(playedCards) do
        if card.type == "social" then
            socialCount = socialCount + 1
        end
    end
    
    if socialCount >= 3 then
        table.insert(combinations, {
            name = "Social Media Spree",
            multiplier = socialCount * 0.5,
            description = string.format("%dx Social Media combo!", socialCount)
        })
    end
    
    -- Check for Gift Cascade
    local giftCards = {}
    for _, card in ipairs(playedCards) do
        if card.type == "gift" then
            table.insert(giftCards, card)
        end
    end
    
    table.sort(giftCards, function(a, b) return a.baseValue < b.baseValue end)
    
    if #giftCards >= 3 then
        local isGiftCascade = true
        for i = 2, #giftCards do
            if giftCards[i].baseValue <= giftCards[i-1].baseValue then
                isGiftCascade = false
                break
            end
        end
        
        if isGiftCascade then
            table.insert(combinations, {
                name = "Gift Cascade",
                multiplier = 2,
                description = "Escalating series of gifts!"
            })
        end
    end
    
    return combinations
end

-- Modifier Factory
Effects.createModifier = {
    highMaintenance = HighMaintenanceModifier.new,
    influencer = InfluencerModifier.new,
    yandere = YandereModifier.new,
    kuudere = KuudereModifier.new,
    boyfriendExperience = BoyfriendExperienceModifier.new,
    sugarDaddy = SugarDaddyModifier.new,
    socialMediaExpert = SocialMediaExpertModifier.new
}

return Effects 