local Card = require 'src.cards.card'

local Deck = {}
Deck.__index = Deck

-- Constants
local HAND_SIZE = 7  -- Default hand size

-- Create a new deck
function Deck.new()
    local self = setmetatable({}, Deck)
    
    self.cards = {}         -- All cards in the deck
    self.drawPile = {}      -- Cards available to draw
    self.discardPile = {}   -- Cards that were discarded this round
    self.playedCards = {}   -- Cards currently in play
    self.hand = {}          -- Cards in hand
    self.usedThisRound = {} -- Cards that were played this round (for round tracking)
    
    return self
end

-- Initialize a standard 52-card deck
function Deck:initializeStandardDeck()
    -- Clear existing cards
    self.cards = {}
    
    -- Add numbered cards (2-10)
    for value = 2, 10 do
        table.insert(self.cards, Card.new(Card.SUITS.DATES, value))
        table.insert(self.cards, Card.new(Card.SUITS.GIFTS, value))
        table.insert(self.cards, Card.new(Card.SUITS.COMPLIMENTS, value))
        table.insert(self.cards, Card.new(Card.SUITS.SOCIAL, value))
    end
    
    -- Add face cards and aces
    local faceCards = {"JACK", "QUEEN", "KING", "ACE"}
    for _, value in ipairs(faceCards) do
        table.insert(self.cards, Card.new(Card.SUITS.DATES, value))
        table.insert(self.cards, Card.new(Card.SUITS.GIFTS, value))
        table.insert(self.cards, Card.new(Card.SUITS.COMPLIMENTS, value))
        table.insert(self.cards, Card.new(Card.SUITS.SOCIAL, value))
    end
    
    -- Initialize draw pile with all cards
    self.drawPile = {}
    for _, card in ipairs(self.cards) do
        table.insert(self.drawPile, card)
    end
    
    self:shuffle()
end

-- Shuffle the draw pile
function Deck:shuffle()
    local cards = self.drawPile
    for i = #cards, 2, -1 do
        local j = love.math.random(i)
        cards[i], cards[j] = cards[j], cards[i]
    end
end

-- Draw a specified number of cards
function Deck:drawCards(count)
    count = count or HAND_SIZE  -- Use default hand size if not specified
    local drawnCards = {}
    
    -- Draw up to count cards or as many as we can
    local actualCount = math.min(count, #self.drawPile)
    for i = 1, actualCount do
        local card = table.remove(self.drawPile)
        table.insert(self.hand, card)
        table.insert(drawnCards, card)
    end
    
    return drawnCards
end

-- Play a card from hand
function Deck:playCard(cardId)
    for i, card in ipairs(self.hand) do
        if card.id == cardId then
            table.remove(self.hand, i)
            table.insert(self.playedCards, card)
            table.insert(self.usedThisRound, card)
            return card
        end
    end
    return nil
end

-- Discard a card from hand
function Deck:discardCard(cardId)
    for i, card in ipairs(self.hand) do
        if card.id == cardId then
            table.remove(self.hand, i)
            table.insert(self.discardPile, card)
            table.insert(self.usedThisRound, card)
            return card
        end
    end
    return nil
end

-- Draw cards until we have a full hand
function Deck:fillHand()
    local cardsNeeded = HAND_SIZE - #self.hand
    if cardsNeeded > 0 and #self.drawPile > 0 then
        return self:drawCards(cardsNeeded)
    end
    return {}
end

-- End turn: move played cards to used pile
function Deck:endTurn()
    -- Move played cards to used pile (but not to discard - they're played, not discarded)
    for _, card in ipairs(self.playedCards) do
        table.insert(self.usedThisRound, card)
    end
    self.playedCards = {}
end

-- Start a new round: reset all piles and shuffle
function Deck:startNewRound()
    -- Reset all piles
    self.drawPile = {}
    self.discardPile = {}
    self.playedCards = {}
    self.hand = {}
    self.usedThisRound = {}
    
    -- Restore all cards to draw pile
    for _, card in ipairs(self.cards) do
        table.insert(self.drawPile, card)
    end
    
    -- Shuffle the deck
    self:shuffle()
    
    -- Draw initial hand
    return self:drawCards(HAND_SIZE)
end

-- Get current deck statistics
function Deck:getDeckStats()
    return {
        totalCards = #self.cards,
        remainingInDeck = #self.drawPile,  -- Only count cards still in draw pile
        inHand = #self.hand,
        discarded = #self.discardPile,
        played = #self.usedThisRound - #self.discardPile,  -- Played cards (excluding discards)
        usedThisRound = #self.usedThisRound
    }
end

-- Update all cards in the deck
function Deck:update(dt)
    for _, card in ipairs(self.hand) do
        card:update(dt)
    end
    
    for _, card in ipairs(self.playedCards) do
        card:update(dt)
    end
end

-- Draw the deck state (for debugging)
function Deck:draw()
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.print("Deck: " .. #self.cards, 10, 50)
    love.graphics.print("Discard: " .. #self.discardPile, 10, 70)
    love.graphics.print("Hand: " .. #self.hand, 10, 90)
    love.graphics.print("Played: " .. #self.playedCards, 10, 110)
end

return Deck 