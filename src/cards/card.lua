local Card = {}
Card.__index = Card

-- Import required modules
local BasicAudio = require("src.audio.basic_audio")

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
    self.baseY = 0  -- Base Y position (for animation)
    self.targetY = 0  -- Target Y position for animation
    self.baseX = 0  -- Base X position
    self.targetX = 0  -- Target X position
    self.liftHeight = 60  -- How high the card lifts when selected
    self.animationSpeed = 12  -- Animation speed multiplier
    self.isAnimating = false
    self.onAnimationComplete = nil  -- Callback for when animation completes
    self.animationType = nil  -- Current animation type (select, play, discard)
    self.targetRotation = 0  -- Target rotation for animations
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
    local isMoving = false
    
    if self.isDealing then
        local currentTime = love.timer.getTime()
        if currentTime >= self.animationStartTime then
            -- Play sound when animation starts, but only once
            if not self.soundPlayed then
                BasicAudio.playDealNote(self.value)
                self.soundPlayed = true
            end
            
            local elapsed = currentTime - self.animationStartTime
            local progress = math.min(elapsed / self.animationDuration, 1)
            
            -- Use easeOutQuad for smoother animation
            progress = -(progress * (progress - 2))
            
            self.x = self.startX + (self.targetX - self.startX) * progress
            self.y = self.startY + (self.targetY - self.startY) * progress
            
            if progress >= 1 then
                self.isDealing = false
                self.x = self.targetX
                self.y = self.targetY
            end
        end
    end
    
    -- Smooth position animation with easing
    if math.abs(self.x - self.targetX) > 0.5 then
        local dx = (self.targetX - self.x)
        local ease = self.animationType == "discard" and 0.85 or 0.92  -- More smoothing for discard
        self.x = self.x + dx * dt * self.animationSpeed * ease
        isMoving = true
    else
        self.x = self.targetX
    end
    
    if math.abs(self.y - self.targetY) > 0.5 then
        local dy = (self.targetY - self.y)
        local ease = self.animationType == "discard" and 0.85 or 0.92
        self.y = self.y + dy * dt * self.animationSpeed * ease
        isMoving = true
    else
        self.y = self.targetY
    end
    
    -- Enhanced rotation animation with easing
    if math.abs(self.rotation - self.targetRotation) > 0.01 then
        local dr = (self.targetRotation - self.rotation)
        -- Use different easing for different animation types
        local ease = self.animationType == "discard" and 0.8 or 0.92
        self.rotation = self.rotation + dr * dt * self.animationSpeed * ease
        isMoving = true
    else
        self.rotation = self.targetRotation
    end
    
    -- Check if animation is complete
    if self.isAnimating and not isMoving then
        self.isAnimating = false
        if self.onAnimationComplete then
            self.onAnimationComplete()
            self.onAnimationComplete = nil
        end
    end
end

-- Draw the card
function Card:draw()
    -- Save current graphics state
    love.graphics.push()
    
    -- Apply transformations relative to card center
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)
    
    -- Draw card shadow (offset slightly)
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.rectangle("fill", -self.width/2 + 4, -self.height/2 + 4, self.width, self.height, 8, 8)
    
    -- Draw card background
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", -self.width/2, -self.height/2, self.width, self.height, 8, 8)
    
    -- Draw card border
    if self.highlighted then
        love.graphics.setColor(1, 0.4, 0.7, 1)
        love.graphics.setLineWidth(3)
    else
        love.graphics.setColor(1, 0.4, 0.7, 0.7)
        love.graphics.setLineWidth(2)
    end
    love.graphics.rectangle("line", -self.width/2, -self.height/2, self.width, self.height, 8, 8)
    
    -- Draw card content
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw card name
    love.graphics.printf(self:getDisplayName(), 
        -self.width/2, -self.height/2 + 10, 
        self.width, "center")
    
    -- Draw value
    love.graphics.printf(tostring(self.value), 
        -self.width/2, -self.height/2 + 35, 
        self.width, "center")
    
    -- Draw description
    love.graphics.printf(self:getDescription(), 
        -self.width/2, self.height/2 - 50, 
        self.width, "center")
    
    -- Restore graphics state
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
        
        -- Only add hover effect if not selected
        if not self.highlighted then
            self.targetScale = 1.05  -- Subtle hover effect
        end
        return true
    end
    
    -- Reset hover effect if not highlighted
    if not self.highlighted then
        self.targetScale = 1.0  -- Normal size
    end
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
    self.x = x
    self.y = y
    self.baseX = self.x
    self.baseY = y
    self.targetX = self.x
    self.targetY = y
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
        self.targetY = self.baseY - self.liftHeight  -- Lift card up
    else
        self.targetY = self.baseY  -- Return to base position
    end
    self.isAnimating = true
    self.animationType = "select"
end

-- Animate to played area
function Card:animateToPlay(targetX, targetY, callback)
    self.targetX = targetX
    self.targetY = targetY
    self.targetRotation = 0
    self.isAnimating = true
    self.animationType = "play"
    self.onAnimationComplete = callback
end

-- Animate to discard
function Card:animateToDiscard(callback)
    -- Animate off to the left and rotate more dramatically
    self.targetX = -200
    self.targetY = love.graphics.getHeight() / 2
    self.targetRotation = -math.pi * 2  -- Full 360 degree spin
    self.animationSpeed = 8  -- Slower animation for more satisfying motion
    self.isAnimating = true
    self.animationType = "discard"
    
    -- Play card slide sound
    BasicAudio.playCardSlide()
    
    self.onAnimationComplete = callback
end

-- Add new function for dealing animation
function Card:animateDealing(targetX, targetY, delay)
    self.isDealing = true
    self.animationStartTime = love.timer.getTime() + delay
    self.startX = self.x
    self.startY = self.y
    self.targetX = targetX
    self.targetY = targetY
    self.animationDuration = 0.2  -- Reduced from 0.3 to 0.2 seconds
    self.soundPlayed = false  -- Add flag for sound playing
end

return Card 