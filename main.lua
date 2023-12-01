local FPS = 15
local TIME_PER_FRAME = 1 / FPS
local TITLE = "Wormy"
local WINDOWWIDTH  = 1024--640
local WINDOWHEIGHT = 768--480
local CELLSIZE     = 32

assert(WINDOWWIDTH % CELLSIZE == 0, "Window width must be a multiple of cell size.")
assert(WINDOWHEIGHT % CELLSIZE == 0, "Window height must be a multiple of cell size.")

CELLWIDTH  = math.floor(WINDOWWIDTH / CELLSIZE)
CELLHEIGHT = math.floor(WINDOWHEIGHT / CELLSIZE)
 
--             R    G    B
local WHITE     = { 1.0, 1.0, 1.0} --(255, 255, 255)
local BLACK     = {  .0,  .0,  .0} --(  0,   0,   0)
local RED       = { 1.0,  .0,  .0} --(255,   0,   0)
local GREEN     = {  .0, 1.0,  .0} --(  0, 255,   0)
local DARKGREEN = {  .0, 0.6,  .0} --(  0, 155,   0)
local DARKGRAY  = { .15, .15, .15} --( 40,  40,  40)
local BGCOLOR = BLACK

local UP    = "up"
local DOWN  = "down"
local LEFT  = "left"
local RIGHT = "right"

local STATES = {
    MENU = "menu",
    PAUSED = "paused",
    GAME = "game",
    GAME_OVER = "game_over"
}

local HEAD = 1
local state = STATES.MENU

local BIGFONT   = love.graphics.newFont('/assets/fonts/juniory.ttf', 100)
local BASICFONT   = love.graphics.newFont('/assets/fonts/juniory.ttf', 25)

local degrees1 = 0 -- degrees of start text
local degrees2 = 0 -- degrees of start text
local direction = RIGHT
local apple = {}
local accumulatedTime = 0

function love.load()
    love.window.setTitle(TITLE)
    love.window.setMode(WINDOWWIDTH, WINDOWHEIGHT)
    love.graphics.setBackgroundColor(155/255, 188/255, 15/255)
end

function love.keypressed(key)
    if state == STATES.GAME then
        if (key == "up" or key == "w") and direction ~= DOWN then
            direction = UP
        elseif (key == "right" or key == "d") and direction ~= LEFT then
            direction = RIGHT
        elseif (key == "down" or key == "s") and direction ~= UP then
            direction = DOWN
        elseif (key == "left" or key == "a") and direction ~= RIGHT then
            direction = LEFT
        end
    end
end

function love.keyreleased(key)
    if state == STATES.MENU then
        state = STATES.GAME
        -- Set a random start point.
        local startx = love.math.random(5, CELLWIDTH - 6)
        local starty = love.math.random(5, CELLHEIGHT - 6)
        wormCoords = { {x = startx,     y = starty},
                       {x = startx - 1, y = starty},
                       {x = startx - 2, y = starty} }
        direction = RIGHT
        print("startx ", startx)
        --Start the apple in a random place.
        apple = getRandomLocation()
        accumulatedTime = 0
    elseif state == STATES.GAME_OVER then
        state = STATES.MENU
    end


    if key == "escape" then
        love.event.quit()
    end
end

