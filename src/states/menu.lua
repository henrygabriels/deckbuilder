local MenuState = {}
MenuState.__index = MenuState

function MenuState.new()
    local self = setmetatable({}, MenuState)
    
    -- Menu options
    self.options = {
        {text = "New Game", action = "new_game"},
        {text = "Continue", action = "continue", enabled = false},
        {text = "Settings", action = "settings"},
        {text = "Quit", action = "quit"}
    }
    
    -- UI state
    self.selectedOption = 1
    self.buttonWidth = 200
    self.buttonHeight = 50
    self.buttonSpacing = 20
    
    -- Animation state
    self.titleScale = 1
    self.titleScaleDir = 1
    self.buttonHover = nil
    
    return self
end

function MenuState:enter()
    -- Check for save game
    if love.filesystem.getInfo("save.dat") then
        self.options[2].enabled = true
    end
    
    -- Initialize positions
    self:updatePositions()
    
    -- Start background music if needed
    -- love.audio.play(menuMusic)
end

function MenuState:exit()
    -- Stop menu music if needed
    -- love.audio.stop(menuMusic)
end

function MenuState:update(dt)
    -- Update title animation
    self.titleScale = self.titleScale + dt * self.titleScaleDir * 0.1
    if self.titleScale > 1.1 then
        self.titleScale = 1.1
        self.titleScaleDir = -1
    elseif self.titleScale < 0.9 then
        self.titleScale = 0.9
        self.titleScaleDir = 1
    end
end

function MenuState:draw()
    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw title
    love.graphics.setColor(1, 0.4, 0.7, 1)
    local titleText = "Waifu Deckbuilder"
    local titleFont = love.graphics.newFont(48)
    love.graphics.setFont(titleFont)
    
    local titleX = love.graphics.getWidth() / 2
    local titleY = love.graphics.getHeight() / 4
    
    love.graphics.push()
    love.graphics.translate(titleX, titleY)
    love.graphics.scale(self.titleScale)
    love.graphics.printf(titleText, -titleFont:getWidth(titleText)/2, -titleFont:getHeight()/2, 
                        titleFont:getWidth(titleText), "center")
    love.graphics.pop()
    
    -- Draw menu options
    local buttonFont = love.graphics.newFont(24)
    love.graphics.setFont(buttonFont)
    
    for i, option in ipairs(self.options) do
        local x = love.graphics.getWidth() / 2 - self.buttonWidth / 2
        local y = love.graphics.getHeight() / 2 + (i-1) * (self.buttonHeight + self.buttonSpacing)
        
        -- Draw button background
        if i == self.buttonHover and option.enabled ~= false then
            love.graphics.setColor(1, 0.4, 0.7, 1)
        elseif option.enabled == false then
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
        end
        love.graphics.rectangle("fill", x, y, self.buttonWidth, self.buttonHeight, 8)
        
        -- Draw button border
        love.graphics.setColor(1, 0.4, 0.7, 1)
        love.graphics.rectangle("line", x, y, self.buttonWidth, self.buttonHeight, 8)
        
        -- Draw button text
        if option.enabled == false then
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        love.graphics.printf(option.text, x, y + self.buttonHeight/2 - buttonFont:getHeight()/2,
                           self.buttonWidth, "center")
    end
end

function MenuState:mousepressed(x, y, button)
    if button == 1 then -- Left click
        for i, option in ipairs(self.options) do
            if option.enabled ~= false and self:isMouseOverButton(i, x, y) then
                self:selectOption(option.action)
                break
            end
        end
    end
end

function MenuState:mousemoved(x, y)
    self.buttonHover = nil
    for i, option in ipairs(self.options) do
        if self:isMouseOverButton(i, x, y) then
            self.buttonHover = i
            break
        end
    end
end

function MenuState:mousereleased(x, y, button)
    -- Handle mouse release if needed
end

function MenuState:keypressed(key)
    if key == "up" then
        self:selectPreviousOption()
    elseif key == "down" then
        self:selectNextOption()
    elseif key == "return" then
        self:selectOption(self.options[self.selectedOption].action)
    end
end

function MenuState:selectOption(action)
    if action == "new_game" then
        changeState("game")
    elseif action == "continue" then
        -- Load saved game
        changeState("game")
    elseif action == "settings" then
        -- Open settings
    elseif action == "quit" then
        love.event.quit()
    end
end

function MenuState:selectNextOption()
    repeat
        self.selectedOption = (self.selectedOption % #self.options) + 1
    until self.options[self.selectedOption].enabled ~= false
end

function MenuState:selectPreviousOption()
    repeat
        self.selectedOption = ((self.selectedOption - 2) % #self.options) + 1
    until self.options[self.selectedOption].enabled ~= false
end

function MenuState:isMouseOverButton(index, x, y)
    local buttonX = love.graphics.getWidth() / 2 - self.buttonWidth / 2
    local buttonY = love.graphics.getHeight() / 2 + (index-1) * (self.buttonHeight + self.buttonSpacing)
    
    return x >= buttonX and x <= buttonX + self.buttonWidth and
           y >= buttonY and y <= buttonY + self.buttonHeight
end

function MenuState:updatePositions()
    -- Update any position-dependent values if needed
end

return MenuState 