local Card = require 'src.cards.card'

local Deck = {}
Deck.__index = Deck

-- Constants
Deck.HAND_SIZE = 7  -- Make HAND_SIZE accessible to other modules

-- Card rank order for sorting
Deck.RANK_ORDER = {
    [2] = 2, [3] = 3, [4] = 4, [5] = 5, [6] = 6, [7] = 7, [8] = 8, [9] = 9, [10] = 10,
    ["JACK"] = 11, ["QUEEN"] = 12, ["KING"] = 13, ["ACE"] = 14
}

-- Create a new deck
function Deck.new()
    local self = setmetatable({}, Deck)
    
    -- Initialize card collections
    self.drawPile = {}
    self.hand = {}
    self.playedCards = {}
    self.discardPile = {}
    
    return self
end

-- Initialize a standard 52-card deck
function Deck:initializeStandardDeck()
    -- Clear all collections
    self.drawPile = {}
    self.hand = {}
    self.playedCards = {}
    self.discardPile = {}
    
    -- Create all cards
    for _, suit in pairs(Card.SUITS) do
        -- Number cards
        for value = 2, 10 do
            table.insert(self.drawPile, Card.new(suit, value))
        end
        -- Face cards
        table.insert(self.drawPile, Card.new(suit, "JACK"))
        table.insert(self.drawPile, Card.new(suit, "QUEEN"))
        table.insert(self.drawPile, Card.new(suit, "KING"))
        table.insert(self.drawPile, Card.new(suit, "ACE"))
    end
    
    -- Shuffle the deck
    self:shuffle()
end

-- Shuffle the draw pile
function Deck:shuffle()
    local drawPileSize = #self.drawPile
    for i = drawPileSize, 2, -1 do
        local j = love.math.random(i)
        self.drawPile[i], self.drawPile[j] = self.drawPile[j], self.drawPile[i]
    end
end

-- Sort cards by rank
function Deck:sortHand()
    table.sort(self.hand, function(a, b)
        return Deck.RANK_ORDER[a.value] < Deck.RANK_ORDER[b.value]
    end)
end

-- Draw a specified number of cards
function Deck:drawCards(count)
    count = count or Deck.HAND_SIZE  -- Use class constant for default hand size
    local drawnCards = {}
    
    -- Draw up to count cards or as many as we can
    local actualCount = math.min(count, #self.drawPile)
    for i = 1, actualCount do
        local card = table.remove(self.drawPile)
        table.insert(self.hand, card)
        table.insert(drawnCards, card)
    end
    
    -- Sort hand by rank
    self:sortHand()
    
    return drawnCards
end

-- Play a card from hand
function Deck:playCard(cardId)
    -- Find and remove card from hand
    for i, card in ipairs(self.hand) do
        if card.id == cardId then
            table.remove(self.hand, i)
            table.insert(self.playedCards, card)
            break
        end
    end
end

-- Discard a card from hand
function Deck:discardCard(cardId)
    -- Find and remove card from hand
    for i, card in ipairs(self.hand) do
        if card.id == cardId then
            table.remove(self.hand, i)
            table.insert(self.discardPile, card)
            break
        end
    end
end

-- Draw cards until we have a full hand
function Deck:fillHand()
    local cardsNeeded = Deck.HAND_SIZE - #self.hand
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
    -- Return all cards to draw pile
    for _, card in ipairs(self.hand) do
        table.insert(self.drawPile, card)
    end
    for _, card in ipairs(self.playedCards) do
        table.insert(self.drawPile, card)
    end
    for _, card in ipairs(self.discardPile) do
        table.insert(self.drawPile, card)
    end
    
    -- Clear all other collections
    self.hand = {}
    self.playedCards = {}
    self.discardPile = {}
    
    -- Shuffle the deck
    self:shuffle()
end

-- Get current deck statistics
function Deck:getDeckStats()
    return {
        remainingInDeck = #self.drawPile,
        inHand = #self.hand,
        played = #self.playedCards,
        discarded = #self.discardPile
    }
end

-- Update all cards in the deck
function Deck:update(dt)
    -- Update all cards in all collections
    for _, card in ipairs(self.drawPile) do
        card:update(dt)
    end
    for _, card in ipairs(self.hand) do
        card:update(dt)
    end
    for _, card in ipairs(self.playedCards) do
        card:update(dt)
    end
    for _, card in ipairs(self.discardPile) do
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