function love.update(dt)
    if state == STATES.GAME then
        accumulatedTime = accumulatedTime + dt
        if accumulatedTime >= TIME_PER_FRAME then
            accumulatedTime = accumulatedTime - TIME_PER_FRAME
            -- check if the worm has hit itself or the edge
            if wormCoords[HEAD].x == -1 or wormCoords[HEAD].x == CELLWIDTH or wormCoords[HEAD].y == -1 or wormCoords[HEAD].y == CELLHEIGHT then
                state = STATES.GAME_OVER
                return -- game over
            end
            for i = 2, #wormCoords do
                if wormCoords[i].x == wormCoords[HEAD].x and wormCoords[i].y == wormCoords[HEAD].y then
                    state = STATES.GAME_OVER
                    return -- game over
                end
            end

            -- check if worm has eaten an apply
            if wormCoords[HEAD].x == apple.x and wormCoords[HEAD].y == apple.y then
                -- don't remove worm's tail segment
                apple = getRandomLocation() -- set a new apple somewhere
            else
                table.remove(wormCoords, #wormCoords)
            end

            -- move the worm by adding a segment in the direction it is moving
            local newHead = {}
            if direction == UP then
                newHead = {x = wormCoords[HEAD].x, y = wormCoords[HEAD].y - 1}
            elseif direction == DOWN then
                newHead = {x = wormCoords[HEAD].x, y = wormCoords[HEAD].y + 1}
            elseif direction == LEFT then
                newHead = {x = wormCoords[HEAD].x - 1, y = wormCoords[HEAD].y}
            elseif direction == RIGHT then
                newHead = {x = wormCoords[HEAD].x + 1, y = wormCoords[HEAD].y}
            end
            table.insert(wormCoords, 1, newHead)
        end
    end
end

function love.draw()
    if state == STATES.MENU then
        showStartScreen()
    elseif state == STATES.GAME then
        --love.graphics.print("Game", 0, 0)
        drawGrid()
        drawApple()
        drawScore()
        drawWorm()
    elseif state == STATES.GAME_OVER then
        love.graphics.print("GAME OVER", 0, 0)
    end
end

function showStartScreen() 
    love.graphics.setFont(BIGFONT)
    local titleText = "Wormy !"
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(titleText)
    local textHeight = font:getHeight()
    love.graphics.setColor(WHITE)
    love.graphics.print(titleText, WINDOWWIDTH/2, WINDOWHEIGHT/2, degrees1, 1, 1, textWidth/2, textHeight/2)
    
    love.graphics.setColor(GREEN)
    love.graphics.print(titleText, WINDOWWIDTH/2, WINDOWHEIGHT/2, degrees2, 1, 1, textWidth/2, textHeight/2)
    degrees1 = degrees1 + 0.01
    degrees2 = degrees2 + 0.015

    love.graphics.setColor(RED)
    love.graphics.setFont(BASICFONT)
    love.graphics.print("Press a key to play.", WINDOWWIDTH/2, WINDOWHEIGHT - 30)

    love.graphics.setColor(1,1,1)
end

function getRandomLocation()
    return {x = love.math.random(0, CELLWIDTH - 1), y = love.math.random(0, CELLHEIGHT - 1)}
end

function drawScore()
    love.graphics.setFont(BASICFONT)
    love.graphics.print("Score: "..tostring((#wormCoords-3)), WINDOWWIDTH - 120, 10) 
end

function drawApple()
    love.graphics.setColor(RED)
    love.graphics.rectangle("fill", apple.x * CELLSIZE, apple.y * CELLSIZE, CELLSIZE, CELLSIZE)
    love.graphics.setColor(1, 1, 1)
end

function drawWorm()
    for i = 1, #wormCoords do
        love.graphics.setColor(DARKGREEN)
        local x = wormCoords[i].x * CELLSIZE
        local y = wormCoords[i].y * CELLSIZE
        love.graphics.rectangle("fill", x, y, CELLSIZE, CELLSIZE)
        love.graphics.setColor(GREEN)
        love.graphics.rectangle("fill", x + 4, y + 4, CELLSIZE - 8, CELLSIZE - 8)
    end
end

function drawGrid()
    for x = 0, WINDOWWIDTH, CELLSIZE do -- draw vertical lines
        love.graphics.setColor(DARKGRAY)
        love.graphics.line(x, 0, x, WINDOWHEIGHT)
    end
    for y = 0, WINDOWHEIGHT, CELLSIZE  do -- draw horizontal lines
        love.graphics.setColor(DARKGRAY)
        love.graphics.line(0, y, WINDOWWIDTH, y)
    end
end