local Card = {}
Card.__index = Card

-- Card suits
Card.SUITS = {
    DATES = "dates",
    GIFTS = "gifts",
    COMPLIMENTS = "compliments",
    SOCIAL = "social"
}

-- Card values
Card.VALUES = {
    TWO = 2,
    THREE = 3,
    FOUR = 4,
    FIVE = 5,
    SIX = 6,
    SEVEN = 7,
    EIGHT = 8,
    NINE = 9,
    TEN = 10,
    JACK = 10,
    QUEEN = 10,
    KING = 10,
    ACE = 11
}

-- Create a new card
function Card.new(suit, value)
    local self = setmetatable({}, Card)
    
    self.suit = suit
    self.value = value
    self.id = suit .. "-" .. value
    
    -- Visual properties
    self.x = 0
    self.y = 0
    self.width = 120
    self.height = 160
    self.scale = 1
    self.rotation = 0
    self.dragging = false
    self.dragOffsetX = 0
    self.dragOffsetY = 0
    self.highlighted = false
    self.hoverScale = 1.0  -- Scale for hover effect
    self.targetScale = 1.0  -- Target scale for animations
    
    return self
end

-- Get the display name for the card
function Card:getDisplayName()
    local valueNames = {
        [2] = "Two",
        [3] = "Three",
        [4] = "Four",
        [5] = "Five",
        [6] = "Six",
        [7] = "Seven",
        [8] = "Eight",
        [9] = "Nine",
        [10] = "Ten",
        ["JACK"] = "Jack",
        ["QUEEN"] = "Queen",
        ["KING"] = "King",
        ["ACE"] = "Ace"
    }
    
    local suitNames = {
        [Card.SUITS.DATES] = "Dates",
        [Card.SUITS.GIFTS] = "Gifts",
        [Card.SUITS.COMPLIMENTS] = "Compliments",
        [Card.SUITS.SOCIAL] = "Social Media"
    }
    
    return valueNames[self.value] .. " of " .. suitNames[self.suit]
end

-- Get card description based on suit and value
function Card:getDescription()
    local descriptions = {
        [Card.SUITS.DATES] = {
            base = "Take your waifu on a date",
            ["JACK"] = "Take your waifu to a casual cafe",
            ["QUEEN"] = "Plan a romantic dinner date",
            ["KING"] = "Organize a full day of activities",
            ["ACE"] = "Create an unforgettable date experience"
        },
        [Card.SUITS.GIFTS] = {
            base = "Give a gift to your waifu",
            ["JACK"] = "Buy her favorite snacks",
            ["QUEEN"] = "Get her something she mentioned",
            ["KING"] = "Purchase that item she's been wanting",
            ["ACE"] = "Surprise her with a perfect gift"
        },
        [Card.SUITS.COMPLIMENTS] = {
            base = "Compliment your waifu",
            ["JACK"] = "Notice her new hairstyle",
            ["QUEEN"] = "Praise her achievements",
            ["KING"] = "Write her a heartfelt letter",
            ["ACE"] = "Make her feel truly special"
        },
        [Card.SUITS.SOCIAL] = {
            base = "Share your relationship on social media",
            ["JACK"] = "Post a cute photo together",
            ["QUEEN"] = "Share your date experience",
            ["KING"] = "Make a relationship milestone post",
            ["ACE"] = "Declare your love publicly"
        }
    }
    
    if type(self.value) == "number" then
        return descriptions[self.suit].base
    else
        return descriptions[self.suit][self.value]
    end
end

-- Get the numeric value of the card
function Card:getNumericValue()
    if type(self.value) == "number" then
        return self.value
    else
        return Card.VALUES[self.value] or 0
    end
end

-- Calculate final value with corruption multiplier
function Card:calculateValue(gameState)
    local baseValue = self:getNumericValue()
    local multiplier = gameState.corruption:getMultiplier(self.suit)
    return baseValue * multiplier
end

-- Update card state
function Card:update(dt)
    -- Smooth scale animation
    if math.abs(self.scale - self.targetScale) > 0.01 then
        self.scale = self.scale + (self.targetScale - self.scale) * dt * 10
    else
        self.scale = self.targetScale
    end
end

-- Draw the card
function Card:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)
    love.graphics.scale(self.scale)
    
    -- Draw card shadow
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.rectangle("fill", -self.width/2 + 2, -self.height/2 + 2, self.width, self.height, 8, 8)
    
    -- Draw card background
    if self.highlighted then
        love.graphics.setColor(1, 0.8, 0.8, 1)
    else
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
    end
    love.graphics.rectangle("fill", -self.width/2, -self.height/2, self.width, self.height, 8, 8)
    
    -- Draw card border
    if self.highlighted then
        love.graphics.setColor(1, 0.4, 0.7, 1)
        love.graphics.setLineWidth(3)  -- Thicker border when selected
    else
        love.graphics.setColor(1, 0.4, 0.7, 0.7)
        love.graphics.setLineWidth(2)
    end
    love.graphics.rectangle("line", -self.width/2, -self.height/2, self.width, self.height, 8, 8)
    
    -- Draw card content
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw card name
    love.graphics.printf(self:getDisplayName(), -self.width/2 + 10, -self.height/2 + 10, self.width - 20, "center")
    
    -- Draw value
    love.graphics.printf(tostring(self.value), -self.width/2 + 10, -self.height/2 + 35, self.width - 20, "center")
    
    -- Draw description
    love.graphics.printf(self:getDescription(), -self.width/2 + 10, self.height/2 - 50, self.width - 20, "center")
    
    love.graphics.pop()
end

-- Check if a point is inside the card's hitbox
function Card:containsPoint(x, y)
    -- Get card's screen-space bounds
    local left = self.x - (self.width * self.scale) / 2
    local right = self.x + (self.width * self.scale) / 2
    local top = self.y - (self.height * self.scale) / 2
    local bottom = self.y + (self.height * self.scale) / 2
    
    -- Add small padding for easier selection
    local padding = 10
    left = left - padding
    right = right + padding
    top = top - padding
    bottom = bottom + padding
    
    -- Check if point is within bounds
    if x >= left and x <= right and y >= top and y <= bottom then
        -- For overlapping cards, be more precise about the right edge
        if x > self.x then  -- Right half of card
            if x > right - 40 then  -- Increased overlap area slightly
                return false
            end
        end
        
        self.targetScale = 1.1  -- Hover effect
        return true
    end
    
    self.targetScale = 1.0  -- Normal size
    return false
end

-- Start dragging the card
function Card:startDrag(x, y)
    self.dragging = true
    self.dragOffsetX = self.x - x
    self.dragOffsetY = self.y - y
end

-- Update card position while dragging
function Card:drag(x, y)
    if self.dragging then
        self.x = x + self.dragOffsetX
        self.y = y + self.dragOffsetY
    end
end

-- Stop dragging the card
function Card:stopDrag()
    self.dragging = false
end

-- Set card position (centered)
function Card:setPosition(x, y)
    self.x = x + (self.width * self.scale) / 2  -- Center the card on the given x position
    self.y = y
end

-- Set card scale
function Card:setScale(scale)
    self.scale = scale
end

-- Set card rotation
function Card:setRotation(rotation)
    self.rotation = rotation
end

-- Highlight or unhighlight the card
function Card:setHighlight(highlighted)
    self.highlighted = highlighted
    if highlighted then
        self.targetScale = 1.1  -- Enlarge when selected
    else
        self.targetScale = 1.0  -- Normal size when deselected
    end
end

return Card 