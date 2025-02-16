local Card = require("src.cards.card")
local Deck = require("src.cards.deck")
local Effects = require("src.cards.effects")
local Corruption = require("src.waifu.corruption")
local RunManager = require("src.waifu.run_manager")
local BasicUI = require("src.ui.basic_ui")
local BasicAudio = require("src.audio.basic_audio")

local GameState = {}
GameState.__index = GameState

function GameState.new()
    local self = setmetatable({}, GameState)
    
    -- Initialize core systems
    self.deck = nil  -- Will be initialized in enter()
    self.corruption = nil  -- Will be initialized in enter()
    self.runManager = nil  -- Will be initialized in enter()
    
    -- Game state
    self.selectedCards = {}
    self.currentScore = 0
    self.messages = {}
    self.gameOver = false
    
    -- Hand tracking
    self.handsRemaining = 3  -- Start with 3 hands per round
    self.discardsRemaining = 3  -- 3 discard opportunities per round
    self.maxCardsPerDiscard = 5  -- Maximum 5 cards per discard
    
    -- Round summary state
    self.showingSummary = false
    self.lastRoundScore = 0
    self.readyForNextRound = false
    
    -- Transition state
    self.transitionTimer = 0
    self.isTransitioning = false
    self.pendingAction = nil  -- "draw" or "endRound" or "showSummary"
    
    -- UI state
    self.playArea = {
        x = 300,            -- Moved left to make room
        y = 100,            -- Moved up to make room
        width = 800,        -- Widened for more cards
        height = 250        -- Adjusted for better proportions
    }
    
    return self
end

function GameState:enter()
    -- Initialize or reset core systems
    self.deck = Deck.new()
    self.corruption = Corruption.new()
    self.runManager = RunManager.new()
    
    -- Reset game state
    self.selectedCards = {}
    self.currentScore = 0
    self.messages = {}
    self.gameOver = false
    
    -- Initialize audio
    BasicAudio.init()
    
    -- Initialize deck
    self.deck:initializeStandardDeck()
    
    -- Start first round
    self:startNewRound()
end

function GameState:exit()
    -- Clean up any resources
    self.selectedCards = {}
    self.messages = {}
    
    -- Stop any ongoing sounds
    -- BasicAudio.stopAll()
end

function GameState:startNewRound()
    -- Reset deck and draw initial hand
    self.deck:startNewRound()
    
    -- Play round start sound
    BasicAudio.play("ROUND_START")
    
    -- Reset round state
    self.selectedCards = {}
    self.currentScore = 0
    
    -- Reset hand and discard tracking
    self.handsRemaining = 3  -- Reset to 3 hands per round
    self.discardsRemaining = 3  -- Reset to 3 discards per round
    
    -- Add round start message
    local state = self.runManager:getState()
    table.insert(self.messages, {
        text = string.format("Stage %d - Round %d (Target: %d points)",
            state.stage, state.round, state.threshold),
        timer = 5
    })
    
    -- Set a timer to deal cards after a short delay
    self.isTransitioning = true
    self.transitionTimer = 0.5  -- Half second delay before dealing
    self.pendingAction = "dealInitialHand"
end

function GameState:dealInitialHand()
    -- Fill initial hand with animation
    self:fillHand()
end

