local starks_door_cfg = {
	boxColor = Color(40, 40, 40, 230),
	borderColor = Color(54, 57, 62, 255),
	headerColor = Color(55, 55, 55, 255),
	textColor = Color(255, 255, 255),
	accentColor = Color(0, 255, 157, 255),
	fontHeader = "starks_hud_header",
	fontMain = "starks_hud_main",
	fontButton = "starks_hud_button",
	boxWidth = 200,
	boxHeight = 120,
	headerHeight = 38,
	cornerRadius = 8,
	menuWidth = 320,
	menuHeight = 40,
	buttonHeight = 36,
	buttonMargin = 8,
}

surface.CreateFont(starks_door_cfg.fontHeader, {
	font = "Quicksand",
	size = 32,
	weight = 800,
})
surface.CreateFont(starks_door_cfg.fontMain, {
	font = "Nunito",
	size = 22,
	weight = 600,
})
surface.CreateFont(starks_door_cfg.fontButton, {
	font = "Nunito",
	size = 20,
	weight = 600,
})

local function starks_GetDoorInfo(door)
	if not IsValid(door) or not door:isKeysOwnable() then return nil end
	local info = {}
	info.title = door:getKeysTitle() or ""
	info.owner = door:getDoorOwner()
	info.owned = door:isKeysOwned()
	info.coowners = door:getKeysCoOwners() or {}
	info.group = door:getKeysDoorGroup()
	info.teams = door:getKeysDoorTeams()
	info.nonOwnable = door:getKeysNonOwnable()
	return info
end

