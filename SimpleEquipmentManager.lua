local ADDON_NAME = ...
local SEM = CreateFrame("Frame")

local DB

local SLOT_IDS = {
    1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18
}

local ICON_CHOICES = {}

local button
local panel
local rows = {}
local createSetFrame
local selectedIconIndex = 1
local editingSetId
local characterFrameHooked = false
local VISIBLE_ROWS = 8
local ROW_HEIGHT = 24
local ROW_SPACING = 4
local ICON_CELL = 26
local ICON_COLS = 9
local ICON_VISIBLE_ROWS = 6
local ICON_ROW_HEIGHT = 28
local iconGridRows = {}
local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

local TEX_TAB_HIGHLIGHT = "Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight"
local PANEL_WIDTH = 222
local PANEL_HEIGHT = 300

local CHROME_BG_COLOR = { 0.12, 0.12, 0.12, 0.95 }
local ROW_COLOR = { 0.35, 0.35, 0.35, 0.12 }
local ROW_HOVER_COLOR = { 0.5, 0.5, 0.5, 0.38 }

local TEX_GEAR_MANAGER_BORDER = "Interface\\PaperDollInfoFrame\\UI-GearManager-Border"
local TEX_GEAR_MANAGER_TITLE = "Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background"
local TEX_TOOLTIP_BG = "Interface\\Tooltips\\UI-Tooltip-Background"
local BORDER_CORNER = 64
-- Inner fill/title insets matched to AceGUI gear-manager window (Blizzard layout).
local CHROME_FILL_LEFT = 8
local CHROME_FILL_TOP = 24
local CHROME_FILL_RIGHT = 6
local CHROME_FILL_BOTTOM = 8
local CHROME_TITLE_RIGHT = 28
local CHROME_TITLE_HEIGHT = 24

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SEM|r: " .. msg)
end

local function DesaturateTexture(tex)
    if tex and tex.SetDesaturated then
        tex:SetDesaturated(true)
    end
end

