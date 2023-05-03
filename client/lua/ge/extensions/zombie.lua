local imgui = ui_imgui

local M = {}

M.outbreak = false
M.showUI = imgui.BoolPtr(true)
M.playerIsInfected = false

local oldMission = nil
local noOfTouchingVehicles = 0

local function reset()
    -- Default all mod properties here
    M.outbreak = false
    M.playerIsInfected = false
end

local function tooltip(text)
    imgui.TextDisabled("(?)")
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(imgui.GetFontSize() * 35.0);
        imgui.TextUnformatted(text)
        imgui.EndTooltip()
    end
end

local ptrBgRed = imgui.FloatPtr(.04)
local ptrBgGreen = imgui.FloatPtr(.30)
local ptrBgBlue = imgui.FloatPtr(.18)
local ptrBgAlpha = imgui.FloatPtr(.8)

local function renderUI()

    local windowFlags = imgui.flags(
        imgui.WindowFlags_NoTitleBar,
        imgui.WindowFlags_NoResize,
        imgui.WindowFlags_AlwaysAutoResize
    )

    local mainViewport = imgui.GetMainViewport()
    local viewPortYHalf = mainViewport.Size.y / 2

    if M.outbreak then
        zombieui.pushStyle(imgui.StyleVar_WindowBorderSize, 1)
        zombieui.pushStyle(imgui.StyleVar_WindowRounding, 8)
        zombieui.pushStyle(imgui.StyleVar_WindowPadding, imgui.ImVec2(40, 6))

        if M.playerIsInfected then
            zombieui.pushColor(imgui.Col_WindowBg, imgui.ImVec4(.54, 0, 0, 1))
        else
            zombieui.pushColor(imgui.Col_WindowBg, imgui.ImVec4(.21, .58, 0, 1))
        end

        imgui.Begin("zombie#playerStatus", M.showUI, windowFlags)
        imgui.SetWindowPos1(imgui.ImVec2(0, viewPortYHalf - 150))

        imgui.SetWindowFontScale(2)
        if M.playerIsInfected then
            imgui.Text("Infected")
        else
            imgui.Text("Survivor")
        end
        imgui.SetWindowFontScale(1)

        imgui.End()
        zombieui.popAll()
    end

    zombieui.pushStyle(imgui.StyleVar_WindowTitleAlign, imgui.ImVec2(0.5, 0.5))
    zombieui.pushStyle(imgui.StyleVar_WindowPadding, imgui.ImVec2(8, 6))
    zombieui.pushStyle(imgui.StyleVar_ItemSpacing, imgui.ImVec2(6, 4))
    zombieui.pushStyle(imgui.StyleVar_WindowBorderSize, 1)
    zombieui.pushStyle(imgui.StyleVar_WindowRounding, 0)

    zombieui.pushColor(imgui.Col_WindowBg, imgui.ImVec4(ptrBgRed[0], ptrBgGreen[0], ptrBgBlue[0], ptrBgAlpha[0]))

    -- zombieui.pushColor(imgui.Col_Separator, imgui.ImVec4(0.85, 0.75, 0.55, 1))
    -- zombieui.pushColor(imgui.Col_SeparatorHovered, imgui.ImVec4(0.85, 0.75, 0.55, 1))
    -- zombieui.pushColor(imgui.Col_SeparatorActive, imgui.ImVec4(0.85, 0.75, 0.55, 1))

    zombieui.pushColor(imgui.Col_Button, imgui.ImVec4(.32, .52, .1, 1))
    zombieui.pushColor(imgui.Col_ButtonHovered, imgui.ImVec4(.34, .60, .25, 1))
    zombieui.pushColor(imgui.Col_ButtonActive, imgui.ImVec4(.34, .8, .17, 1))

    if imgui.Begin("Zombie Mode", M.showUI, windowFlags) then
        -- Aligned left and centered vertically
        imgui.SetWindowPos1(imgui.ImVec2(0, viewPortYHalf - imgui.GetWindowHeight() / 2))

        imgui.Text("Outbreak status:")
        imgui.SameLine()
        if M.outbreak then
            imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "Active")
        else
            imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), "Inactive")
        end

        imgui.SetWindowFontScale(1.2)
        if M.outbreak then
            if imgui.Button("Stop outbreak") then
                print('Stop button clicked')
                TriggerServerEvent('zombieStopOutbreak', 'Stop')
            end
        else
            if imgui.Button("Start outbreak") then
                print('Start button clicked')
                TriggerServerEvent('zombieStartOutbreak', 'Start')
            end
        end
        imgui.SetWindowFontScale(1)


        imgui.End()
    end
    zombieui.popAll()
end

M.reload = function()
    log("D", "reload", "Reloading...")
    extensions.reload("zombie")
    extensions.reload("zombieui")
end

M.start = function ()
    M.outbreak = true
end
M.stop = function ()
    M.outbreak = false
end
M.setInfected = function ()
    M.playerIsInfected = true
end
M.setSurvivor = function ()
    M.playerIsInfected = false
end

M.onExtensionLoaded = function()
    log("D", "onExtensionLoaded", "Zombie extension loaded")
end

M.onExtensionUnloaded = function()
    log("D", "onExtensionUnloaded", "Zombie extension unloaded")
    reset()
end

M.onUpdate = function(dt)
    -- local mission = getMissionFilename()
    -- if not oldMission or oldMission ~= mission then
    --     if mission == "" then return end
    --     oldMission = mission
    --     reset()
    -- end

    -- Check for collisions
    -- if M.outbreak then

    --     local gameVehicleId = be:getPlayerVehicleID(0)
    --     local collisions = map.objects[gameVehicleId].objectCollisions
    --     -- Reset every update
    --     noOfTouchingVehicles = 0

    --     for vehicleId, _ in pairs(collisions) do
    --         noOfTouchingVehicles = noOfTouchingVehicles + 1
    --     end
    -- end

    -- Lastly, render UI
    if M.showUI[0] then
        renderUI()
    end
end

AddEventHandler('zombieCountdown', function (data)
    print('zombieCountdown from server', data)
end)

AddEventHandler('zombieReset', function (data)
    print('zombieReset from server', data)
    reset()
end)

AddEventHandler('zombieStartOutbreak', function (data)
    print('zombieStartOutbreak from server', data)
    M.outbreak = true
end)

AddEventHandler('zombieStopOutbreak', function (data)
    print('zombieStopOutbreak from server', data)
    reset()
end)

AddEventHandler('zombieTurnInfected', function (data)
    print('zombieTurnInfected from server', data)
    M.playerIsInfected = true
end)

return M
