--[[
  ____ _____  _    ____  _  ______    _   _ _   _ ____  
 / ___|_   _|/ \  |  _ \| |/ / ___|  | | | | | | |  _ \ 
 \___ \ | | / _ \ | |_) | ' /\___ \  | |_| | | | | | | |
  ___) || |/ ___ \|  _ <| . \ ___) | |  _  | |_| | |_| |
 |____/ |_/_/   \_|_| \_|_|\_|____/  |_| |_|\___/|____/ 

Made by:      Stuka
Discord:      stuka1808
Some parts of this script contain snippets from:
OverlordAkise - https://github.com/OverlordAkise
--]]

if not ENABLE_OVERHEAD_HUD then return end

-- Disable default DarkRP HUD elements
timer.Simple(1, function()
    if GAMEMODE and GAMEMODE.Config then
        GAMEMODE.Config.showjob = false
        GAMEMODE.Config.showhealth = false
        GAMEMODE.Config.showname = false
    end
end)

-- Remove default overhead

hook.Remove("PostPlayerDraw", "DarkRP_ChatIndicator")

-- Drawing helpers

local function DrawBox(x, y, w, h, color, roundTop, roundBottom)
    draw.RoundedBoxEx(OVERHEAD_BOX_CORNER_RADIUS, x, y, w, h, color, roundTop, roundTop, roundBottom, roundBottom)
end

local function GetTextWidth(text, font)
    surface.SetFont(font)
    local width = surface.GetTextSize(text or "")
    return width
end

local function GetBoxWidth(name, job)
    local nameW = GetTextWidth(name, OVERHEAD_NAME_FONT)
    if OVERHEAD_SHOW_JOB then
        local jobW = GetTextWidth(job, OVERHEAD_INFO_FONT)
        return math.max(nameW, jobW) + OVERHEAD_BOX_MARGIN * 2
    end
    return nameW + OVERHEAD_BOX_MARGIN * 2
end

-- Plyer Caching

local playersToRender = {}

timer.Create("starks_overhead_player_cache", OVERHEAD_CACHE_INTERVAL, 0, function()
    playersToRender = {}
    local localPly = LocalPlayer()
    if not IsValid(localPly) then return end

    local myPos = localPly:GetPos()

    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or ply == localPly then continue end

        local success, plyPos = pcall(function() return ply:GetPos() end)
        if not success or not plyPos then continue end

        local distSq = myPos:DistToSqr(plyPos)
        if distSq <= OVERHEAD_DISTANCE^2 or ply:IsSpeaking() then
            table.insert(playersToRender, {
                ply = ply,
                pos = plyPos
            })
        end
    end
end)

-- Draw Hook

hook.Add("PostDrawTranslucentRenderables", "starks_overhead_hud", function()
    local localPly = LocalPlayer()
    if not IsValid(localPly) then return end

    local eyeAngles = localPly:EyeAngles()
    local myPos = localPly:GetPos()

    for _, entry in ipairs(playersToRender) do
        local ply = entry.ply
        local plyPos = entry.pos

        if not IsValid(ply) or not ply:Alive() or ply:IsDormant() then continue end

        local successEye, eyePos = pcall(function() return ply:EyePos() end)
        if not successEye or not eyePos then continue end

        if ply:GetColor().a < 100 or ply:GetNoDraw() then continue end

        local name  = ply:Nick()
        local job   = ply:getDarkRPVar("job") or "Unknown"
        local money = DarkRP.formatMoney(ply:getDarkRPVar("money") or 0)

        local distance = myPos:Distance(plyPos)
        local scale = distance * OVERHEAD_SCALE_MULT

        local width = GetBoxWidth(name, job)
        local x = -width / 2
        local y = 0
        local heightOffset = math.max((eyePos.z - plyPos.z) + scale * 35, OVERHEAD_MIN_HEIGHT)

        cam.Start3D2D(Vector(eyePos.x, eyePos.y, plyPos.z + heightOffset), Angle(0, eyeAngles.y - 90, 90), scale)
            DrawBox(x, y - OVERHEAD_HEADER_HEIGHT, width, OVERHEAD_HEADER_HEIGHT, OVERHEAD_HEADER_COLOR, true, false)
            DrawBox(x, y, width, OVERHEAD_BOX_HEIGHT, OVERHEAD_BOX_COLOR, false, true)

            local textX = x + OVERHEAD_BOX_MARGIN - 20

            draw.SimpleText(name, OVERHEAD_NAME_FONT, textX, y - OVERHEAD_HEADER_HEIGHT, OVERHEAD_TEXT_COLOR, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

            if OVERHEAD_SHOW_JOB then
                draw.SimpleText(job, OVERHEAD_INFO_FONT, textX, y + 2, OVERHEAD_TEXT_COLOR, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end

            if OVERHEAD_SHOW_MONEY then
                draw.SimpleText(money, OVERHEAD_INFO_FONT, textX, y + 20, OVERHEAD_TEXT_COLOR_MONEY, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
        cam.End3D2D()
    end
end)

print("[Starks HUD] Overhead loaded.")