local function starks_DrawDoorHUD(door)
	local info = starks_GetDoorInfo(door)
	if not info then return end

	-- Always place HUD on the side facing the player
	local obbCenter = door:OBBCenter()
	local doorForward = door:GetForward()
	local doorUp = door:GetUp()
	local worldCenter = door:LocalToWorld(obbCenter)
	local plyPos = LocalPlayer():EyePos()
	local toPlayer = (plyPos - worldCenter):GetNormalized()
	local facing = doorForward:Dot(toPlayer) > 0 and doorForward or -doorForward
	local pos = worldCenter + facing * 5 + doorUp * 18
	local ang = door:GetAngles()
	if facing == -doorForward then
		ang:RotateAroundAxis(ang:Up(), 180)
	end
	ang:RotateAroundAxis(ang:Right(), -90)
	ang:RotateAroundAxis(ang:Up(), 90)

	cam.Start3D2D(pos, ang, 0.15)
		-- Header box (NO_BL + NO_BR)
		RNDX.Draw(8, -starks_door_cfg.boxWidth/2, 0, starks_door_cfg.boxWidth, starks_door_cfg.headerHeight, starks_door_cfg.headerColor, RNDX.NO_BL + RNDX.NO_BR)
		-- Main box (NO_TL + NO_TR)
		RNDX.Draw(8, -starks_door_cfg.boxWidth/2, starks_door_cfg.headerHeight, starks_door_cfg.boxWidth, starks_door_cfg.boxHeight - starks_door_cfg.headerHeight, starks_door_cfg.boxColor, RNDX.NO_TL + RNDX.NO_TR)
		draw.SimpleText("DOOR", starks_door_cfg.fontHeader, 0, starks_door_cfg.headerHeight/2, starks_door_cfg.textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local y = starks_door_cfg.headerHeight + 12
		if info.owned then
			draw.SimpleText("Owner: " .. (IsValid(info.owner) and info.owner:Nick() or "Unknown"), starks_door_cfg.fontMain, 0, y, starks_door_cfg.textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			y = y + 28
			if info.title ~= "" then
				draw.SimpleText("Title: " .. info.title, starks_door_cfg.fontMain, 0, y, starks_door_cfg.textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
				y = y + 24
			end
			if next(info.coowners) then
				draw.SimpleText("Co-Owners:", starks_door_cfg.fontMain, 0, y, starks_door_cfg.textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
				y = y + 22
				for k, v in pairs(info.coowners) do
					local ply = Player(k)
					if IsValid(ply) then
						draw.SimpleText(ply:Nick(), starks_door_cfg.fontMain, 0, y, starks_door_cfg.textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
						y = y + 18
					end
				end
			end
		elseif info.group then
			draw.SimpleText("Group Door: " .. info.group, starks_door_cfg.fontMain, 0, y, starks_door_cfg.textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			y = y + 28
		elseif info.teams then
			draw.SimpleText("Team Door", starks_door_cfg.fontMain, 0, y, starks_door_cfg.textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			y = y + 24
			for k, v in pairs(info.teams) do
				if RPExtraTeams[k] then
					draw.SimpleText(RPExtraTeams[k].name, starks_door_cfg.fontMain, 0, y, starks_door_cfg.textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
					y = y + 18
				end
			end
		elseif not info.nonOwnable then
			draw.SimpleText("FOR SALE", starks_door_cfg.fontMain, 0, y, starks_door_cfg.accentColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			y = y + 24
			draw.SimpleText("Press F2 to Buy", starks_door_cfg.fontMain, 0, y, starks_door_cfg.textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	cam.End3D2D()
end

local starks_doorcache = {}
timer.Create("Starks_DoorsRefresh", 0.5, 0, function()
	local client = LocalPlayer()
	if not IsValid(client) then return end
	starks_doorcache = {}
	for _, v in ipairs(ents.FindInSphere(client:GetPos(), 300)) do
		if IsValid(v) and v:isDoor() and v:isKeysOwnable() then
			table.insert(starks_doorcache, v)
		end
	end
end)

hook.Add("PostDrawTranslucentRenderables", "Starks_DrawDoorsHUD", function()
	for _, door in ipairs(starks_doorcache) do
		starks_DrawDoorHUD(door)
	end
end)


local KeyFrameVisible = false
local function starks_OpenDoorMenu(setDoorOwnerAccess, doorSettingsAccess)
	if KeyFrameVisible then return end
	local trace = LocalPlayer():GetEyeTrace()
	local ent = trace.Entity
	if not IsValid(ent) or not ent:isKeysOwnable() or trace.HitPos:DistToSqr(LocalPlayer():EyePos()) > 40000 then return end

	KeyFrameVisible = true
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(240, 40)
	Frame:ShowCloseButton(false)
	Frame:SetVisible(true)
	Frame:MakePopup()
	Frame:ParentToHUD()
	Frame:SetTitle("")
	function Frame:Paint(w,h)
		-- Header box (NO_BL + NO_BR)
		RNDX.Draw(8, 0, 0, w, 38, starks_door_cfg.headerColor, RNDX.NO_BL + RNDX.NO_BR)
		-- Main box (NO_TL + NO_TR)
		RNDX.Draw(8, 0, 38, w, h-38, starks_door_cfg.boxColor, RNDX.NO_TL + RNDX.NO_TR)
		draw.SimpleText("DOOR MENU", starks_door_cfg.fontHeader, w/2, 19, starks_door_cfg.textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		-- Draw close button placeholder
		draw.SimpleText("X", starks_door_cfg.fontHeader, w-25, 19, Color(255,0,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	function Frame:Think()
		-- Don't close the menu if the console is open
		if gui.IsConsoleVisible and gui.IsConsoleVisible() then return end
		local tr = LocalPlayer():GetEyeTrace()
		local LAEnt = tr.Entity
		if not IsValid(LAEnt) or not LAEnt:isKeysOwnable() or tr.HitPos:DistToSqr(LocalPlayer():EyePos()) > 40000 then
			self:Close()
		end
		if not self.Dragging then return end
		local x = gui.MouseX() - self.Dragging[1]
		local y = gui.MouseY() - self.Dragging[2]
		x = math.Clamp(x, 0, ScrW() - self:GetWide())
		y = math.Clamp(y, 0, ScrH() - self:GetTall())
		self:SetPos(x, y)
	end

	function Frame:OnMousePressed(mcode)
		if mcode == MOUSE_LEFT then
			local mx, my = gui.MouseX() - Frame:GetX(), gui.MouseY() - Frame:GetY()
			if mx > Frame:GetWide()-44 and mx < Frame:GetWide()-4 and my > 4 and my < 34 then
				Frame:Close()
			end
		end
	end

	function Frame:Close()
		KeyFrameVisible = false
		self:SetVisible(false)
		self:Remove()
	end

	local y = 44
	local function AddButtonToFrame(text, callback, disabled)
		Frame:SetTall(Frame:GetTall() + 60)
		local button = vgui.Create("DButton", Frame)
		button:SetPos(10, Frame:GetTall() - 55)
		button:SetSize(220, 50)
		button:SetText(text)
		button:SetFont(starks_door_cfg.fontButton)
		button:SetTextColor(starks_door_cfg.textColor)
		button.DoClick = function()
			if callback then callback() end
			Frame:Close()
		end
		button.Paint = function(self,w,h)
			RNDX.Draw(8, 0, 0, w, h, self.Hovered and Color(66, 70, 77) or Color(47, 49, 54))
			draw.SimpleText(self:GetText(), starks_door_cfg.fontButton, w/2, h/2, starks_door_cfg.textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		if disabled then button:SetDisabled(true) end
		Frame.buttonCount = (Frame.buttonCount or 0) + 1
		Frame.lastButton = button
		return button
	end

	local entType = DarkRP.getPhrase(ent:IsVehicle() and "vehicle" or "door")

	if ent:isKeysOwnedBy(LocalPlayer()) then
		AddButtonToFrame(DarkRP.getPhrase("sell_x", entType), function() RunConsoleCommand("darkrp", "toggleown") end)
		AddButtonToFrame(DarkRP.getPhrase("add_owner"), function()
			local menu = DermaMenu()
			menu.found = false
			for _, v in pairs(DarkRP.nickSortedPlayers()) do
				if not ent:isKeysOwnedBy(v) and not ent:isKeysAllowedToOwn(v) then
					local steamID = v:SteamID()
					menu.found = true
					menu:AddOption(v:Nick(), function() RunConsoleCommand("darkrp", "ao", steamID) end)
				end
			end
			if not menu.found then
				menu:AddOption(DarkRP.getPhrase("noone_available"), function() end)
			end
			menu:Open()
		end)
		AddButtonToFrame(DarkRP.getPhrase("remove_owner"), function()
			local menu = DermaMenu()
			for _, v in pairs(DarkRP.nickSortedPlayers()) do
				if (ent:isKeysOwnedBy(v) and not ent:isMasterOwner(v)) or ent:isKeysAllowedToOwn(v) then
					local steamID = v:SteamID()
					menu.found = true
					menu:AddOption(v:Nick(), function() RunConsoleCommand("darkrp", "ro", steamID) end)
				end
			end
			if not menu.found then
				menu:AddOption(DarkRP.getPhrase("noone_available"), function() end)
			end
			menu:Open()
		end, not ent:isMasterOwner(LocalPlayer()))
	end

	if doorSettingsAccess then
		AddButtonToFrame(DarkRP.getPhrase(ent:getKeysNonOwnable() and "allow_ownership" or "disallow_ownership"), function() Frame:Close() RunConsoleCommand("darkrp", "toggleownable") end)
	end

	if doorSettingsAccess and (ent:isKeysOwned() or ent:getKeysNonOwnable() or ent:getKeysDoorGroup() or hasTeams) or ent:isKeysOwnedBy(LocalPlayer()) then
		AddButtonToFrame(DarkRP.getPhrase("set_x_title", entType), function()
			Derma_StringRequest(DarkRP.getPhrase("set_x_title", entType), DarkRP.getPhrase("set_x_title_long", entType), "", function(text)
				RunConsoleCommand("darkrp", "title", text)
				if IsValid(Frame) then
					Frame:Close()
				end
			end,
			function() end, DarkRP.getPhrase("ok"), DarkRP.getPhrase("cancel"))
		end)
	end

	if not ent:isKeysOwned() and not ent:getKeysNonOwnable() and not ent:getKeysDoorGroup() and not ent:getKeysDoorTeams() or not ent:isKeysOwnedBy(LocalPlayer()) and ent:isKeysAllowedToOwn(LocalPlayer()) then
		AddButtonToFrame(DarkRP.getPhrase("buy_x", entType), function() RunConsoleCommand("darkrp", "toggleown") end)
	end

	if doorSettingsAccess then
		AddButtonToFrame(DarkRP.getPhrase("edit_door_group"), function()
			local menu = DermaMenu()
			local groups = menu:AddSubMenu(DarkRP.getPhrase("door_groups"))
			local teams = menu:AddSubMenu(DarkRP.getPhrase("jobs"))
			local add = teams:AddSubMenu(DarkRP.getPhrase("add"))
			local remove = teams:AddSubMenu(DarkRP.getPhrase("remove"))

			menu:AddOption(DarkRP.getPhrase("none"), function()
				RunConsoleCommand("darkrp", "togglegroupownable")
				if IsValid(Frame) then Frame:Close() end
			end)

			for k in pairs(RPExtraTeamDoors) do
				groups:AddOption(k, function()
					RunConsoleCommand("darkrp", "togglegroupownable", k)
					if IsValid(Frame) then Frame:Close() end
				end)
			end

			local doorTeams = ent:getKeysDoorTeams()
			for k, v in pairs(RPExtraTeams) do
				local which = (not doorTeams or not doorTeams[k]) and add or remove
				which:AddOption(v.name, function()
					RunConsoleCommand("darkrp", "toggleteamownable", k)
					if IsValid(Frame) then Frame:Close() end
				end)
			end

			menu:Open()
		end)
	end

	if Frame.buttonCount == 1 then
		Frame.lastButton:DoClick()
	elseif Frame.buttonCount == 0 or not Frame.buttonCount then
		Frame:Close()
		KeyFrameVisible = true
		timer.Simple(0.3, function() KeyFrameVisible = false end)
	end

	hook.Call("onKeysMenuOpened", nil, ent, Frame)
	Frame:Center()
end

hook.Add("PlayerButtonDown", "Starks_DoorMenu_F2", function(ply, btn)
	if ply ~= LocalPlayer() then return end
	if btn == KEY_F2 then
		CAMI.PlayerHasAccess(LocalPlayer(), "DarkRP_SetDoorOwner", function(setDoorOwnerAccess)
			CAMI.PlayerHasAccess(LocalPlayer(), "DarkRP_ChangeDoorSettings", fp{starks_OpenDoorMenu, setDoorOwnerAccess})
		end)
		return true -- block default
	end
end)

hook.Add("HUDDrawDoorData", "starks_doorhud_disable_default", function(ent)
	return true -- block default
end)

-- Overwrite DarkRP.openKeysMenu to use our menu
hook.Add("PostGamemodeLoaded", "Starks_OverrideKeysMenu", function()
	function DarkRP.openKeysMenu(um)
		CAMI.PlayerHasAccess(LocalPlayer(), "DarkRP_SetDoorOwner", function(setDoorOwnerAccess)
			CAMI.PlayerHasAccess(LocalPlayer(), "DarkRP_ChangeDoorSettings", fp{starks_OpenDoorMenu, setDoorOwnerAccess})
		end)
	end
	net.Receive("KeysMenu", DarkRP.openKeysMenu)
end)

print("[Starks HUD] Doors loaded.")