function GameState:playSelectedCards()
    if #self.selectedCards > 0 then
        -- Detect poker hand
        local handInfo = Effects.detectPokerHand(self.selectedCards)
        if not handInfo then
            table.insert(self.messages, {
                text = "Not a valid poker hand!",
                timer = 2
            })
            return
        end
        
        -- Play hand-specific chord
        BasicAudio.playHandChord(handInfo.handType.name)
        
        -- Decrement hands remaining when a valid hand is played
        self.handsRemaining = self.handsRemaining - 1
        
        -- Check if we've run out of hands
        if self.handsRemaining < 0 then
            self.gameOver = true
            table.insert(self.messages, {
                text = "Game Over - Out of hands!",
                timer = -1  -- Permanent message
            })
            return
        end
        
        -- Get base score and multiplier from the hand type
        local baseScore = handInfo.handType.baseScore
        local handMultiplier = handInfo.handType.multiplier
        
        -- Track corruption multipliers for each suit in the scoring cards
        local suitMultipliers = {}
        for _, card in ipairs(handInfo.scoringCards) do
            if not suitMultipliers[card.suit] then
                suitMultipliers[card.suit] = self.corruption:getMultiplier(card.suit)
            end
        end
        
        -- Calculate final score
        local score = baseScore
        local totalMultiplier = handMultiplier
        
        -- Apply corruption multipliers for each suit used in the scoring hand
        for suit, multiplier in pairs(suitMultipliers) do
            totalMultiplier = totalMultiplier * multiplier
            
            -- Track corruption for each suit used in the scoring hand
            self.corruption:trackHand({
                suit = suit,
                value = baseScore,  -- Track the base score
                multiplier = handMultiplier,  -- Track the hand multiplier
                isValid = true
            })
        end
        
        -- Apply total multiplier
        score = score * totalMultiplier
        
        -- Update score and check against threshold
        self.currentScore = self.currentScore + score
        local result = self.runManager:checkScore(self.currentScore)
        
        -- Build detailed score message
        local scoreMsg = string.format("%s! Base: %d × Hand: %dx", 
            handInfo.handType.name, baseScore, handMultiplier)
        
        -- Add corruption multipliers to message if any were applied
        if next(suitMultipliers) then
            scoreMsg = scoreMsg .. " × Corruption:"
            for suit, mult in pairs(suitMultipliers) do
                scoreMsg = scoreMsg .. string.format(" %s(%.1fx)", suit, mult)
            end
        end
        
        scoreMsg = scoreMsg .. string.format(" = %d! (Total: %d/%d)",
            score, result.score, result.threshold)
        
        -- Add score message
        table.insert(self.messages, {
            text = scoreMsg,
            timer = 3
        })
        
        -- Add hands remaining message
        table.insert(self.messages, {
            text = string.format("Hands remaining: %d", self.handsRemaining),
            timer = 2
        })
        
        -- Process bonuses
        for _, bonus in ipairs(result.bonuses) do
            table.insert(self.messages, {
                text = string.format("BONUS! Exceeded threshold by %dx!",
                    bonus.multiplier),
                timer = 3
            })
        end
        
        -- Animate cards to played area
        local cardsToMove = {}
        for i, card in ipairs(self.selectedCards) do
            table.insert(cardsToMove, card)
        end
        
        -- Clear selected cards immediately to prevent double-playing
        self.selectedCards = {}
        
        -- Start animations
        local cardsAnimating = #cardsToMove
        for i, card in ipairs(cardsToMove) do
            local targetX = self.playArea.x + 50 + (i-1) * 130 + card.width/2
            local targetY = self.playArea.y + 50 + card.height/2
            
            card:animateToPlay(targetX, targetY, function()
                cardsAnimating = cardsAnimating - 1
                if cardsAnimating == 0 then
                    -- All cards finished animating
                    for _, c in ipairs(cardsToMove) do
                        self.deck:playCard(c.id)
                    end
                    
                    -- Start transition timer
                    self.isTransitioning = true
                    self.transitionTimer = 1.5
                    
                    -- Set pending action
                    if result.cleared then
                        self.pendingAction = "endRound"
                    else
                        self.pendingAction = "draw"
                    end
                end
            end)
        end
        
        -- Check for corruption level changes
        self:checkCorruptionChange(self.corruption.suitValues, self.corruption.suitValues)
    end
end

