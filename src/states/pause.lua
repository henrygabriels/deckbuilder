local PauseState = {}
PauseState.__index = PauseState

function PauseState.new()
    local self = setmetatable({}, PauseState)
    
    -- Menu options
    self.options = {
        {text = "Resume", action = "resume"},
        {text = "Settings", action = "settings"},
        {text = "Quit to Menu", action = "quit_menu"}
    }
    
    -- UI state
    self.selectedOption = 1
    self.buttonWidth = 200
    self.buttonHeight = 50
    self.buttonSpacing = 20
    self.buttonHover = nil
    
    return self
end

function PauseState:enter()
    -- Pause game music if needed
    -- love.audio.pause(gameMusic)
    
    -- Initialize positions
    self:updatePositions()
end

function PauseState:exit()
    -- Resume game music if needed
    -- love.audio.resume(gameMusic)
end

function PauseState:update(dt)
    -- Update any animations if needed
end

function PauseState:draw()
    -- Draw game state in background (dimmed)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw pause menu
    love.graphics.setColor(1, 1, 1, 1)
    local titleFont = love.graphics.newFont(36)
    love.graphics.setFont(titleFont)
    love.graphics.printf("PAUSED", 0, love.graphics.getHeight() / 4,
                        love.graphics.getWidth(), "center")
    
    -- Draw menu options
    local buttonFont = love.graphics.newFont(24)
    love.graphics.setFont(buttonFont)
    
    for i, option in ipairs(self.options) do
        local x = love.graphics.getWidth() / 2 - self.buttonWidth / 2
        local y = love.graphics.getHeight() / 2 + (i-1) * (self.buttonHeight + self.buttonSpacing)
        
        -- Draw button background
        if i == self.buttonHover then
            love.graphics.setColor(1, 0.4, 0.7, 1)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
        end
        love.graphics.rectangle("fill", x, y, self.buttonWidth, self.buttonHeight, 8)
        
        -- Draw button border
        love.graphics.setColor(1, 0.4, 0.7, 1)
        love.graphics.rectangle("line", x, y, self.buttonWidth, self.buttonHeight, 8)
        
        -- Draw button text
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(option.text, x, y + self.buttonHeight/2 - buttonFont:getHeight()/2,
                           self.buttonWidth, "center")
    end
end

function PauseState:mousepressed(x, y, button)
    if button == 1 then -- Left click
        for i, option in ipairs(self.options) do
            if self:isMouseOverButton(i, x, y) then
                self:selectOption(option.action)
                break
            end
        end
    end
end

function PauseState:mousemoved(x, y)
    self.buttonHover = nil
    for i, option in ipairs(self.options) do
        if self:isMouseOverButton(i, x, y) then
            self.buttonHover = i
            break
        end
    end
end

function PauseState:mousereleased(x, y, button)
    -- Handle mouse release if needed
end

function PauseState:keypressed(key)
    if key == "up" then
        self:selectPreviousOption()
    elseif key == "down" then
        self:selectNextOption()
    elseif key == "return" then
        self:selectOption(self.options[self.selectedOption].action)
    elseif key == "escape" then
        self:selectOption("resume")
    end
end

function PauseState:selectOption(action)
    if action == "resume" then
        changeState("game")
    elseif action == "settings" then
        -- Open settings
    elseif action == "quit_menu" then
        changeState("menu")
    end
end

function PauseState:selectNextOption()
    self.selectedOption = (self.selectedOption % #self.options) + 1
end

function PauseState:selectPreviousOption()
    self.selectedOption = ((self.selectedOption - 2) % #self.options) + 1
end

function PauseState:isMouseOverButton(index, x, y)
    local buttonX = love.graphics.getWidth() / 2 - self.buttonWidth / 2
    local buttonY = love.graphics.getHeight() / 2 + (index-1) * (self.buttonHeight + self.buttonSpacing)
    
    return x >= buttonX and x <= buttonX + self.buttonWidth and
           y >= buttonY and y <= buttonY + self.buttonHeight
end

function PauseState:updatePositions()
    -- Update any position-dependent values if needed
end

return PauseState 