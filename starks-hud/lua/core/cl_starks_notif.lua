--[[
  ____ _____  _    ____  _  ______    _   _ _   _ ____  
 / ___|_   _|/ \  |  _ \| |/ / ___|  | | | | | | |  _ \ 
 \___ \ | | / _ \ | |_) | ' /\___ \  | |_| | | | | | | |
  ___) || |/ ___ \|  _ <| . \ ___) | |  _  | |_| | |_| |
 |____/ |_/_/   \_|_| \_|_|\_|____/  |_| |_|\___/|____/ 

Made by:      Stuka
Discord:      stuka1808
--]]

local color_white = Color(255, 255, 255)
local notifBoxCol = Color(40,40,40)

local NOTIF_START_X = 0
local NOTIF_START_Y = 200
local NOTIF_WIDTH_PADDING = 20
local NOTIF_ICON_WIDTH = 32
local NOTIF_HEIGHT = 32
local NOTIF_ROUNDED = 8
local NOTIF_ICON_X_OFFSET = 16
local NOTIF_TEXT_X_OFFSET = 42 -- 32 + 10
local NOTIF_ICON_FONT = "StarksHUDNotifsIcons"
local NOTIF_TEXT_FONT = "StarksHUDNotif"
local NOTIF_PROGRESS_FONT = "StarksFontNotifProgress"
local NOTIF_LERP_SPEED = 10
local NOTIF_VERTICAL_SPACING = 5
local NOTIF_REMOVE_OFFSET = 10

local IconGlyphs = {}
IconGlyphs[NOTIFY_GENERIC]   = "A"
IconGlyphs[NOTIFY_ERROR]     = "B"
IconGlyphs[NOTIFY_UNDO]      = "C"
IconGlyphs[NOTIFY_HINT]      = "D"
IconGlyphs[NOTIFY_CLEANUP]   = "E"

local LoadingIcon = "E"

local Notifications = {}

-- draw function
local function DrawNotification(x, y, w, h, text, iconGlyph, col, progress)
    draw.RoundedBox(NOTIF_ROUNDED, x, y, w, h, col)

    draw.SimpleText(iconGlyph, NOTIF_ICON_FONT, x + NOTIF_ICON_X_OFFSET, y + h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(text, NOTIF_TEXT_FONT, x + NOTIF_TEXT_X_OFFSET, y + h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

-- Add Legacy Notification
function notification.AddLegacy(text, type, time)
    surface.SetFont(NOTIF_TEXT_FONT)
    table.insert(Notifications, 1, {
        x = ScrW(),
        y = ScrH() - NOTIF_START_Y,
        w = surface.GetTextSize(text) + NOTIF_WIDTH_PADDING + NOTIF_ICON_WIDTH,
        h = NOTIF_HEIGHT,
        text = text,
        col = notifBoxCol,
        iconGlyph = IconGlyphs[type] or "A",
        time = CurTime() + time,
        progress = nil,
    })
end

-- Add Progress Notification
function notification.AddProgress(id, text, frac)
    for k, v in ipairs(Notifications) do
        if v.id == id then
            v.text = text
            v.progress = frac
            return
        end
    end
    surface.SetFont(NOTIF_PROGRESS_FONT)
    table.insert(Notifications, 1, {
        x = ScrW(),
        y = ScrH() - NOTIF_START_Y,
        w = surface.GetTextSize(text) + NOTIF_WIDTH_PADDING + NOTIF_ICON_WIDTH,
        h = NOTIF_HEIGHT,
        id = id,
        text = text,
        col = notifBoxCol,
        icon = LoadingIcon,
        time = math.huge,
        progress = math.Clamp(frac or 0, 0, 1),
    })
end

-- Kill Progress Notification
function notification.Kill(id)
    for k, v in ipairs(Notifications) do
        if v.id == id then
            v.time = 0
        end
    end
end

-- Paint Notifications
hook.Add("HUDPaint", "starks_hud_notifications", function()
    for k, v in ipairs(Notifications) do
        DrawNotification(v.x, v.y, v.w, v.h, v.text, v.iconGlyph, v.col, v.progress)

        v.x = Lerp(FrameTime() * NOTIF_LERP_SPEED, v.x, v.time > CurTime() and ScrW() - v.w - NOTIF_REMOVE_OFFSET or ScrW() + 1)
        v.y = Lerp(FrameTime() * NOTIF_LERP_SPEED, v.y, (ScrH() - NOTIF_START_Y) - (k - 1) * (v.h + NOTIF_VERTICAL_SPACING))

        if v.x >= ScrW() and v.time < CurTime() then
            table.remove(Notifications, k)
        end
    end
end)

print("[Starks HUD] Notifications Loaded")