function GameState:discardSelectedCards()
    if #self.selectedCards > 0 then
        -- Check discard limits
        if self.discardsRemaining <= 0 then
            table.insert(self.messages, {
                text = "No discards remaining this round!",
                timer = 2
            })
            return
        end
        
        -- Play discard sound effect
        BasicAudio.play("CARD_DISCARD")
        
        if #self.selectedCards > self.maxCardsPerDiscard then
            table.insert(self.messages, {
                text = string.format("Can only discard up to %d cards at once!", self.maxCardsPerDiscard),
                timer = 2
            })
            return
        end
        
        -- Store cards to animate
        local cardsToDiscard = {}
        for _, card in ipairs(self.selectedCards) do
            table.insert(cardsToDiscard, card)
        end
        
        -- Clear selected cards immediately
        self.selectedCards = {}
        
        -- Start animations
        local cardsAnimating = #cardsToDiscard
        for _, card in ipairs(cardsToDiscard) do
            card:animateToDiscard(function()
                cardsAnimating = cardsAnimating - 1
                if cardsAnimating == 0 then
                    -- All cards finished animating
                    for _, c in ipairs(cardsToDiscard) do
                        self.deck:discardCard(c.id)
                    end
                    
                    -- Start transition timer
                    self.isTransitioning = true
                    self.transitionTimer = 0.5
                    
                    -- Update hand state
                    if #self.deck.hand == 0 then
                        self.handsRemaining = self.handsRemaining - 1
                        if self.handsRemaining < 0 then
                            self.gameOver = true
                            table.insert(self.messages, {
                                text = "Game Over - Out of hands!",
                                timer = -1
                            })
                            return
                        end
                        
                        if self.handsRemaining <= 0 then
                            self.pendingAction = "endRound"
                        else
                            self.pendingAction = "draw"
                        end
                    else
                        self.pendingAction = "draw"
                    end
                    
                    -- Decrement discards remaining
                    self.discardsRemaining = self.discardsRemaining - 1
                    
                    -- Add discard message
                    table.insert(self.messages, {
                        text = string.format("Cards discarded (%d discards remaining)", self.discardsRemaining),
                        timer = 2
                    })
                end
            end)
        end
    end
end

function GameState:endRound()
    -- Store the score for summary screen
    self.lastRoundScore = self.currentScore
    
    -- Process round end
    local success, message = self.runManager:nextRound()
    
    if not success then
        -- Game over - breakup
        self.gameOver = true
        BasicAudio.play("GAME_OVER")
        table.insert(self.messages, {
            text = message,
            timer = -1  -- Permanent message
        })
    else
        -- Show round summary instead of immediately starting next round
        self.showingSummary = true
        self.readyForNextRound = true
        
        -- Check if we advanced to next stage (level up)
        if self.runManager:getState().round == 1 then
            BasicAudio.play("LEVEL_UP")
        end
    end
end

function GameState:startNextRound()
    self.showingSummary = false
    self.readyForNextRound = false
    self:startNewRound()
end

function GameState:update(dt)
    -- Update deck animations
    self.deck:update(dt)
    
    -- Update message timers
    for i = #self.messages, 1, -1 do
        local msg = self.messages[i]
        if msg.timer > 0 then
            msg.timer = msg.timer - dt
            if msg.timer <= 0 then
                table.remove(self.messages, i)
            end
        end
    end
    
    -- Handle transition timer
    if self.isTransitioning then
        self.transitionTimer = self.transitionTimer - dt
        if self.transitionTimer <= 0 then
            self.isTransitioning = false
            
            -- Clear played cards from display
            self.deck.playedCards = {}
            
            -- Handle pending action
            if self.pendingAction == "endRound" then
                self:endRound()
            elseif self.pendingAction == "draw" then
                self:fillHand()
            elseif self.pendingAction == "dealInitialHand" then
                self:dealInitialHand()
            end
            
            self.pendingAction = nil
        end
    end
end

