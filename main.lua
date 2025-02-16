-- Import required modules
local GameState = require('src.states.game')
local MenuState = require('src.states.menu')
local PauseState = require('src.states.pause')

-- Global game state
local currentState
local states = {}
local gameWidth = 1280
local gameHeight = 720
local debug = false

-- Global state change function (needs to be global for states to access it)
function changeState(stateName)
    if states[stateName] then
        if currentState then
            currentState:exit()
        end
        currentState = states[stateName]
        if currentState.enter then
            currentState:enter()
        end
    end
end

-- Initialize the game
function love.load()
    -- Enable debug mode if launched with --debug
    for _, arg in ipairs(love.arg.parseGameArguments(arg)) do
        if arg == '--debug' then
            debug = true
        end
    end

    -- Set up window
    love.window.setMode(gameWidth, gameHeight, {
        resizable = false,
        vsync = true,
        minwidth = 800,
        minheight = 600
    })
    love.window.setTitle("Waifu Deckbuilder")

    -- Initialize states
    states = {
        menu = MenuState.new(),
        game = GameState.new(),
        pause = PauseState.new()
    }

    -- Start with menu state
    changeState('menu')
end

-- Update game logic
function love.update(dt)
    if currentState and currentState.update then
        currentState:update(dt)
    end
end

-- Draw game graphics
function love.draw()
    if currentState and currentState.draw then
        currentState:draw()
    end

    -- Draw debug info if in debug mode
    if debug then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
        love.graphics.print("Memory: " .. math.floor(collectgarbage("count")) .. "KB", 10, 30)
        if currentState and currentState.drawDebug then
            currentState:drawDebug()
        end
    end
end

-- Handle mouse pressed events
function love.mousepressed(x, y, button)
    if currentState and currentState.mousepressed then
        currentState:mousepressed(x, y, button)
    end
end

-- Handle mouse moved events
function love.mousemoved(x, y)
    if currentState and currentState.mousemoved then
        currentState:mousemoved(x, y)
    end
end

-- Handle mouse released events
function love.mousereleased(x, y, button)
    if currentState and currentState.mousereleased then
        currentState:mousereleased(x, y, button)
    end
end

-- Handle keyboard events
function love.keypressed(key)
    if currentState and currentState.keypressed then
        currentState:keypressed(key)
    end
end

-- Handle window focus changes
function love.focus(focused)
    if not focused and currentState == states.game then
        changeState('pause')
    end
end

-- Clean up resources
function love.quit()
    -- Save game state if needed
    if currentState and currentState.save then
        currentState:save()
    end
end 