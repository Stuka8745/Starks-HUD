--[[
  ____ _____  _    ____  _  ______    _   _ _   _ ____  
 / ___|_   _|/ \  |  _ \| |/ / ___|  | | | | | | |  _ \ 
 \___ \ | | / _ \ | |_) | ' /\___ \  | |_| | | | | | | |
  ___) || |/ ___ \|  _ <| . \ ___) | |  _  | |_| | |_| |
 |____/ |_/_/   \_|_| \_|_|\_|____/  |_| |_|\___/|____/ 

Made by:      Stuka
Discord:      stuka1808
--]]

local hungerModEnabled = false
local hmPad = 0

hook.Add("InitPostEntity","starks_hunder",function()
    if not DarkRP.disabledDefaults["modules"]["hungermod"] then
        hungerModEnabled = true
        hmPad = 30
        print("[STARKS HUD] hungermod support enabled")
    end
end)

-- Disable default HUD elements
local disabledHUD = {
    ["DarkRP_HUD"]          = true,
    ["DarkRP_LocalPlayerHUD"] = true,
    ["CHudBattery"]         = true,
    ["CHudHealth"]          = true,
    ["DarkRP_Hungermod"]    = true,
    ["ChudSecondaryAmmo"]   = true,
    ["CHudAmmo"]            = true,
}

hook.Add("HUDShouldDraw","starks_disableDefaultHud",function(vs)
    if disabledHUD[vs] then return false end
end)

-- Base resolution reference
local baseResW = 1920
local baseResH = 1080

-- Screen dimensions
local scrw = ScrW()
local scrh = ScrH()

-- HUD positioning
local startX = math.Round(20*(scrw/baseResW))
local startY = math.Round(scrh-(140*(scrh/baseResH)))

-- HUD sizing
local baseW = 300
local baseH = 120

-- Header sizing
local headerH = baseH - 85

-- Bar dimensions
local barX = 8
local barY = startY + 90
local maxBarSize = 260
local barH = 8

-- HUD colors
local backgroundCol     = Color(40,40,40,255)
local headerCol         = Color(55,55,55,255)
local avatarCol         = Color(60,60,60)
local color_blk         = Color(0,0,0)
local color_wht         = Color(255,255,255)
local hpCol             = Color(255,99,99,255)
local armorCol          = Color(91,208,255,255)
local hungerCol         = Color(255,165,47,255)
local backgroundBarCol  = Color(100,100,100,255)
local moneyCol          = Color(0,255,157)
local iconCol           = Color(255,255,255,255)
local notWantedCol     = Color(126, 126, 126)
local wantedCol         = Color(255, 237, 75)

