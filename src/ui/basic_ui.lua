local Card = require("src.cards.card")
local Corruption = require("src.waifu.corruption")

local BasicUI = {}

-- Colors
local COLORS = {
    BACKGROUND = {0.1, 0.1, 0.1, 1},
    CARD_BG = {0.2, 0.2, 0.2, 1},
    CARD_BORDER = {1, 0.4, 0.7, 1},
    TEXT = {1, 1, 1, 1},
    BUTTON = {0.3, 0.3, 0.3, 1},
    BUTTON_HOVER = {0.4, 0.4, 0.4, 1},
    BUTTON_DISABLED = {0.2, 0.2, 0.2, 0.5},
    SUIT_COLORS = {
        [Card.SUITS.DATES] = {1, 0.4, 0.7, 1},      -- Pink
        [Card.SUITS.GIFTS] = {0.4, 0.7, 1, 1},      -- Blue
        [Card.SUITS.COMPLIMENTS] = {0.7, 1, 0.4, 1}, -- Green
        [Card.SUITS.SOCIAL] = {1, 0.7, 0.4, 1}      -- Orange
    }
}

-- Suit symbols
local SUIT_SYMBOLS = {
    [Card.SUITS.DATES] = "💝",
    [Card.SUITS.GIFTS] = "🎁",
    [Card.SUITS.COMPLIMENTS] = "💕",
    [Card.SUITS.SOCIAL] = "📱"
}

-- Draw a basic card
function BasicUI.drawCard(card, x, y, width, height, isHighlighted)
    -- Card shadow (more pronounced when lifted)
    local shadowOffset = isHighlighted and 8 or 2
    local shadowAlpha = isHighlighted and 0.4 or 0.2
    love.graphics.setColor(0, 0, 0, shadowAlpha)
    love.graphics.rectangle("fill", x + shadowOffset, y + shadowOffset, width, height, 8, 8)
    
    -- Card background
    love.graphics.setColor(COLORS.CARD_BG)
    love.graphics.rectangle("fill", x, y, width, height, 8, 8)
    
    -- Border
    love.graphics.setColor(COLORS.SUIT_COLORS[card.suit])
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, 8, 8)
    
    -- Card content
    love.graphics.setColor(COLORS.TEXT)
    local symbol = SUIT_SYMBOLS[card.suit]
    
    -- Use smaller font for card value
    local smallFont = love.graphics.newFont(14)
    local normalFont = love.graphics.newFont(12)
    local oldFont = love.graphics.getFont()
    
    -- Draw value and suit symbol
    love.graphics.setFont(smallFont)
    love.graphics.printf(tostring(card.value), x, y + 5, width, "center")
    love.graphics.printf(symbol, x, y + height/2 - 15, width, "center")
    
    -- Draw card description with smaller font
    love.graphics.setFont(normalFont)
    love.graphics.printf(card:getDescription(), x, y + height - 30, width, "center")
    
    love.graphics.setFont(oldFont)
    love.graphics.setLineWidth(1) -- Reset line width
end

-- Draw the play area
function BasicUI.drawPlayArea(x, y, width, height)
    love.graphics.setColor(0.15, 0.15, 0.15, 1)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("line", x, y, width, height)
end

-- Draw corruption levels with smaller font
function BasicUI.drawCorruption(corruption, x, y)
    love.graphics.setColor(COLORS.TEXT)
    local smallFont = love.graphics.newFont(12)
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(smallFont)
    
    local lineHeight = 25
    local currentY = y
    
    for suit, value in pairs(corruption.suitValues) do
        local level = Corruption.getLevel(value)
        if level > 0 then
            local symbol = SUIT_SYMBOLS[suit]
            local multiplier = corruption:getMultiplier(suit)
            love.graphics.setColor(COLORS.SUIT_COLORS[suit])
            love.graphics.printf(
                string.format("%s %.1fx", symbol, multiplier),
                x, currentY, 150, "left"
            )
            currentY = currentY + lineHeight
        end
    end
    
    love.graphics.setFont(oldFont)
end