-- Calculate preview score for selected cards
function GameState:calculatePreview()
    if #self.selectedCards == 0 then
        return nil
    end
    
    -- Detect poker hand
    local handInfo = Effects.detectPokerHand(self.selectedCards)
    if not handInfo then
        return nil
    end
    
    -- Get base score and multiplier from the hand type
    local baseScore = handInfo.handType.baseScore
    local handMultiplier = handInfo.handType.multiplier
    
    -- Track corruption multipliers for each suit in the scoring cards
    local suitMultipliers = {}
    for _, card in ipairs(handInfo.scoringCards) do
        if not suitMultipliers[card.suit] then
            suitMultipliers[card.suit] = self.corruption:getMultiplier(card.suit)
        end
    end
    
    -- Calculate total multiplier
    local totalMultiplier = handMultiplier
    for _, multiplier in pairs(suitMultipliers) do
        totalMultiplier = totalMultiplier * multiplier
    end
    
    -- Calculate final score
    local finalScore = baseScore * totalMultiplier
    
    return {
        handType = handInfo.handType,
        scoringCards = handInfo.scoringCards,
        baseScore = baseScore,
        handMultiplier = handMultiplier,
        suitMultipliers = suitMultipliers,
        totalMultiplier = totalMultiplier,
        finalScore = finalScore
    }
end