-- Main HUD paint hook
hook.Add("HUDPaint","starks_hud",function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    -- RNDX Flags
    local headerFlags = RNDX.NO_BL + RNDX.NO_BR -- Header
    local mainBoxFlags = RNDX.NO_TL + RNDX.NO_TR -- Main Box
    local mainAmmoBoxFlags = RNDX.NO_TL + RNDX.NO_TR -- Ammo Main Box
    local ammoBoxHeaderFlags = RNDX.NO_BL + RNDX.NO_BR -- Ammo Header
    local agendaMainBoxFlags = RNDX.NO_TL + RNDX.NO_TR -- Agenda Main Box
    local agendaHeaderFlags = RNDX.NO_BL + RNDX.NO_BR -- Agenda Header

    -- Header box
    RNDX.Draw(8, startX, startY-35, baseW, headerH, headerCol, headerFlags)

    -- Main HUD box
    if hungerModEnabled then
        RNDX.Draw(8, startX, startY, baseW, baseH, backgroundCol, mainBoxFlags)
    else
        RNDX.Draw(8, startX, startY, baseW, baseH-10, backgroundCol, mainBoxFlags)
    end

    -- Player name
    draw.SimpleText(ply:Nick(),"StarksFontHUD",startX+15,startY-18,color_wht,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)

    -- Player job
    draw.SimpleText(ply:getDarkRPVar("job"),"StarksFontHUD",startX+15,startY+20,color_wht,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)

    -- Money and salary
    local money = DarkRP.formatMoney(ply:getDarkRPVar("money") or 0)
    local salary = ply:getDarkRPVar("salary") or 0
    draw.SimpleText(money .. " + " .. salary, "StarksFontHUD", startX + 15, startY + 50, moneyCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Health bar
    RNDX.Draw(12, startX+30, barY-18, maxBarSize, barH, backgroundBarCol)
    RNDX.Draw(12, startX+30, barY-18, math.Clamp((ply:Health() * maxBarSize) / ply:GetMaxHealth(), 0, maxBarSize), barH, hpCol)
    draw.SimpleText("A","StarksHUDIcons",startX+11,barY-20,hpCol)

    -- Armor bar
    RNDX.Draw(12, startX+30, barY-2, maxBarSize, barH, backgroundBarCol)
    RNDX.Draw(12, startX+30, barY-2, math.Clamp((ply:Armor() / 100) * maxBarSize, 0, maxBarSize), barH, armorCol)
    draw.SimpleText("B","StarksHUDIcons",startX+10,barY-4,armorCol)


    if hungerModEnabled then
        RNDX.Draw(12, startX+30, barY+14, maxBarSize, barH, backgroundBarCol)
        draw.SimpleText("C","StarksHUDIcons",startX+10,barY+12,hungerCol)
        RNDX.Draw(12, startX+30, barY+14, ((LocalPlayer():getDarkRPVar("Energy")*maxBarSize)/100), barH, hungerCol)
    end

    -- Weapon display
    local wep = ply:GetActiveWeapon()
    if wep:IsValid() then
        local veh = ply:GetVehicle()
        if IsValid(veh) and not ply:GetAllowWeaponsInVehicle() then return end

        local wep_name = wep:GetPrintName() or wep:GetClass() or "Unknown"
        local ammo_type = wep:GetPrimaryAmmoType()

        if ammo_type == -1 then
            RNDX.Draw(8,scrw-245,startY+20,200,30,headerCol, ammoBoxHeaderFlags)
            RNDX.Draw(8,scrw-245,startY+50,200,70,backgroundCol, mainAmmoBoxFlags)
            draw.SimpleText(wep_name,"StarksFontHUD",scrw-235,scrh-105,color_wht,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
        else
            RNDX.Draw(8,scrw-245,startY+20,200,30,headerCol, ammoBoxHeaderFlags)
            RNDX.Draw(8,scrw-245,startY+50,200,70,backgroundCol, mainAmmoBoxFlags)
            draw.SimpleText(wep_name,"StarksFontHUD",scrw-235,scrh-105,color_wht,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
            draw.SimpleText(wep:Clip1().." / "..ply:GetAmmoCount(ammo_type),"StarksFontAmmo",scrw-150,scrh-80,color_wht,TEXT_ALIGN_CENTER)
        end
    end

    -- Agenda display
    local agenda = ply:getAgendaTable()
    if agenda then
        local agendaText = DarkRP.textWrap((ply:getDarkRPVar("agenda") or ""):gsub("//", "\n"):gsub("\\n", "\n"), "DarkRPHUD1", 440)

        RNDX.Draw(8, startX, startY-875, baseW+160, baseH+30, backgroundCol, agendaMainBoxFlags)
        RNDX.Draw(8, startX, startY-910, baseW+160, baseH-85, headerCol, agendaHeaderFlags)

        draw.SimpleText(agenda.Title, "StarksFontHUD", startX+10, startY-910, color_wht, 0)
        draw.SimpleText(agendaText, "StarksFontAgenda", startX+20, startY-875, color_wht, 0)
    end

    -- Wanted display
    if ply:getDarkRPVar("wanted") then
        draw.SimpleText("E", "StarksHUDWanted", startX + 270, startY - 17, color_wht, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    else
        draw.SimpleText("E", "StarksHUDWanted", startX+270, startY - 17, notWantedCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    
    end

    if ply:getDarkRPVar("HasGunlicense") then
        draw.SimpleText("D", "StarksHUDLicense", startX + 240, startY - 16, color_wht, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    else
        draw.SimpleText("D", "StarksHUDLicense", startX + 240, startY - 16, notWantedCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    if ply:getDarkRPVar("Arrested") then
        draw.SimpleText("F", "StarksHUDArrested", startX + 210, startY - 16, color_wht, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    else
        draw.SimpleText("F", "StarksHUDArrested", startX + 210, startY - 16, notWantedCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    end


end)

print("[Starks HUD] HUD Loaded")