-- Nine-slice gear-manager border (same ornate edges as Blizzard's equipment UI / character-adjacent panels).
local function CreateGearManagerBorderPiece(frame, name)
    local tex = frame:CreateTexture(name, "BORDER")
    tex:SetTexture(TEX_GEAR_MANAGER_BORDER)
    return tex
end

local function ApplyGearManagerBorder(frame, namePrefix)
    if frame.gearBorder then
        return
    end

    namePrefix = namePrefix or "SEM"
    local tl = CreateGearManagerBorderPiece(frame, namePrefix .. "BorderTopLeft")
    tl:SetWidth(BORDER_CORNER)
    tl:SetHeight(BORDER_CORNER)
    tl:SetPoint("TOPLEFT")
    tl:SetTexCoord(0.501953125, 0.625, 0, 1)

    local tr = CreateGearManagerBorderPiece(frame, namePrefix .. "BorderTopRight")
    tr:SetWidth(BORDER_CORNER)
    tr:SetHeight(BORDER_CORNER)
    tr:SetPoint("TOPRIGHT")
    tr:SetTexCoord(0.625, 0.75, 0, 1)

    local top = CreateGearManagerBorderPiece(frame, namePrefix .. "BorderTop")
    top:SetHeight(BORDER_CORNER)
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT")
    top:SetPoint("TOPRIGHT", tr, "TOPLEFT")
    top:SetTexCoord(0.25, 0.369140625, 0, 1)

    local bl = CreateGearManagerBorderPiece(frame, namePrefix .. "BorderBottomLeft")
    bl:SetWidth(BORDER_CORNER)
    bl:SetHeight(BORDER_CORNER)
    bl:SetPoint("BOTTOMLEFT")
    bl:SetTexCoord(0.751953125, 0.875, 0, 1)

    local br = CreateGearManagerBorderPiece(frame, namePrefix .. "BorderBottomRight")
    br:SetWidth(BORDER_CORNER)
    br:SetHeight(BORDER_CORNER)
    br:SetPoint("BOTTOMRIGHT")
    br:SetTexCoord(0.875, 1, 0, 1)

    local bottom = CreateGearManagerBorderPiece(frame, namePrefix .. "BorderBottom")
    bottom:SetHeight(BORDER_CORNER)
    bottom:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT")
    bottom:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
    bottom:SetTexCoord(0.376953125, 0.498046875, 0, 1)

    local left = CreateGearManagerBorderPiece(frame, namePrefix .. "BorderLeft")
    left:SetWidth(BORDER_CORNER)
    left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT")
    left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT")
    left:SetTexCoord(0.001953125, 0.125, 0, 1)

    local right = CreateGearManagerBorderPiece(frame, namePrefix .. "BorderRight")
    right:SetWidth(BORDER_CORNER)
    right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT")
    right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
    right:SetTexCoord(0.1171875, 0.2421875, 0, 1)

    frame.gearBorder = true
end

-- Gear-manager border + title band + fill (equipment panel, create/edit set dialog).
local function ApplyCharacterPanelChrome(frame, borderPrefix)
    if frame.SetBackdrop then
        frame:SetBackdrop(nil)
    end

    ApplyGearManagerBorder(frame, borderPrefix)

    if not frame.bgFill then
        frame.bgFill = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
        frame.bgFill:SetTexture(TEX_TOOLTIP_BG)
    end
    frame.bgFill:ClearAllPoints()
    frame.bgFill:SetPoint("TOPLEFT", CHROME_FILL_LEFT, -CHROME_FILL_TOP)
    frame.bgFill:SetPoint("BOTTOMRIGHT", -CHROME_FILL_RIGHT, CHROME_FILL_BOTTOM)
    frame.bgFill:SetVertexColor(CHROME_BG_COLOR[1], CHROME_BG_COLOR[2], CHROME_BG_COLOR[3], CHROME_BG_COLOR[4])

    if not frame.titleBg then
        frame.titleBg = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
    end
    frame.titleBg:SetTexture(TEX_GEAR_MANAGER_TITLE)
    frame.titleBg:ClearAllPoints()
    frame.titleBg:SetPoint("TOPLEFT", 9, -6)
    frame.titleBg:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -CHROME_TITLE_RIGHT, -CHROME_TITLE_HEIGHT)
    frame.titleBg:SetVertexColor(1, 1, 1, 1)
end

-- Sidecar attached to the character frame's right edge (does not cover gear/stats).
local function UpdatePanelLayout()
    if not panel or not CharacterFrame then
        return
    end

    panel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    panel:ClearAllPoints()
    -- Negative X tucks the panel under the frame border; Y=0 aligns tops.
    panel:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", -38.5, -10.8)
end

local function UpdateButtonSelectedState()
    if not button then
        return
    end
    if panel and panel:IsShown() then
        button.selected:Show()
    else
        button.selected:Hide()
    end
end

local function LoadMacroIcons()
    wipe(ICON_CHOICES)

    if GetNumMacroIcons and GetMacroIconInfo then
        local count = GetNumMacroIcons() or 0
        for i = 1, count do
            local icon = GetMacroIconInfo(i)
            if icon then
                table.insert(ICON_CHOICES, icon)
            end
        end
    elseif GetMacroIcons then
        local iconTable = {}
        GetMacroIcons(iconTable)
        for _, icon in ipairs(iconTable) do
            if icon then
                table.insert(ICON_CHOICES, icon)
            end
        end
    end

    if #ICON_CHOICES == 0 then
        table.insert(ICON_CHOICES, "Interface\\Icons\\INV_Helmet_03")
    end
end

local function GetItemIDFromLink(link)
    if not link then
        return nil
    end
    local itemID = string.match(link, "item:(%d+)")
    return itemID and tonumber(itemID) or nil
end

