function love.conf(t)
    -- Identity
    t.identity = "waifu_deckbuilder"            -- Save directory name
    t.version = "11.4"                          -- LÖVE version
    t.console = true                            -- Enable console output for debugging

    -- Window settings
    t.window.title = "Waifu Deckbuilder"        -- Window title
    t.window.icon = nil                         -- Window icon path
    t.window.width = 1280                       -- Window width
    t.window.height = 720                       -- Window height
    t.window.borderless = false                 -- Remove window border
    t.window.resizable = false                  -- Make window resizable
    t.window.minwidth = 800                     -- Minimum window width
    t.window.minheight = 600                    -- Minimum window height
    t.window.fullscreen = false                 -- Enable fullscreen
    t.window.fullscreentype = "desktop"         -- Fullscreen type
    t.window.vsync = 1                          -- Enable vertical sync
    t.window.msaa = 0                          -- MSAA samples
    t.window.depth = nil                        -- Bits/pixel for depth buffer
    t.window.stencil = nil                      -- Bits/pixel for stencil buffer
    t.window.display = 1                        -- Monitor index

    -- Modules
    t.modules.audio = true                      -- Enable audio module
    t.modules.data = true                       -- Enable data module
    t.modules.event = true                      -- Enable event module
    t.modules.font = true                       -- Enable font module
    t.modules.graphics = true                   -- Enable graphics module
    t.modules.image = true                      -- Enable image module
    t.modules.joystick = false                  -- Disable joystick module
    t.modules.keyboard = true                   -- Enable keyboard module
    t.modules.math = true                       -- Enable math module
    t.modules.mouse = true                      -- Enable mouse module
    t.modules.physics = false                   -- Disable physics module
    t.modules.sound = true                      -- Enable sound module
    t.modules.system = true                     -- Enable system module
    t.modules.thread = true                     -- Enable thread module
    t.modules.timer = true                      -- Enable timer module
    t.modules.touch = false                     -- Disable touch module
    t.modules.video = false                     -- Disable video module
    t.modules.window = true                     -- Enable window module
end 