function GameState:draw()
    if self.showingSummary then
        -- Draw summary screen background
        love.graphics.setColor(0.1, 0.1, 0.1, 1)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        -- Get state info for summary
        local state = self.runManager:getState()
        
        -- Set up fonts
        local titleFont = love.graphics.newFont(32)
        local headerFont = love.graphics.newFont(24)
        local normalFont = love.graphics.newFont(18)
        
        -- Draw round completion title
        love.graphics.setFont(titleFont)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(string.format("Round %d Complete!", state.round - 1), 
            0, 50, love.graphics.getWidth(), "center")
        
        -- Draw score summary
        love.graphics.setFont(headerFont)
        love.graphics.printf("Round Score", 0, 120, love.graphics.getWidth(), "center")
        love.graphics.setFont(normalFont)
        love.graphics.printf(string.format("%d points", self.lastRoundScore),
            0, 160, love.graphics.getWidth(), "center")
        
        -- Draw stage progress
        love.graphics.setFont(headerFont)
        love.graphics.printf("Stage Progress", 0, 220, love.graphics.getWidth(), "center")
        
        -- Draw round boxes
        local boxWidth = 150
        local boxHeight = 80
        local boxSpacing = 30
        local totalWidth = (3 * boxWidth) + (2 * boxSpacing)
        local startX = (love.graphics.getWidth() - totalWidth) / 2
        local boxY = 260
        
        for i = 1, 3 do
            local x = startX + (i-1) * (boxWidth + boxSpacing)
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            love.graphics.rectangle("fill", x, boxY, boxWidth, boxHeight, 5)
            
            -- Highlight current round
            if i == state.round then
                love.graphics.setColor(1, 0.4, 0.7, 1)
                love.graphics.rectangle("line", x, boxY, boxWidth, boxHeight, 5)
            end
            
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(normalFont)
            love.graphics.printf(string.format("Round %d", i), 
                x, boxY + 10, boxWidth, "center")
            
            -- Show score if round is completed
            if i < state.round then
                love.graphics.printf("CLEARED", 
                    x, boxY + 40, boxWidth, "center")
            elseif i == state.round then
                love.graphics.printf(string.format("Target: %d", state.threshold),
                    x, boxY + 40, boxWidth, "center")
            else
                love.graphics.printf("LOCKED",
                    x, boxY + 40, boxWidth, "center")
            end
        end
        
        -- Draw corruption status
        love.graphics.setFont(headerFont)
        love.graphics.printf("Corruption Status", 0, 380, love.graphics.getWidth(), "center")
        love.graphics.setFont(normalFont)
        
        local suitY = 420
        love.graphics.print(string.format("Dates: %.1fx", 
            self.corruption:getMultiplier(Card.SUITS.DATES)), startX, suitY)
        love.graphics.print(string.format("Gifts: %.1fx",
            self.corruption:getMultiplier(Card.SUITS.GIFTS)), startX + boxWidth + boxSpacing, suitY)
        love.graphics.print(string.format("Compliments: %.1fx",
            self.corruption:getMultiplier(Card.SUITS.COMPLIMENTS)), startX, suitY + 30)
        love.graphics.print(string.format("Social: %.1fx",
            self.corruption:getMultiplier(Card.SUITS.SOCIAL)), startX + boxWidth + boxSpacing, suitY + 30)
        
        -- Draw continue button if ready
        if self.readyForNextRound then
            local buttonWidth = 200
            local buttonHeight = 50
            local buttonX = (love.graphics.getWidth() - buttonWidth) / 2
            local buttonY = love.graphics.getHeight() - 100
            
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight, 5)
            love.graphics.setColor(1, 0.4, 0.7, 1)
            love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, buttonHeight, 5)
            
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(normalFont)
            love.graphics.printf("Continue", 
                buttonX, buttonY + (buttonHeight - normalFont:getHeight())/2,
                buttonWidth, "center")
            
            -- Store button bounds for click detection
            self.continueButton = {
                x = buttonX,
                y = buttonY,
                width = buttonWidth,
                height = buttonHeight
            }
        end
    else
        -- Draw normal game state
    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw play area
    BasicUI.drawPlayArea(self.playArea.x, self.playArea.y, self.playArea.width, self.playArea.height)
    
    -- Draw waifu (moved to top right)
    BasicUI.drawWaifu(self.corruption, love.graphics.getWidth() - 150, 100, 40)
    
    -- Draw played cards
    for i, card in ipairs(self.deck.playedCards) do
            card:draw()
    end
    
    -- Draw hand
    for i, card in ipairs(self.deck.hand) do
            card:draw()
        end
        
        -- Draw preview if cards are selected
        local preview = self:calculatePreview()
        if preview then
            -- Draw preview box
            local previewX = 10
            local previewY = love.graphics.getHeight() - 300
            local previewWidth = 250
            local previewHeight = 110
            
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            love.graphics.rectangle("fill", previewX, previewY, previewWidth, previewHeight, 5)
            love.graphics.setColor(1, 0.4, 0.7, 1)
            love.graphics.rectangle("line", previewX, previewY, previewWidth, previewHeight, 5)
            
            -- Set up font
            local previewFont = love.graphics.newFont(14)
            love.graphics.setFont(previewFont)
            love.graphics.setColor(1, 1, 1, 1)
            
            -- Draw preview info
            love.graphics.print(string.format("%s", preview.handType.name), previewX + 10, previewY + 10)
            love.graphics.print(string.format("Base Score: %d", preview.baseScore), previewX + 10, previewY + 30)
            love.graphics.print(string.format("Hand Multiplier: %.1fx", preview.handMultiplier), previewX + 10, previewY + 50)
            
            -- Draw suit multipliers
            local suitY = previewY + 70
            for suit, mult in pairs(preview.suitMultipliers) do
                love.graphics.print(string.format("%s: %.1fx", suit, mult), previewX + 10, suitY)
                suitY = suitY + 20
            end
            
            -- Draw final score
            love.graphics.setColor(1, 0.4, 0.7, 1)
            love.graphics.print(string.format("= %d points", preview.finalScore), previewX + 10, suitY)
        end
        
        -- Set up smaller font for UI
        local uiFont = love.graphics.newFont(14)
        love.graphics.setFont(uiFont)
        
        -- Draw stage info (top left)
        local state = self.runManager:getState()
        love.graphics.setColor(1, 1, 1, 1)
        
        -- Stage progress box
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", 10, 10, 180, 90, 5)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(string.format("Stage %d - Round %d/3", state.stage, state.round), 20, 20)
        love.graphics.print(string.format("Target: %d", state.threshold), 20, 40)
        love.graphics.print(string.format("Score: %d", self.currentScore), 20, 60)
        love.graphics.print(string.format("Best: %d", state.bestScore), 20, 80)
        
        -- Draw suit multipliers (left side)
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", 10, 110, 180, 100, 5)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Suit Multipliers:", 20, 120)
        love.graphics.print(string.format("Dates: %.1fx", self.corruption:getMultiplier(Card.SUITS.DATES)), 30, 140)
        love.graphics.print(string.format("Gifts: %.1fx", self.corruption:getMultiplier(Card.SUITS.GIFTS)), 30, 160)
        love.graphics.print(string.format("Compliments: %.1fx", self.corruption:getMultiplier(Card.SUITS.COMPLIMENTS)), 30, 180)
        love.graphics.print(string.format("Social: %.1fx", self.corruption:getMultiplier(Card.SUITS.SOCIAL)), 30, 200)
        
        -- Draw deck stats (left side, below multipliers)
    local stats = self.deck:getDeckStats()
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", 10, 220, 180, 100, 5)  -- Made taller for extra info
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(string.format("Hands left: %d", self.handsRemaining), 20, 230)
        love.graphics.print(string.format("Discards left: %d", self.discardsRemaining), 20, 250)
        love.graphics.print(string.format("Cards in deck: %d", stats.remainingInDeck), 20, 270)
        love.graphics.print(string.format("Cards played: %d", stats.played), 20, 290)
        
        -- Draw action buttons (right side)
    local buttonPos = BasicUI.getButtonPositions()
        local canPlay = #self.selectedCards > 0 and not self.gameOver
        local canDiscard = #self.selectedCards > 0 and not self.gameOver
    
    BasicUI.drawActionButtons(
        buttonPos.play.x, buttonPos.play.y,
        buttonPos.play.width, buttonPos.play.height,
        canPlay, canDiscard
    )
    
        -- Draw messages
        local messageY = love.graphics.getHeight() - 150
        for _, msg in ipairs(self.messages) do
            love.graphics.print(msg.text, 10, messageY)
            messageY = messageY + 25
        end
        
        -- Draw game over screen
        if self.gameOver then
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            
            -- Use larger font for game over
            local gameOverFont = love.graphics.newFont(24)
            love.graphics.setFont(gameOverFont)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf("GAME OVER - She broke up with you!", 
                0, love.graphics.getHeight() / 2 - 50, 
                love.graphics.getWidth(), "center")
            
            love.graphics.printf("Press SPACE to try again", 
                0, love.graphics.getHeight() / 2 + 50, 
                love.graphics.getWidth(), "center")
        end
    end