local function EnsureDB()
    if type(SimpleEquipmentManagerDB) ~= "table" then
        SimpleEquipmentManagerDB = {}
    end
    if type(SimpleEquipmentManagerDB.sets) ~= "table" then
        SimpleEquipmentManagerDB.sets = {}
    end
    if type(SimpleEquipmentManagerDB.nextId) ~= "number" then
        SimpleEquipmentManagerDB.nextId = 1
    end
    DB = SimpleEquipmentManagerDB
    if #ICON_CHOICES == 0 then
        LoadMacroIcons()
    end
end

local function GetEquippedSnapshot()
    local snapshot = {}
    for _, slotID in ipairs(SLOT_IDS) do
        local itemLink = GetInventoryItemLink("player", slotID)
        local itemID = GetInventoryItemID and GetInventoryItemID("player", slotID) or GetItemIDFromLink(itemLink)
        snapshot[slotID] = {
            itemID = itemID,
            itemLink = itemLink,
        }
    end
    return snapshot
end

local function IsSetEquipped(setData)
    if not setData or type(setData.itemsBySlot) ~= "table" then
        return false
    end

    for _, slotID in ipairs(SLOT_IDS) do
        local expected = setData.itemsBySlot[slotID]
        local currentLink = GetInventoryItemLink("player", slotID)
        local currentID = GetInventoryItemID and GetInventoryItemID("player", slotID) or GetItemIDFromLink(currentLink)

        local expectedID = expected and expected.itemID or nil
        local expectedLink = expected and expected.itemLink or nil

        if expectedID then
            if currentID ~= expectedID then
                return false
            end
        else
            if (currentLink or false) ~= (expectedLink or false) then
                return false
            end
        end
    end

    return true
end

local function EquipSet(setData)
    if not setData or type(setData.itemsBySlot) ~= "table" then
        return
    end

    local missing = 0
    for _, slotID in ipairs(SLOT_IDS) do
        local entry = setData.itemsBySlot[slotID]
        if entry and entry.itemLink then
            local ok = pcall(EquipItemByName, entry.itemLink, slotID)
            if not ok then
                missing = missing + 1
            end
        end
    end

    if missing > 0 then
        Print("Some items could not be equipped (bags/bank/missing).")
    end
end

local function FindSetByName(name)
    local normalized = string.lower(name or "")
    for _, setData in ipairs(DB.sets) do
        if string.lower(setData.name or "") == normalized then
            return setData
        end
    end
    return nil
end

local function FindSetById(setID)
    for _, setData in ipairs(DB.sets) do
        if setData.id == setID then
            return setData
        end
    end
    return nil
end

local function NameExists(name, ignoredId)
    local normalized = string.lower(name or "")
    for _, setData in ipairs(DB.sets) do
        if setData.id ~= ignoredId and string.lower(setData.name or "") == normalized then
            return true
        end
    end
    return false
end

local function CreateSet(name, iconPath)
    local setData = {
        id = DB.nextId,
        name = name,
        icon = iconPath,
        itemsBySlot = GetEquippedSnapshot(),
    }
    DB.nextId = DB.nextId + 1
    table.insert(DB.sets, setData)
    Print("Saved set: " .. name)
end

local function DeleteSetById(setID)
    if not setID then
        return
    end

    for i, setData in ipairs(DB.sets) do
        if setData.id == setID then
            table.remove(DB.sets, i)
            Print("Deleted set: " .. (setData.name or "Unknown"))
            return
        end
    end
end

local function SortSets()
    table.sort(DB.sets, function(a, b)
        return (a.name or "") < (b.name or "")
    end)
end