-- Draw stats and game info with smaller font
function BasicUI.drawStats(score, handsRemaining, deckStats, x, y)
    love.graphics.setColor(COLORS.TEXT)
    local smallFont = love.graphics.newFont(12)
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(smallFont)
    
    local lineHeight = 20
    local currentY = y
    
    -- Score and hands
    love.graphics.printf(string.format("Score: %d", score), x, currentY, 150, "left")
    currentY = currentY + lineHeight
    love.graphics.printf(string.format("🎲 %d hands left", handsRemaining), x, currentY, 150, "left")
    currentY = currentY + lineHeight * 1.5
    
    -- Deck stats
    love.graphics.printf(string.format("Cards in deck: %d", deckStats.remainingInDeck), x, currentY, 150, "left")
    currentY = currentY + lineHeight
    
    if deckStats.usedThisRound > 0 then
        love.graphics.printf(string.format("Used: %d", deckStats.usedThisRound), x, currentY, 150, "left")
        currentY = currentY + lineHeight
    end
    
    if deckStats.discarded > 0 then
        love.graphics.printf(string.format("Discarded: %d", deckStats.discarded), x, currentY, 150, "left")
    end
    
    love.graphics.setFont(oldFont)
end

-- Draw messages with better visibility and smaller font
function BasicUI.drawMessages(messages, x, y, width)
    local smallFont = love.graphics.newFont(12)
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(smallFont)
    
    -- Draw semi-transparent background for better readability
    love.graphics.setColor(0, 0, 0, 0.7)
    local messageHeight = 30
    love.graphics.rectangle("fill", x, y - 5, width, #messages * messageHeight + 10)
    
    love.graphics.setColor(COLORS.TEXT)
    local currentY = y
    
    for _, message in ipairs(messages) do
        love.graphics.printf(message.description, x + 20, currentY, width - 40, "center")
        currentY = currentY + messageHeight
    end
    
    love.graphics.setFont(oldFont)
end

-- Draw a basic waifu representation
function BasicUI.drawWaifu(corruption, x, y, size)
    -- Base circle for waifu
    love.graphics.setColor(1, 0.8, 0.8, 1)
    love.graphics.circle("fill", x, y, size)
    love.graphics.setColor(1, 0.4, 0.7, 1)
    love.graphics.circle("line", x, y, size)
    
    -- Draw corruption indicators around the waifu
    local angle = 0
    for suit, value in pairs(corruption.suitValues) do
        local level = Corruption.getLevel(value)
        if level > 0 then
            local symbol = SUIT_SYMBOLS[suit]
            love.graphics.setColor(COLORS.SUIT_COLORS[suit])
            local symbol_x = x + math.cos(angle) * (size + 20)
            local symbol_y = y + math.sin(angle) * (size + 20)
            love.graphics.printf(symbol, symbol_x - 15, symbol_y - 15, 30, "center")
            angle = angle + math.pi/2
        end
    end
end

-- Check if mouse is over a button
function BasicUI.isMouseOverButton(x, y, width, height)
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= x + width and my >= y and my <= y + height
end

-- Get button positions (for hit testing)
function BasicUI.getButtonPositions()
    local buttonWidth = 160
    local buttonHeight = 35
    local spacing = 10
    local rightMargin = 20
    local startX = love.graphics.getWidth() - buttonWidth - rightMargin
    local startY = love.graphics.getHeight() - 200
    
    return {
        play = {x = startX, y = startY, width = buttonWidth, height = buttonHeight},
        discard = {x = startX, y = startY + buttonHeight + spacing, width = buttonWidth, height = buttonHeight}
    }
end

-- Draw action buttons with smaller font
function BasicUI.drawActionButtons(x, y, width, height, canPlay, canDiscard)
    local spacing = 10
    local buttonWidth = width
    local smallFont = love.graphics.newFont(12)
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(smallFont)
    
    -- Play Hand button
    local playButtonColor = canPlay and COLORS.BUTTON or COLORS.BUTTON_DISABLED
    if canPlay and BasicUI.isMouseOverButton(x, y, buttonWidth, height) then
        playButtonColor = COLORS.BUTTON_HOVER
    end
    love.graphics.setColor(playButtonColor)
    love.graphics.rectangle("fill", x, y, buttonWidth, height, 8, 8)
    love.graphics.setColor(COLORS.TEXT)
    love.graphics.printf("Play Hand (Space)", x, y + height/2 - 8, buttonWidth, "center")
    
    -- Discard button
    local discardButtonColor = canDiscard and COLORS.BUTTON or COLORS.BUTTON_DISABLED
    if canDiscard and BasicUI.isMouseOverButton(x, y + height + spacing, buttonWidth, height) then
        discardButtonColor = COLORS.BUTTON_HOVER
    end
    love.graphics.setColor(discardButtonColor)
    love.graphics.rectangle("fill", x, y + height + spacing, buttonWidth, height, 8, 8)
    love.graphics.setColor(COLORS.TEXT)
    love.graphics.printf("Discard Selected (D)", x, y + (height + spacing) + height/2 - 8, buttonWidth, "center")
    
    love.graphics.setFont(oldFont)
end

return BasicUI 