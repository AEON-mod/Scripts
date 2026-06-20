-- =============================================================================
-- Project:  AeonGlide — Advanced Mouse Gestures
-- Version:  5.0.0
-- Platform: macOS (Hammerspoon — https://www.hammerspoon.org)
--
-- Installation:
--   1. Install Hammerspoon  →  brew install --cask hammerspoon
--   2. Copy this file to    →  ~/.hammerspoon/AeonGlide.lua
--   3. Add to init.lua      →  require("AeonGlide")
--   4. Reload config        →  ⌘⇧R  or click Hammerspoon → Reload Config
-- =============================================================================

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ CONFIGURATION                                                              │
-- └─────────────────────────────────────────────────────────────────────────────┘

local config = {
    clickWindow       = 0.35,   -- Max seconds between clicks for multi-click
    singleClickDelay  = 0.20,   -- Seconds before committing a single right-click
    swipeThreshold    = 50,     -- Min px horizontal drag to count as a swipe
    holdThreshold     = 0.30,   -- Seconds — shorter = tap, longer = hold
    edgeHoverDelay    = 1.0,    -- Seconds hovering top pixel → Mission Control
    edgeHoverCooldown = 1.5,    -- Seconds cooldown after Mission Control fires
    gameCheckInterval = 2.0,    -- Seconds between game-detection polls
    edgeCheckInterval = 0.1,    -- Seconds between top-edge hover polls
    version           = "5.0.0",
}

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ GAME / FULLSCREEN APP DETECTION LIST                                       │
-- │ Use bundle identifiers (preferred) or exact app names.                     │
-- │ Find bundle IDs: osascript -e 'id of app "AppName"'                       │
-- └─────────────────────────────────────────────────────────────────────────────┘

local targetGames = {
    -- Bundle identifiers
    "com.riotgames.LeagueofLegends.GameClient",
    "com.valvesoftware.cs2",
    "com.mojang.minecraftlauncher",
    "com.epicgames.fortnite",
    -- App names (fallback)
    "Minecraft",
    "Steam",
}

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ INTERNAL STATE                                                             │
-- └─────────────────────────────────────────────────────────────────────────────┘

local state = {
    suspended      = false,
    rClicks        = 0,
    lClicks        = 0,
    leftHeld       = false,
    comboMode      = false,    -- latched at rightMouseDown when left is held
    rightDownPos   = nil,
    rightDownTime  = 0,
    passThrough    = 0,        -- count of synthetic events to let pass
    lastRClickTime = 0,
    lastLClickTime = 0,
    hoverStart     = 0,
}

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ MENUBAR ICON                                                               │
-- └─────────────────────────────────────────────────────────────────────────────┘

local menubar = hs.menubar.new()

local function updateMenubar()
    if state.suspended then
        menubar:setTitle("🔴")
        menubar:setTooltip("AeonGlide v" .. config.version .. " — Paused")
    else
        menubar:setTitle("🟢")
        menubar:setTooltip("AeonGlide v" .. config.version .. " — Active")
    end
    menubar:setMenu({
        { title = "AeonGlide v" .. config.version, disabled = true },
        { title = "-" },
        { title = state.suspended and "▶  Resume" or "⏸  Pause", fn = function()
            state.suspended = not state.suspended
            updateMenubar()
            hs.alert.show(state.suspended and "AeonGlide ⏸ Paused" or "AeonGlide ▶ Active")
        end },
        { title = "-" },
        { title = "⏻  Quit AeonGlide", fn = function()
            cleanup()
        end },
    })
end

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ GAME DETECTION TIMER                                                       │
-- └─────────────────────────────────────────────────────────────────────────────┘

local gameSuspended = false  -- track whether *game detection* caused the pause

local gameTimer = hs.timer.new(config.gameCheckInterval, function()
    local app = hs.application.frontmostApplication()
    if not app then return end

    local bid  = app:bundleID() or ""
    local name = app:name()     or ""

    local found = false
    for _, pattern in ipairs(targetGames) do
        if bid == pattern or name == pattern then
            found = true
            break
        end
    end

    if found and not state.suspended then
        state.suspended = true
        gameSuspended   = true
        updateMenubar()
    elseif not found and gameSuspended then
        state.suspended = false
        gameSuspended   = false
        updateMenubar()
    end
end)

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ TOP EDGE HOVER → MISSION CONTROL                                          │
-- └─────────────────────────────────────────────────────────────────────────────┘

local edgeTimer = hs.timer.new(config.edgeCheckInterval, function()
    if state.suspended then return end

    local pos    = hs.mouse.absolutePosition()
    local screen = hs.mouse.getCurrentScreen()
    if not screen then return end

    local frame = screen:frame()

    if pos.y <= frame.y + 1 then
        if state.hoverStart == 0 then
            state.hoverStart = hs.timer.secondsSinceEpoch()
        elseif hs.timer.secondsSinceEpoch() - state.hoverStart > config.edgeHoverDelay then
            -- Trigger Mission Control  (Ctrl+Up is the default binding)
            hs.eventtap.keyStroke({ "ctrl" }, "up")
            state.hoverStart = 0
            hs.timer.usleep(config.edgeHoverCooldown * 1e6)
        end
    else
        state.hoverStart = 0
    end
end)

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ DELAYED-ACTION TIMER MANAGEMENT                                            │
-- └─────────────────────────────────────────────────────────────────────────────┘

local singleTimer = nil
local multiTimer  = nil

local function cancelTimers()
    if singleTimer then singleTimer:stop(); singleTimer = nil end
    if multiTimer  then multiTimer:stop();  multiTimer  = nil end
end

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ LEFT BUTTON TRACKER — state + triple-click paste                           │
-- └─────────────────────────────────────────────────────────────────────────────┘

local leftTap = hs.eventtap.new({
    hs.eventtap.event.types.leftMouseDown,
    hs.eventtap.event.types.leftMouseUp,
}, function(event)
    if state.suspended then return false end

    local t = event:getType()

    if t == hs.eventtap.event.types.leftMouseDown then
        state.leftHeld = true

        -- Triple left-click → Paste
        local now = hs.timer.secondsSinceEpoch()
        if now - state.lastLClickTime < config.clickWindow then
            state.lClicks = state.lClicks + 1
        else
            state.lClicks = 1
        end
        state.lastLClickTime = now

        if state.lClicks >= 3 then
            hs.eventtap.keyStroke({ "cmd" }, "v")
            state.lClicks = 0
        end

    elseif t == hs.eventtap.event.types.leftMouseUp then
        state.leftHeld = false
    end

    return false   -- always pass through left clicks
end)

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ RIGHT BUTTON — Master Gesture Handler                                      │
-- │                                                                            │
-- │   Single click    →  Context menu (synthetic pass-through)                 │
-- │   Double click    →  Copy           ⌘C                                    │
-- │   Triple click    →  Select All     ⌘A                                    │
-- │   Swipe L / R     →  Back / Forward ⌘[ / ⌘]                              │
-- │   Left+Tap Right  →  Clipboard      ⌘⇧V  (or 3rd-party manager)          │
-- │   Left+Hold Right →  Screenshot     ⌘⇧4                                  │
-- └─────────────────────────────────────────────────────────────────────────────┘

local rightTap = hs.eventtap.new({
    hs.eventtap.event.types.rightMouseDown,
    hs.eventtap.event.types.rightMouseUp,
}, function(event)
    if state.suspended then return false end

    local t = event:getType()

    -- ── RIGHT MOUSE DOWN ───────────────────────────────────────────────────
    if t == hs.eventtap.event.types.rightMouseDown then
        if state.passThrough > 0 then
            state.passThrough = state.passThrough - 1
            return false
        end

        state.rightDownPos  = hs.mouse.absolutePosition()
        state.rightDownTime = hs.timer.secondsSinceEpoch()
        state.comboMode     = state.leftHeld   -- latch combo state at press

        return true   -- consume

    -- ── RIGHT MOUSE UP ─────────────────────────────────────────────────────
    elseif t == hs.eventtap.event.types.rightMouseUp then
        if state.passThrough > 0 then
            state.passThrough = state.passThrough - 1
            return false
        end

        local now      = hs.timer.secondsSinceEpoch()
        local duration = now - state.rightDownTime
        local upPos    = hs.mouse.absolutePosition()

        -- ── Combo: Left was held when right was pressed ────────────────────
        if state.comboMode then
            state.comboMode = false
            if duration > 0.3 then
                hs.eventtap.keyStroke({ "cmd", "shift" }, "4")   -- Screenshot
            else
                hs.eventtap.keyStroke({ "cmd", "shift" }, "v")   -- Clipboard
            end
            return true
        end

        -- ── Swipe detection ────────────────────────────────────────────────
        if state.rightDownPos then
            local distX = upPos.x - state.rightDownPos.x
            if math.abs(distX) > config.swipeThreshold then
                if distX > 0 then
                    hs.eventtap.keyStroke({ "cmd" }, "]")        -- Forward
                else
                    hs.eventtap.keyStroke({ "cmd" }, "[")        -- Back
                end
                state.rClicks = 0
                cancelTimers()
                return true
            end
        end

        -- ── Multi-click state machine ──────────────────────────────────────
        if now - state.lastRClickTime < config.clickWindow then
            state.rClicks = state.rClicks + 1
        else
            state.rClicks = 1
        end
        state.lastRClickTime = now

        cancelTimers()

        local clickDur = duration

        if state.rClicks == 1 then
            singleTimer = hs.timer.doAfter(config.singleClickDelay, function()
                if state.rClicks == 1 then
                    -- Quick tap → pass-through native right-click
                    if clickDur < config.holdThreshold then
                        state.passThrough = 2   -- down + up
                        hs.eventtap.rightClick(hs.mouse.absolutePosition())
                    end
                    state.rClicks = 0
                elseif state.rClicks >= 2 then
                    -- Wait a beat for a possible 3rd click
                    multiTimer = hs.timer.doAfter(0.18, function()
                        if state.rClicks >= 3 then
                            hs.eventtap.keyStroke({ "cmd" }, "a")   -- Select All
                        else
                            hs.eventtap.keyStroke({ "cmd" }, "c")   -- Copy
                        end
                        state.rClicks = 0
                    end)
                end
            end)
        end

        return true   -- consume
    end

    return false
end)

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ HOTKEY BINDINGS                                                            │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- Manual toggle: ⌃⌘P
hs.hotkey.bind({ "ctrl", "cmd" }, "p", function()
    state.suspended = not state.suspended
    gameSuspended   = false   -- clear auto-pause latch on manual toggle
    updateMenubar()
    hs.alert.show(state.suspended and "AeonGlide ⏸ Paused" or "AeonGlide ▶ Active")
end)

-- Kill switch: ⌃⌘Escape
local function cleanup()
    leftTap:stop()
    rightTap:stop()
    gameTimer:stop()
    edgeTimer:stop()
    cancelTimers()
    if menubar then menubar:delete() end
    hs.alert.show("AeonGlide ■ Terminated")
end

hs.hotkey.bind({ "ctrl", "cmd" }, "escape", cleanup)

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ START                                                                      │
-- └─────────────────────────────────────────────────────────────────────────────┘

leftTap:start()
rightTap:start()
gameTimer:start()
edgeTimer:start()
updateMenubar()

hs.alert.show("🛸 AeonGlide v" .. config.version .. " — Active")