local function RefreshSetRows()
    if not panel or not panel:IsShown() then
        return
    end

    SortSets()
    local totalSets = #DB.sets
    if panel.scrollFrame then
        FauxScrollFrame_Update(panel.scrollFrame, totalSets, #rows, ROW_HEIGHT + ROW_SPACING)
    end
    local offset = panel.scrollFrame and FauxScrollFrame_GetOffset(panel.scrollFrame) or 0

    for i = 1, #rows do
        local row = rows[i]
        local setData = DB.sets[i + offset]

        if setData then
            row.setData = setData
            row.icon:SetTexture(setData.icon or ICON_CHOICES[1])
            row.name:SetText(setData.name or ("Set " .. (i + offset)))
            row.checkmark:SetShown(IsSetEquipped(setData))
            row:Show()
        else
            row.setData = nil
            row:Hide()
        end
    end
end

local function HideCreateSetFrame()
    if createSetFrame then
        createSetFrame:Hide()
    end
end

local setRowMenuFrame
local ShowCreateSetFrame

local function ConfirmDeleteSet(setData)
    if not setData then
        return
    end

    StaticPopupDialogs["SEM_DELETE_SET_CONFIRM"] = {
        text = "Delete set \"%s\"?",
        button1 = YES,
        button2 = NO,
        OnAccept = function(_, data)
            DeleteSetById(data)
            RefreshSetRows()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = STATICPOPUP_NUMDIALOGS,
    }

    StaticPopup_Show("SEM_DELETE_SET_CONFIRM", setData.name or "Set", nil, setData.id)
end

local function AddSetRowMenuButton(level, text, onSelect, arg1)
    local info = UIDropDownMenu_CreateInfo()
    info.text = text
    info.notCheckable = true
    info.isNotRadio = true
    info.arg1 = arg1
    info.func = function()
        if CloseDropDownMenus then
            CloseDropDownMenus()
        else
            HideDropDownMenu(1)
        end
        onSelect(arg1)
    end
    UIDropDownMenu_AddButton(info, level)
end

local function ShowSetRowMenu(anchor, setData)
    if not setData then
        return
    end

    if not setRowMenuFrame then
        setRowMenuFrame = CreateFrame("Frame", "SEMSetRowMenu", UIParent, "UIDropDownMenuTemplate")
        setRowMenuFrame.displayMode = "MENU"
        setRowMenuFrame.initialize = function(self, level)
            if level ~= 1 then
                return
            end

            local menuSetData = self.setData
            if not menuSetData then
                return
            end

            AddSetRowMenuButton(level, "Edit", function(data)
                C_Timer.After(0, function()
                    ShowCreateSetFrame(data)
                end)
            end, menuSetData)

            AddSetRowMenuButton(level, DELETE, ConfirmDeleteSet, menuSetData)
        end
    end

    setRowMenuFrame.setData = setData
    ToggleDropDownMenu(1, nil, setRowMenuFrame, anchor, 0, 0)
end

local function SetRowHover(row, hovered)
    if hovered then
        row.bg:SetVertexColor(ROW_HOVER_COLOR[1], ROW_HOVER_COLOR[2], ROW_HOVER_COLOR[3], ROW_HOVER_COLOR[4])
        row.settingsBtn:Show()
    else
        row.bg:SetVertexColor(ROW_COLOR[1], ROW_COLOR[2], ROW_COLOR[3], ROW_COLOR[4])
        row.settingsBtn:Hide()
    end
end

local function RefreshIconGrid()
    if not createSetFrame or not createSetFrame.iconScrollFrame then
        return
    end

    local totalRows = math.ceil(#ICON_CHOICES / ICON_COLS)
    FauxScrollFrame_Update(createSetFrame.iconScrollFrame, totalRows, ICON_VISIBLE_ROWS, ICON_ROW_HEIGHT)
    local offset = FauxScrollFrame_GetOffset(createSetFrame.iconScrollFrame)

    for rowIndex = 1, ICON_VISIBLE_ROWS do
        local row = iconGridRows[rowIndex]
        local dataRow = rowIndex + offset

        for col = 1, ICON_COLS do
            local btn = row.buttons[col]
            local iconIndex = (dataRow - 1) * ICON_COLS + col

            if iconIndex <= #ICON_CHOICES then
                btn.iconIndex = iconIndex
                btn.iconTex:SetTexture(ICON_CHOICES[iconIndex])
                btn.selected:SetShown(iconIndex == selectedIconIndex)
                btn:Show()
            else
                btn.iconIndex = nil
                btn:Hide()
            end
        end
    end
end

local function SelectIcon(index)
    if index < 1 or index > #ICON_CHOICES then
        return
    end
    selectedIconIndex = index
    if createSetFrame then
        RefreshIconGrid()
    end
end

local function ScrollIconGridToSelection()
    if not createSetFrame or not createSetFrame.iconScrollFrame then
        return
    end

    local row = math.floor((selectedIconIndex - 1) / ICON_COLS)
    local totalRows = math.ceil(#ICON_CHOICES / ICON_COLS)
    local maxOffset = math.max(0, totalRows - ICON_VISIBLE_ROWS)
    FauxScrollFrame_SetOffset(createSetFrame.iconScrollFrame, math.min(row, maxOffset))
    RefreshIconGrid()
end

ShowCreateSetFrame = function(setData)
    if not createSetFrame then
        createSetFrame = CreateFrame("Frame", "SEMCreatSetFrame", UIParent, BACKDROP_TEMPLATE)
        createSetFrame:SetSize(300, 340)
        createSetFrame:SetFrameStrata("DIALOG")
        createSetFrame:SetToplevel(true)
        createSetFrame:EnableMouse(true)
        createSetFrame:SetMovable(true)
        createSetFrame:RegisterForDrag("LeftButton")
        createSetFrame:SetScript("OnDragStart", createSetFrame.StartMoving)
        createSetFrame:SetScript("OnDragStop", createSetFrame.StopMovingOrSizing)

        ApplyCharacterPanelChrome(createSetFrame, "SEMCreate")

        createSetFrame.title = createSetFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        createSetFrame.title:SetPoint("TOP", 0, -9)
        createSetFrame.title:SetText("Create New Set")

        createSetFrame.closeButton = CreateFrame("Button", "SEMCreateSetCloseButton", createSetFrame, "UIPanelCloseButton")
        createSetFrame.closeButton:SetPoint("CENTER", createSetFrame, "TOPRIGHT", -14, -15)
        if createSetFrame.closeButton.SetFrameLevel and createSetFrame.GetFrameLevel then
            createSetFrame.closeButton:SetFrameLevel(createSetFrame:GetFrameLevel() + 10)
        end
        createSetFrame.closeButton:SetScript("OnClick", HideCreateSetFrame)
        createSetFrame.closeButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText(CLOSE)
            GameTooltip:Show()
        end)
        createSetFrame.closeButton:SetScript("OnLeave", GameTooltip_Hide)

        createSetFrame.nameLabel = createSetFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        createSetFrame.nameLabel:SetPoint("TOPLEFT", 20, -40)
        createSetFrame.nameLabel:SetText("Set Name")

        createSetFrame.nameEdit = CreateFrame("EditBox", nil, createSetFrame, "InputBoxTemplate")
        createSetFrame.nameEdit:SetSize(180, 24)
        createSetFrame.nameEdit:SetPoint("TOPLEFT", 20, -58)
        createSetFrame.nameEdit:SetAutoFocus(false)
        createSetFrame.nameEdit:SetMaxLetters(24)

        createSetFrame.iconLabel = createSetFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        createSetFrame.iconLabel:SetPoint("TOPLEFT", 20, -88)
        createSetFrame.iconLabel:SetText("Icon (click to select)")

        createSetFrame.iconScrollFrame = CreateFrame("ScrollFrame", "SEMIconScrollFrame", createSetFrame, "FauxScrollFrameTemplate")
        createSetFrame.iconScrollFrame:SetPoint("TOPLEFT", 16, -104)
        createSetFrame.iconScrollFrame:SetSize(ICON_COLS * ICON_CELL + 8, ICON_VISIBLE_ROWS * ICON_ROW_HEIGHT)
        createSetFrame.iconScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
            FauxScrollFrame_OnVerticalScroll(self, offset, ICON_ROW_HEIGHT, RefreshIconGrid)
        end)

        local gridTop = -104
        for rowIndex = 1, ICON_VISIBLE_ROWS do
            local row = CreateFrame("Frame", nil, createSetFrame)
            row:SetSize(ICON_COLS * ICON_CELL, ICON_CELL)
            row:SetPoint("TOPLEFT", 20, gridTop - (rowIndex - 1) * ICON_ROW_HEIGHT)
            row.buttons = {}

            for col = 1, ICON_COLS do
                local btn = CreateFrame("Button", nil, row)
                btn:SetSize(ICON_CELL, ICON_CELL)
                btn:SetPoint("TOPLEFT", (col - 1) * ICON_CELL, 0)

                btn.iconTex = btn:CreateTexture(nil, "ARTWORK")
                btn.iconTex:SetAllPoints(true)

                btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
                btn.highlight:SetAllPoints(true)
                btn.highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
                btn.highlight:SetBlendMode("ADD")

                btn.selected = btn:CreateTexture(nil, "OVERLAY")
                btn.selected:SetAllPoints(true)
                btn.selected:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
                btn.selected:SetVertexColor(1, 0.82, 0)
                btn.selected:Hide()

                btn:SetScript("OnClick", function(self)
                    if self.iconIndex then
                        SelectIcon(self.iconIndex)
                    end
                end)

                row.buttons[col] = btn
            end

            iconGridRows[rowIndex] = row
        end

        createSetFrame.cancelBtn = CreateFrame("Button", nil, createSetFrame, "UIPanelButtonTemplate")
        createSetFrame.cancelBtn:SetSize(70, 24)
        createSetFrame.cancelBtn:SetPoint("BOTTOMRIGHT", -16, 16)
        createSetFrame.cancelBtn:SetText(CANCEL)

        createSetFrame.saveBtn = CreateFrame("Button", nil, createSetFrame, "UIPanelButtonTemplate")
        createSetFrame.saveBtn:SetSize(70, 24)
        createSetFrame.saveBtn:SetPoint("RIGHT", createSetFrame.cancelBtn, "LEFT", -8, 0)
        createSetFrame.saveBtn:SetText(SAVE)

        createSetFrame.cancelBtn:SetScript("OnClick", HideCreateSetFrame)
        createSetFrame.saveBtn:SetScript("OnClick", function()
            local rawName = createSetFrame.nameEdit:GetText() or ""
            local name = string.gsub(rawName, "^%s*(.-)%s*$", "%1")
            if name == "" then
                Print("Set name cannot be empty.")
                return
            end
            if NameExists(name, editingSetId) then
                Print("A set with that name already exists.")
                return
            end

            if editingSetId then
                local editedSet = FindSetById(editingSetId)
                if not editedSet then
                    Print("Could not find set to edit.")
                    HideCreateSetFrame()
                    RefreshSetRows()
                    return
                end

                editedSet.name = name
                editedSet.icon = ICON_CHOICES[selectedIconIndex]
                editedSet.itemsBySlot = GetEquippedSnapshot()
                Print("Updated set (name, icon, and gear): " .. name)
            else
                CreateSet(name, ICON_CHOICES[selectedIconIndex])
            end

            HideCreateSetFrame()
            RefreshSetRows()
        end)
    end

    createSetFrame:ClearAllPoints()
    createSetFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    if #ICON_CHOICES == 0 then
        LoadMacroIcons()
    end

    editingSetId = setData and setData.id or nil
    if setData then
        createSetFrame.title:SetText("Edit Set")
        createSetFrame.saveBtn:SetText("Update")
        createSetFrame.nameEdit:SetText(setData.name or "")
        selectedIconIndex = 1
        for i, iconPath in ipairs(ICON_CHOICES) do
            if iconPath == setData.icon then
                selectedIconIndex = i
                break
            end
        end
    else
        createSetFrame.title:SetText("Create New Set")
        createSetFrame.saveBtn:SetText(SAVE)
        createSetFrame.nameEdit:SetText("")
        selectedIconIndex = 1
    end

    ScrollIconGridToSelection()
    createSetFrame:Show()
    createSetFrame.nameEdit:SetFocus()
end

local function CreateSetPanel()
    panel = CreateFrame("Frame", "SimpleEquipmentManagerPanel", CharacterFrame, BACKDROP_TEMPLATE)
    panel:Hide()
    panel:EnableMouse(true)
    ApplyCharacterPanelChrome(panel, "SEMPanel")
    UpdatePanelLayout()

    if CharacterFrame.GetFrameLevel then
        panel:SetFrameLevel(CharacterFrame:GetFrameLevel() + 2)
    end

    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.title:SetPoint("TOP", 0, -9)
    panel.title:SetText("Equipment Manager")

    panel.closeButton = CreateFrame("Button", "SEMEquipmentPanelCloseButton", panel, "UIPanelCloseButton")
    panel.closeButton:SetPoint("CENTER", panel, "TOPRIGHT", -14, -15)
    if panel.closeButton.SetFrameLevel and panel.GetFrameLevel then
        panel.closeButton:SetFrameLevel(panel:GetFrameLevel() + 10)
    end
    panel.closeButton:SetScript("OnClick", function()
        panel:Hide()
    end)
    panel.closeButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(CLOSE)
        GameTooltip:Show()
    end)
    panel.closeButton:SetScript("OnLeave", GameTooltip_Hide)

    panel.newSetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.newSetButton:SetSize(PANEL_WIDTH - 24, 28)
    panel.newSetButton:SetPoint("BOTTOM", 0, 12)
    panel.newSetButton:SetText("New Set")
    panel.newSetButton:SetScript("OnClick", function()
        ShowCreateSetFrame(nil)
    end)

    panel.scrollFrame = CreateFrame("ScrollFrame", "SimpleEquipmentManagerScrollFrame", panel, "FauxScrollFrameTemplate")
    panel.scrollFrame:SetPoint("TOPLEFT", 10, -34)
    panel.scrollFrame:SetPoint("BOTTOMRIGHT", -28, 46)
    panel.scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT + ROW_SPACING, RefreshSetRows)
    end)

    local startY = -34
    for i = 1, VISIBLE_ROWS do
        local row = CreateFrame("Button", nil, panel)
        row:SetSize(PANEL_WIDTH - 36, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 12, startY - (i - 1) * (ROW_HEIGHT + ROW_SPACING))

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints(true)
        row.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        row.bg:SetVertexColor(ROW_COLOR[1], ROW_COLOR[2], ROW_COLOR[3], ROW_COLOR[4])

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(20, 20)
        row.icon:SetPoint("LEFT", 4, 0)

        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.name:SetJustifyH("LEFT")
        row.name:SetText("Set")

        row.checkmark = row:CreateTexture(nil, "OVERLAY")
        row.checkmark:SetSize(16, 16)
        row.checkmark:SetPoint("RIGHT", -22, 0)
        row.checkmark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        row.checkmark:Hide()

        row.settingsBtn = CreateFrame("Button", nil, row)
        row.settingsBtn:SetSize(16, 16)
        row.settingsBtn:SetPoint("RIGHT", -2, 0)
        row.settingsBtn:Hide()

        row.settingsBtn.icon = row.settingsBtn:CreateTexture(nil, "ARTWORK")
        row.settingsBtn.icon:SetAllPoints(true)
        row.settingsBtn.icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
        DesaturateTexture(row.settingsBtn.icon)

        row.settingsBtn.highlight = row.settingsBtn:CreateTexture(nil, "HIGHLIGHT")
        row.settingsBtn.highlight:SetAllPoints(true)
        row.settingsBtn.highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        row.settingsBtn.highlight:SetBlendMode("ADD")

        row.settingsBtn:SetScript("OnClick", function(self)
            local parentRow = self:GetParent()
            if parentRow and parentRow.setData then
                ShowSetRowMenu(self, parentRow.setData)
            end
        end)
        row.settingsBtn:SetScript("OnEnter", function(self)
            SetRowHover(self:GetParent(), true)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine("Set options")
            GameTooltip:Show()
        end)
        row.settingsBtn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            local parentRow = self:GetParent()
            if parentRow and not parentRow:IsMouseOver() then
                SetRowHover(parentRow, false)
            end
        end)

        row:SetScript("OnEnter", function(self)
            SetRowHover(self, true)
        end)
        row:SetScript("OnLeave", function(self)
            if not self.settingsBtn:IsMouseOver() then
                SetRowHover(self, false)
            end
        end)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnClick", function(self, mouseButton)
            if not self.setData then
                return
            end

            if mouseButton == "RightButton" then
                ShowCreateSetFrame(self.setData)
                return
            end

            EquipSet(self.setData)
            C_Timer.After(0.2, RefreshSetRows)
        end)

        row:Hide()
        rows[i] = row
    end

    panel:SetScript("OnShow", function()
        RefreshSetRows()
        UpdateButtonSelectedState()
    end)
    panel:SetScript("OnHide", UpdateButtonSelectedState)
