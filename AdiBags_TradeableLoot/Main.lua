--[[

The MIT License (MIT)

Copyright (c) 2023 Ella36
Copyright (c) 2022 Lucas Vienna (Avyiel) <dev@lucasvienna.dev>
Copyright (c) 2021 Lars Norberg
Copyright (c) 2016 Spanky
Copyright (c) 2012 Kevin (Outroot) <kevin@outroot.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]
-- Retrieve addon folder name, and our private addon namespace.
---@type string
local addonName, addon = ...

-- AdiBags namespace
-----------------------------------------------------------
local AdiBags = LibStub("AceAddon-3.0"):GetAddon("AdiBags")

-- Lua API
-----------------------------------------------------------
local _G = _G
local string_find = string.find
local setmetatable = setmetatable
local rawget = rawget
local rawset = rawset

-- Helpers function
-----------------------------------------------------------
local function split(s, sep)
    local fields = {}
    
    local sep = sep or " "
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)
    
    return fields
end

local function startswith(s, start)
    return string.sub(s, 1, #start) == start
end

-- WoW API
-----------------------------------------------------------
local CreateFrame = _G.CreateFrame
local GetItemInfo = _G.GetItemInfo
local C_Item_GetItemInventoryTypeByID = C_Item and C_Item.GetItemInventoryTypeByID
local C_TooltipInfo_GetBagItem = C_TooltipInfo and C_TooltipInfo.GetBagItem

-- WoW Constants
-----------------------------------------------------------
local S_ITEM_BOE = ITEM_BIND_ON_EQUIP
local S_ITEM_TIMER_FORMAT = string.format(BIND_TRADE_TIME_REMAINING, "|")
local S_ITEM_TIMER_SPLIT = split(S_ITEM_TIMER_FORMAT, "|")
local S_ITEM_TIMER = S_ITEM_TIMER_SPLIT[1]
local N_BANK_CONTAINER = BANK_CONTAINER

-- Addon Constants
-----------------------------------------------------------
local S_BOE = "BoE"
local S_TIMER = "Timer"

-- Localization system
-----------------------------------------------------------
-- Set the locale metatable to simplify L[key] = true
local L = setmetatable({}, {
	__index = function(self, key)
		if not self[key] then
			--@debug@
			print("Missing loc: " .. key)
			--@end-debug@
			rawset(self, key, tostring(key))
			return tostring(key)
		end
		return rawget(self, key)
	end,
	__newindex = function(self, key, value)
		if value == true then
			rawset(self, key, tostring(key))
		else
			rawset(self, key, tostring(value))
		end
	end,
})

-- If we eventually localize this addon, then GetLocale() and some elseif's will
-- come into play here. For now, only enUS
L["TradeableLoot"] = true                                              -- uiName
L["Put BoE and items with a loot Timer in their own sections."] = true -- uiDesc

-- Categories
L[S_BOE] = true
L[S_TIMER] = true

-- Private Default API
-- This mostly contains methods we always want available
-----------------------------------------------------------

--- Whether we have C_TooltipInfo APIs available
addon.IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE


-----------------------------------------------------------
-- Filter Setup
-----------------------------------------------------------

-- Register our filter with AdiBags
local filter = AdiBags:RegisterFilter("TradeableLoot", 70, "ABEvent-1.0")
filter.uiName = L["TradeableLoot"]
filter.uiDesc = L["Put BoE and items with a loot Timer in their own sections."]

function filter:OnInitialize()
	-- Register the settings namespace
	self.db = AdiBags.db:RegisterNamespace(self.filterName, {
		profile = {
			enableBoE = true,
			enableTimer = true,
		},
	})
end

-----------------------------------------------------------
-- Actual filter
-----------------------------------------------------------

-- Tooltip used for scanning.
-- Let's keep this name for all scanner addons.
local _SCANNER = "TradeableLoot_ScannerTooltip"
local Scanner
if not addon.IsRetail then
	-- This is not needed on WoW10, since we can use C_TooltipInfo
	Scanner = _G[_SCANNER] or CreateFrame("GameTooltip", _SCANNER, UIParent, "GameTooltipTemplate")
end

function filter:Filter(slotData)
	local bag, slot, quality, itemId = slotData.bag, slotData.slot, slotData.quality, slotData.itemId
	local _, _, _, _, _, _, _, _, _, _, _, _, _, bindType, _, _, _ = GetItemInfo(itemId)

	-- Only parse items that are Uncommon (2) and above, and are of type BoP, BoE
	local junk = quality ~= nil and quality <= 1
	if (not junk) or (bindType ~= nil and bindType > 0 and bindType < 3) then
		local category = self:GetItemCategory(bag, slot)
		return self:GetCategoryLabel(category, itemId)
	end
end


function filter:GetItemCategory(bag, slot)
	local category = nil

	local function GetBindType(msg)
		if (msg) then
			if (string_find(msg, S_ITEM_BOE)) then
				return S_BOE
			elseif (startswith(msg, S_ITEM_TIMER)) then
				return S_TIMER
			end
		end
	end

	if (addon.IsRetail) then
		-- Untested with S_ITEM_TIMER
		local tooltipInfo = C_TooltipInfo_GetBagItem(bag, slot)
		for i=2,#tooltipInfo.lines do
			local line = tooltipInfo.lines[i]
			if (not line) then
				break
			end


			local bind = GetBindType(line.leftText)
			if (bind) then
				category = bind
				break
			end
		end
	else
		Scanner.owner = self
		Scanner.bag = bag
		Scanner.slot = slot
		Scanner:ClearLines()
		Scanner:SetOwner(UIParent, "ANCHOR_NONE")
		if bag == N_BANK_CONTAINER then
			Scanner:SetInventoryItem("player", BankButtonIDToInvSlotID(slot, nil))
		else
			Scanner:SetBagItem(bag, slot)
		end
		for i=2,_G[_SCANNER]:NumLines() do
			local line = _G[_SCANNER .. "TextLeft" .. i]
			if (not line) then
				break
			end
			local bind = GetBindType(line:GetText())
			if (bind) then
				category = bind
				break
			end
		end
		Scanner:Hide()
	end

	return category
end

function filter:GetCategoryLabel(category, itemId)
	if not category then return nil end

	if (category == S_BOE) and self.db.profile.enableBoE then
		return L[S_BOE]
	elseif (category == S_TIMER) and self.db.profile.enableTimer then
		return L[S_TIMER]
	end
end