end

function GameState:updateHandPositions()
    local handSize = #self.deck.hand
    -- Sort the hand by rank
    self.deck:sortHand()
    
    -- Calculate positions for all cards
    for i, card in ipairs(self.deck.hand) do
        local targetX = (love.graphics.getWidth() / 2) + ((i - math.ceil(Deck.HAND_SIZE/2)) * 80)
        local targetY = love.graphics.getHeight() - 150
        
        -- Only set position directly if card isn't being animated
        if not card.isDealing and not card.isAnimating then
            card:setPosition(targetX, targetY)
        elseif card.isDealing then
            -- Update target position for dealing animation
            card.targetX = targetX
            card.targetY = targetY
        end
    end
end

function GameState:fillHand()
    -- Calculate how many cards we need to add
    local currentHandSize = #self.deck.hand
    local cardsToAdd = math.min(Deck.HAND_SIZE - currentHandSize, #self.deck.drawPile)
    
    if cardsToAdd > 0 then
        -- First, animate existing cards to make room
        self:updateHandPositions()
        
        -- Draw new cards and add them to hand
        local startX = love.graphics.getWidth() + 100  -- Start off screen to the right
        local baseY = love.graphics.getHeight() - 150  -- Base Y position for hand
        
        -- Draw all cards first and store them
        local newCards = {}
        for i = 1, cardsToAdd do
            local card = table.remove(self.deck.drawPile, 1)
            if card then
                -- Add card to hand immediately so sorting works
                table.insert(self.deck.hand, card)
                table.insert(newCards, card)
                
                -- Set initial position
                card:setPosition(startX, baseY)
            end
        end
        
        -- Sort new cards by rank for animation order
        table.sort(newCards, function(a, b)
            return Deck.RANK_ORDER[a.value] < Deck.RANK_ORDER[b.value]
        end)
        
        -- Calculate final positions for all cards
        self:updateHandPositions()
        
        -- Start animations
        for i, card in ipairs(newCards) do
            -- Start dealing animation with a slight delay between cards
            card:animateDealing(card.targetX, card.targetY, (i-1) * 0.03)
        end
    end
end

function GameState:mousepressed(x, y, button)
    if self.showingSummary and self.readyForNextRound then
        -- Check for continue button click
        if self.continueButton and
           x >= self.continueButton.x and x <= self.continueButton.x + self.continueButton.width and
           y >= self.continueButton.y and y <= self.continueButton.y + self.continueButton.height then
            self:startNextRound()
            return
        end
    elseif not self.gameOver then
    if button == 1 then -- Left click
            -- Check for card selection (in reverse order to handle overlapping)
            local handSize = #self.deck.hand
            for i = handSize, 1, -1 do  -- Start from rightmost (top) card
                local card = self.deck.hand[i]
            if card:containsPoint(x, y) then
                    -- Found the topmost card that was clicked
                    -- Toggle card selection
                    local isSelected = false
                    for j, selected in ipairs(self.selectedCards) do
                        if selected.id == card.id then
                            table.remove(self.selectedCards, j)
                            isSelected = true
                break
            end
        end
        
                    if not isSelected then
                        table.insert(self.selectedCards, card)
                        -- Play note for card value when selected
                        BasicAudio.playCardNote(card.value)
                    end
                    
                    card:setHighlight(not isSelected)
                    break  -- Stop checking other cards once we've found the top one
                end
            end
            
            -- Check for button clicks
            local buttonPos = BasicUI.getButtonPositions()
            local canPlay = #self.selectedCards > 0 and not self.isTransitioning
            local canDiscard = #self.selectedCards > 0 and not self.isTransitioning
            
            -- Play button
            if canPlay and BasicUI.isMouseOverButton(buttonPos.play.x, buttonPos.play.y, 
                                                   buttonPos.play.width, buttonPos.play.height) then
                self:playSelectedCards()
            end
            
            -- Discard button
            if canDiscard and BasicUI.isMouseOverButton(buttonPos.discard.x, buttonPos.discard.y,
                                                      buttonPos.discard.width, buttonPos.discard.height) then
                self:discardSelectedCards()
            end
        end
    end
end

function GameState:keypressed(key)
    if self.showingSummary and self.readyForNextRound then
        if key == "space" or key == "return" then
            self:startNextRound()
        end
    elseif self.gameOver then
        if key == "space" then
            -- Return to menu instead of resetting game
            changeState("menu")
        end
    else
    if key == "space" then
            self:playSelectedCards()
    elseif key == "d" then
            self:discardSelectedCards()
        end
    end
end

-- Track corruption changes and play sound when it increases
function GameState:checkCorruptionChange(oldValues, newValues)
    for suit, newValue in pairs(newValues) do
        local oldValue = oldValues[suit] or 0
        if Corruption.getLevel(newValue) > Corruption.getLevel(oldValue) then
                BasicAudio.play("CORRUPTION")
            break  -- Only play sound once even if multiple suits increase
        end
    end
end

return GameState 