end

local function TogglePanel()
    if not panel then
        return
    end
    if panel:IsShown() then
        panel:Hide()
    else
        if CharacterFrame and not CharacterFrame:IsShown() then
            if ToggleCharacter then
                ToggleCharacter("PaperDollFrame")
            elseif ShowUIPanel then
                ShowUIPanel(CharacterFrame)
                if CharacterFrame_ShowSubFrame then
                    CharacterFrame_ShowSubFrame("PaperDollFrame")
                end
            else
                CharacterFrame:Show()
            end
        end
        UpdatePanelLayout()
        panel:Show()
        RefreshSetRows()
    end
    UpdateButtonSelectedState()
end

local function CreateCharacterButton()
    if button or not CharacterFrame or not PaperDollFrame then
        return
    end

    button = CreateFrame("Button", "SimpleEquipmentManagerButton", PaperDollFrame)
    button:SetSize(28, 28)
    button:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -45, -42)

    button.bg = button:CreateTexture(nil, "ARTWORK")
    button.bg:SetAllPoints(true)
    button.bg:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    DesaturateTexture(button.bg)
    button.bg:SetVertexColor(0.75, 0.75, 0.75, 1)

    button.icon = button:CreateTexture(nil, "OVERLAY")
    button.icon:SetSize(24, 24)
    button.icon:SetPoint("CENTER")
    button.icon:SetTexture("Interface\\Icons\\INV_Helmet_03")
    DesaturateTexture(button.icon)

    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    button:RegisterForClicks("LeftButtonUp")

    button.selected = button:CreateTexture(nil, "OVERLAY")
    button.selected:SetAllPoints(true)
    button.selected:SetTexture(TEX_TAB_HIGHLIGHT)
    button.selected:SetBlendMode("ADD")
    button.selected:Hide()

    button:SetScript("OnClick", TogglePanel)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Simple Equipment Manager")
        GameTooltip:AddLine("Open saved equipment sets.", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function EnsureUI()
    if not CharacterFrame then
        return
    end
    CreateCharacterButton()
    if not panel then
        CreateSetPanel()
    end
    if not characterFrameHooked then
        CharacterFrame:HookScript("OnHide", function()
            if panel and panel:IsShown() then
                panel:Hide()
            end
            HideCreateSetFrame()
            UpdateButtonSelectedState()
        end)

        CharacterFrame:HookScript("OnShow", function()
            UpdatePanelLayout()
        end)

        if CharacterFrame_ShowSubFrame then
            hooksecurefunc("CharacterFrame_ShowSubFrame", function(frameName)
                if frameName ~= "PaperDollFrame" then
                    if panel and panel:IsShown() then
                        panel:Hide()
                    end
                    HideCreateSetFrame()
                end
            end)
        end

        characterFrameHooked = true
    end
end

SEM:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        EnsureDB()
    elseif event == "PLAYER_LOGIN" then
        EnsureUI()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        RefreshSetRows()
    end
end)

SEM:RegisterEvent("ADDON_LOADED")
SEM:RegisterEvent("PLAYER_LOGIN")
SEM:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
