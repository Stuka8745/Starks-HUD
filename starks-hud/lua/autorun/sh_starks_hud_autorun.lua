
if SERVER then
    resource.AddSingleFile("resource/fonts/Quicksand.ttf")
    resource.AddSingleFile("resource/fonts/StarksHUDIcons")
    AddCSLuaFile("core/cl_starks_doors.lua")
    AddCSLuaFile("misc/cl_starks_hud_fonts.lua")
    AddCSLuaFile("sh_starks_hud_cfg.lua")
    AddCSLuaFile("core/cl_starks_hud.lua")
    AddCSLuaFile("core/cl_starks_overhead.lua")
    AddCSLuaFile("core/cl_starks_notif.lua")
else
    RNDX = include("misc/cl_rndx.lua")
    include("core/cl_starks_doors.lua")
    include("misc/cl_starks_hud_fonts.lua")
    include("sh_starks_hud_cfg.lua")
    include("core/cl_starks_hud.lua")
    include("core/cl_starks_overhead.lua")
    include("core/cl_starks_notif.lua")
end

