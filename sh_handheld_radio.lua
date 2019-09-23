
ITEM.name = "Handheld Radio"
ITEM.model = Model("models/deadbodies/dead_male_civilian_radio.mdl")
ITEM.description = "A shiny handheld radio with a frequency tuner.\nIt is currently turned %s%s."
ITEM.cost = 50
ITEM.classes = {CLASS_EMP, CLASS_EOW}
ITEM.flag = "v"

-- Inventory drawing
if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
	
		if (item:GetData("enabled")) then
			surface.SetDrawColor(255, 255, 0, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
		
		if (item:GetData("active")) then
			surface.SetDrawColor(110, 200, 110, 255)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
		
		if (item:GetData("silenced") and item:GetData("enabled")) then
			surface.SetDrawColor(255, 255/4, 110/2, 200)
			surface.DrawRect(w - 14, h - 11, 9, 2)
		end
	end
end

function ITEM:GetDescription()
	local enabled = self:GetData("enabled")
	local ret = string.format(self.description, enabled and "on" or "off", enabled and (" and tuned to " .. self:GetData("frequency", "100.0")) or "")
	
	if (self:GetData("silenced") and enabled) then
		ret = ret .. " \nRadio tones are currently silenced."
	end
	if self:GetData("active") then
		ret = ret .. " \nYou are transmitting on this radio."
	end
	
	return ret
end

function ITEM.postHooks.drop(item, status)
	item:SetData("enabled", false)
	item:SetData("active",false)
end

ITEM.functions.Frequency = {
	OnRun = function(itemTable)
	
		local character = itemTable.player:GetCharacter()
		local radios = character:GetInventory():GetItemsByUniqueID("handheld_radio", true)
		local longranges = character:GetInventory():GetItemsByUniqueID("longrange", true)
		local bBreak = false
		
		-- Puts the long ranges in with regular radios
		if (#longranges > 0) then
			for k,v in pairs(longranges) do radios[#radios+1] = v end
		end
		
		if !itemTable:GetData("enabled") then 
			itemTable:SetData("enabled", true)
		end
			
		if (!itemTable:GetData("active")) then -- if the current radio is on...
			-- first deactivates all other active radios
			for k, v in ipairs(radios) do
				if (v != itemTable and v:GetData("enabled", false) and v:GetData("active",false)) then
					v:SetData("active",false)
					--bCanToggle = false
					--break
				end
			end
			
			itemTable:SetData("active",true)
			character:SetData("frequency",itemTable:GetData("frequency","000.0"))
		end
		--if (itemTable:GetData("enabled") and itemTable:GetData("active")) then
		netstream.Start(itemTable.player, "Frequency", itemTable:GetData("frequency", "000.0"))
		--else
		--	netstream.Start(itemTable, "Frequency", itemTable:GetData("frequency", "000.0"))
		--end

		return false
	end
}

ITEM.functions.Silence = {
	OnRun = function(itemTable)
		--netstream.Start(itemTable.player, "Frequency", itemTable:GetData("silenced", "000.0"))
		if (itemTable:GetData("enabled")) then
			itemTable:SetData("silenced", !itemTable:GetData("silenced", false))
			if itemTable:GetData("silenced") then
				itemTable.player:NotifyLocalized("You silenced the radio.")
			else
				itemTable.player:NotifyLocalized("You unsilenced the radio.")
			end
		end
		return false
	end
}

ITEM.functions.Toggle = {
	OnRun = function(itemTable)
		local character = itemTable.player:GetCharacter()
		local radios = character:GetInventory():GetItemsByUniqueID("handheld_radio", true)
		local longranges = character:GetInventory():GetItemsByUniqueID("longrange", true)
		local bCanToggle = true
		
		-- Puts the long ranges in with regular radios
		if (#longranges > 0) then
			for k,v in pairs(longranges) do radios[#radios+1] = v end
		end
		
		-- activates the radio if no other powered on radios are in inventory already
		local enabl = false
		for k, v in ipairs(radios) do
			if (v != itemTable and v:GetData("enabled", false)) then
				enabl = true
				break
			end
		end	
		
		-- for k, v in ipairs(longranges) do
			-- if (v != itemTable and v:GetData("enabled", false)) then
				-- bCanToggle = false
				-- break
			-- end
		-- end
		
		bCanToggle = true
		if (bCanToggle) then
			itemTable:SetData("enabled", !itemTable:GetData("enabled", false))

			-- Sets frequency to that of currently active radio
			if (itemTable:GetData("enabled",false)) then
				if !enabl then
					itemTable:SetData("active",true)
					character:SetData("frequency",itemTable:GetData("frequency","000.0"))
				end
			else
				character:SetData("frequency","")
				itemTable:SetData("active",false)
			end
			
			itemTable.player:EmitSound("buttons/lever7.wav", 50, math.random(170, 180), 0.25)
		else
			itemTable.player:NotifyLocalized("radioAlreadyOn")
		end

		return false
	end
}

ITEM.functions.Activate = {
	OnRun = function(itemTable)
		local character = itemTable.player:GetCharacter()
		local radios = character:GetInventory():GetItemsByUniqueID("handheld_radio", true)
		local longranges = character:GetInventory():GetItemsByUniqueID("longrange", true)
		local bCanToggle = true
		
		-- Puts the long ranges in with regular radios
		if (#longranges > 0) then
			for k,v in pairs(longranges) do radios[#radios+1] = v end
		end
		
		if (itemTable:GetData("enabled",false)) then -- if the current radio is on...
			-- first deactivates all other active radios
			for k, v in ipairs(radios) do
				if (v != itemTable and v:GetData("enabled", false) and v:GetData("active",false)) then
					v:SetData("active",false)
					--bCanToggle = false
					--break
				end
			end
			
			-- toggles current radio active status
			itemTable:SetData("active", !itemTable:GetData("active", false))
			if itemTable:GetData("active") then
				character:SetData("frequency",itemTable:GetData("frequency","000.0"))
				itemTable.player:NotifyLocalized("You activated the radio.")
			else
				character:SetData("frequency","")
				itemTable.player:NotifyLocalized("You deactivated the radio.")
			end
			
			-- -- Sets frequency to that of currently active radio
			-- if (itemTable:GetData("active",false)) then 
				-- character:SetData("frequency",itemTable:GetData("frequency","000.0"))
			-- else
				-- character:SetData("frequency","")
			-- end
			
			itemTable.player:EmitSound("buttons/lever8.wav", 50, math.random(170, 180), 0.25)
		--else
		--	itemTable.player:NotifyLocalized("radioAlreadyOn")
		end

		return false
	end
}
