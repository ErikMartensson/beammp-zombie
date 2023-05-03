local imgui = ui_imgui

local M = {}

local colorCount = 0
local styleCount = 0

local function pushStyle(idx, val)
    if type(val) == "cdata" then
        imgui.PushStyleVar2(idx, val)
    else
        imgui.PushStyleVar1(idx, val)
    end

    styleCount = styleCount + 1
end

local function pushColor(idx, col)
    if type(col) == "cdata" then
        imgui.PushStyleColor2(idx, col)
    else
        imgui.PushStyleColor1(idx, col)
    end

    colorCount = colorCount + 1
end

local function popAll()
    imgui.PopStyleVar(styleCount)
    imgui.PopStyleColor(colorCount)

    colorCount = 0
    styleCount = 0
end

local function textCenter(text)
    imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(text).x) * 0.5)
    imgui.Text(text)
end

M.pushStyle = pushStyle
M.pushColor = pushColor
M.popAll = popAll

M.textCenter = textCenter

return M
