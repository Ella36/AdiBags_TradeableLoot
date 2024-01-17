--[[

The MIT License (MIT)

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
-- Retrive addon folder name, and our private addon namespace.
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

-- WoW API
-----------------------------------------------------------
local CreateFrame = _G.CreateFrame
local GetItemInfo = _G.GetItemInfo
local C_Item_GetItemInventoryTypeByID = C_Item and C_Item.GetItemInventoryTypeByID
local C_TooltipInfo_GetBagItem = C_TooltipInfo and C_TooltipInfo.GetBagItem

-- WoW Constants
-----------------------------------------------------------
local S_ITEM_BOP = ITEM_SOULBOUND
local S_ITEM_BOA = ITEM_ACCOUNTBOUND
local S_ITEM_BOA2 = ITEM_BNETACCOUNTBOUND
local S_ITEM_BOA3 = ITEM_BIND_TO_BNETACCOUNT
local S_ITEM_BOE = ITEM_BIND_ON_EQUIP
local N_BANK_CONTAINER = BANK_CONTAINER

-- Addon Constants
-----------------------------------------------------------
local S_BOA = "BoA"
local S_BOE = "BoE"
local S_BOP = "BoP"

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
L["Bound"] = true                                              -- uiName
L["Put BoA, BoE, and BoP items in their own sections."] = true -- uiDesc

-- Options
L["Enable BoE"] = true
L["Check this if you want a section for BoE items."] = true
L["Enable BoA"] = true
L["Check this if you want a section for BoA items."] = true
L["Enable Soulbound"] = true
L["Check this if you want a section for BoP items."] = true
L["Filter Poor/Common BoE"] = true
L["Also filter Poor (gray) and Common (white) quality BoE items."] = true
L["Only Equipable"] = true
L["Only filter equipable soulbound items."] = true
L["Soulbound"] = true

-- Categories
L[S_BOA] = true
L[S_BOE] = true
L[S_BOP] = "Soulbound"

if (GetLocale() == "zhCN") then
	L["Bound"] = "绑定"
	L["Put BoA, BoE, and BoP items in their own sections."] = "将 BoA、BoE 和 BoP 项目放在各自的部分中。"

	L["Also filter Poor (gray) and Common (white) quality BoE items."] = "还可以过滤质量较差（灰色）和普通（白色）的 BoE 项目。"
	L["Check this if you want a section for BoA items."] = "如果您想要 BoA 商品的部分，请选中此选项。"
	L["Check this if you want a section for BoE items."] = "如果您想要BoE项目的部分，请选中此项。"
	L["Check this if you want a section for BoP items."] = "如果您想要BoP项目的部分，请选中此项。"
	L["Enable BoA"] = "启用BoA"
	L["Enable BoE"] = "启用BoE"
	L["Enable Soulbound"] = "启用灵魂绑定"
	L["Filter Poor/Common BoE"] = "过滤白色垃圾/普通BoE"
	L["Only Equipable"] = "仅可装备"
	L["Only filter equipable soulbound items."] = "只过滤装备齐全的灵魂物品。"
	L["Soulbound"] = "灵魂绑定"

	L[S_BOA] = true
	L[S_BOE] = true
	L[S_BOP] = "灵魂绑定"
end

-- Private Default API
-- This mostly contains methods we always want available
-----------------------------------------------------------

--- Whether we have C_TooltipInfo APIs available
addon.IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE


-----------------------------------------------------------
-- Filter Setup
-----------------------------------------------------------

-- Register our filter with AdiBags
local filter = AdiBags:RegisterFilter("Bound", 70, "ABEvent-1.0")
filter.uiName = L["Bound"]
filter.uiDesc = L["Put BoA, BoE, and BoP items in their own sections."]

function filter:OnInitialize()
	-- Register the settings namespace
	self.db = AdiBags.db:RegisterNamespace(self.filterName, {
		profile = {
			enableBoE = true,
			grayAndWhiteBoE = false,
			enableBoA = true,
			enableBoP = false,
			onlyEquipableBoP = true,
		},
	})
end

-- Setup options panel
function filter:GetOptions()
	return {
		enableBoE = {
			name = L["Enable BoE"],
			desc = L["Check this if you want a section for BoE items."],
			type = "toggle",
			width = "double",
			order = 10,
		},
		grayAndWhiteBoE = {
			name = L["Filter Poor/Common BoE"],
			desc = L["Also filter Poor (gray) and Common (white) quality BoE items."],
			type = "toggle",
			width = "double",
			order = 15,
		},
		enableBoA = {
			name = L["Enable BoA"],
			desc = L["Check this if you want a section for BoA items."],
			type = "toggle",
			width = "double",
			order = 20,
		},
		bound = {
			name = L["Soulbound"],
			desc = "Soulbound stuff",
			type = "group",
			inline = true,
			args = {
				enableBoP = {
					name = L["Enable Soulbound"],
					desc = L["Check this if you want a section for BoP items."],
					type = "toggle",
					order = 10,
				},
				onlyEquipableBoP = {
					name = L["Only Equipable"],
					desc = L["Only filter equipable soulbound items."],
					type = "toggle",
					order = 20,
					disabled = function() return not self.db.profile.enableBoP end,
				},
			},
		},
	}, AdiBags:GetOptionHandler(self, true, function() return self:Update() end)
end

function filter:Update()
	-- Notify myself that the filtering options have changed
	self:SendMessage("AdiBags_FiltersChanged")
end

function filter:OnEnable()
	AdiBags:UpdateFilters()
end

function filter:OnDisable()
	AdiBags:UpdateFilters()
end

-----------------------------------------------------------
-- Actual filter
-----------------------------------------------------------

-- Tooltip used for scanning.
-- Let's keep this name for all scanner addons.
local _SCANNER = "AVY_ScannerTooltip"
local Scanner
if not addon.IsRetail then
	-- This is not needed on WoW10, since we can use C_TooltipInfo
	Scanner = _G[_SCANNER] or CreateFrame("GameTooltip", _SCANNER, UIParent, "GameTooltipTemplate")
end

function filter:Filter(slotData)
	local bag, slot, quality, itemId = slotData.bag, slotData.slot, slotData.quality, slotData.itemId
	local _, _, _, _, _, _, _, _, _, _, _, _, _, bindType, _, _, _ = GetItemInfo(itemId)

	-- Only parse items that are Common (1) and above, and are of type BoP, BoE, and BoU
	local junk = quality ~= nil and quality == 0
	if (not junk or (junk and self.db.profile.grayAndWhiteBoE)) or (bindType ~= nil and bindType > 0 and bindType < 4) then
		local category = self:GetItemCategory(bag, slot)
		return self:GetCategoryLabel(category, itemId)
	end
end

function filter:GetItemCategory(bag, slot)
	local category = nil

	local function GetBindType(msg)
		if (msg) then
			if (string_find(msg, S_ITEM_BOP)) then
				return S_BOP
			elseif (string_find(msg, S_ITEM_BOA) or string_find(msg, S_ITEM_BOA2) or string_find(msg, S_ITEM_BOA3)) then
				return S_BOA
			elseif (string_find(msg, S_ITEM_BOE)) then
				return S_BOE
			end
		end
	end

	if (addon.IsRetail) then
		local tooltipInfo = C_TooltipInfo_GetBagItem(bag, slot)
		if not tooltipInfo then return end
		for i = 2, 4 do
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
		for i = 2, 4 do
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
	elseif (category == S_BOA) and self.db.profile.enableBoA then
		return L[S_BOA]
	elseif (category == S_BOP) and self.db.profile.enableBoP then
		if (self.db.profile.onlyEquipableBoP) then
			if (self:IsItemEquipable(itemId)) then
				return L[S_BOP]
			end
		else
			return L[S_BOP]
		end
	end
end

function filter:IsItemEquipable(itemId)
	-- Inventory type 0 is INVTYPE_NON_EQUIP: Non-equipable
	return not (C_Item_GetItemInventoryTypeByID(itemId) == 0)
end
