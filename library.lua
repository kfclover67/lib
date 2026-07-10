local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")
local Stats            = game:FindService("Stats")

local LocalPlayer = Players.LocalPlayer

local fs = {
    writefile   = writefile,
    readfile    = readfile,
    appendfile  = appendfile,
    isfile      = isfile,
    isfolder    = isfolder,
    listfiles   = listfiles,
    makefolder  = makefolder,
    delfile     = delfile,
    delfolder   = delfolder,
    loadfile    = loadfile,
}
local getCustomAsset = getcustomasset or getsynasset
local setClipboard   = setclipboard or toclipboard
local httpGet = function(url)
    local ok, res = pcall(function()
        if syn and syn.request then
            return syn.request({ Url = url, Method = "GET" }).Body
        end
        return game:HttpGet(url)
    end)
    if ok then return res end
    return nil
end

local function cleanFileName(name)
    return tostring(name):gsub("[^%w%._%-]", "_")
end

local function looksLikeFontData(data)
    if type(data) ~= "string" or #data < 128 then
        return false
    end

    local head = data:sub(1, 256):lower()
    if head:find("<!doctype", 1, true) or head:find("<html", 1, true) or head:find("not found", 1, true) then
        return false
    end

    local magic = data:sub(1, 4)
    return magic == "\0\1\0\0"
        or magic == "OTTO"
        or magic == "true"
        or magic == "ttcf"
        or magic == "wOFF"
        or magic == "wOF2"
end

local function ensureFontFolders()
    if not (fs.makefolder and fs.isfolder) then return end
    pcall(function()
        if not fs.isfolder("void") then fs.makefolder("void") end
        if not fs.isfolder("void/fonts") then fs.makefolder("void/fonts") end
    end)
end

local function hasFS()
    return fs.writefile and fs.readfile and fs.isfile and fs.listfiles and fs.makefolder and true or false
end

local Library = {
    Toggles      = {},
    Options      = {},
    Connections  = {},
    ActivePopups = {},
    Registry     = {},
    FontRegistry = {},
    CustomFontAssets = {},
    DependencyBoxes = {},
    KeybindEntries = {},
    SearchIndex = {},
    SearchIconAsset = "rbxassetid://72296609649861",
    ActiveSearchPanels = {},
    Theme = {
        DarkBackground    = Color3.fromRGB(11, 11, 13),
        PageBackground    = Color3.fromRGB(15, 15, 17),
        SectionBackground = Color3.fromRGB(19, 19, 22),
        Inline            = Color3.fromRGB(26, 26, 30),
        Border            = Color3.fromRGB(38, 38, 44),
        Text              = Color3.fromRGB(150, 160, 180),
        DarkText          = Color3.fromRGB(96, 105, 124),
        LightText         = Color3.fromRGB(208, 212, 222),
        Accent            = Color3.fromRGB(74, 140, 200),
        TitleColor        = Color3.fromRGB(108, 138, 184),
    },
    Fonts = {
        { "Gotham", Enum.Font.Gotham },
        { "GothamBold", Enum.Font.GothamBold },
        { "GothamBlack", Enum.Font.GothamBlack },
        { "GothamMedium", Enum.Font.GothamMedium },
        { "Code", Enum.Font.Code },
        { "Arial", Enum.Font.Arial },
        { "ArialBold", Enum.Font.ArialBold },
        { "SourceSans", Enum.Font.SourceSans },
        { "SourceSansBold", Enum.Font.SourceSansBold },
        { "SourceSansLight", Enum.Font.SourceSansLight },
        { "SourceSansItalic", Enum.Font.SourceSansItalic },
        { "SourceSansSemibold", Enum.Font.SourceSansSemibold },
        { "Roboto", Enum.Font.Roboto },
        { "RobotoMono", Enum.Font.RobotoMono },
        { "Legacy", Enum.Font.Legacy },
        { "Fantasy", Enum.Font.Fantasy },
        { "Antique", Enum.Font.Antique },
        { "Arcade", Enum.Font.Arcade },
        { "Cartoon", Enum.Font.Cartoon },
        { "Highway", Enum.Font.Highway },
        { "SciFi", Enum.Font.SciFi },
    },
    FontsToDownload = {
        ["Tahoma"]            = { Link = "https://github.com/LuckyHub1/LuckyHub/raw/main/zekton_rg.ttf" },
        ["Minecraftia"]       = { Link = "https://github.com/LuckyHub1/LuckyHub/raw/refs/heads/main/Minecraftia.ttf" },
        ["Silkscreen"]        = { Link = "https://github.com/LuckyHub1/LuckyHub/raw/refs/heads/main/Silkscreen.ttf" },
        ["ProggyClean"]       = { Link = "https://github.com/bestCheaterOnEarth/font/raw/refs/heads/main/FONTS/ProggyClean.ttf" },
        ["ProggyTiny"]        = { Link = "https://github.com/bestCheaterOnEarth/font/raw/refs/heads/main/FONTS/ProggyTiny.ttf" },
        ["visitor"]           = { Link = "https://github.com/bestCheaterOnEarth/font/raw/refs/heads/main/FONTS/visitor.ttf" },
        ["windows-xp-tahoma"] = { Link = "https://github.com/bestCheaterOnEarth/font/raw/refs/heads/main/FONTS/windows-xp-tahoma.ttf" },
        ["SmallestPixel"]     = { Link = "https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/smallest_pixel-7.ttf" },
    },
    Font     = Enum.Font.Gotham,
    FontMed  = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    CurrentFontSpec = { enum = Enum.Font.Gotham },
    Open      = true,
    IsMobile  = (UserInputService.TouchEnabled and not UserInputService.MouseEnabled),
    ConfigFolder = "void",
    KeybindListVisible = true,
    KeybindListMode = "toggled",
    UnloadCallbacks = {},
    Unloaded = false,
}
Library.__index = Library

do
    local genv = (getgenv and getgenv()) or _G
    genv.Toggles = Library.Toggles
    genv.toggles = Library.Toggles
    genv.Options = Library.Options
    genv.options = Library.Options
end

local function computeRole(f)
    if f == Enum.Font.GothamBold or f == Enum.Font.GothamBlack or f == Enum.Font.ArialBold or f == Enum.Font.SourceSansBold then
        return "bold"
    elseif f == Enum.Font.GothamMedium or f == Enum.Font.SourceSansSemibold then
        return "medium"
    end
    return "regular"
end

local function applyFontToObject(obj, role)
    local spec = Library.CurrentFontSpec
    if not spec then return end
    if spec.custom then
        local asset = Library.CustomFontAssets[spec.custom]
        if asset then
            local weight = role == "bold" and Enum.FontWeight.Bold
                or (role == "medium" and Enum.FontWeight.Medium or Enum.FontWeight.Regular)
            pcall(function() obj.FontFace = Font.new(asset, weight, Enum.FontStyle.Normal) end)
        end
    elseif spec.enum then
        local enum = spec.enum
        if role == "bold" then enum = Library:_BoldVariant(spec.enum) end
        pcall(function() obj.Font = enum end)
    end
end

local function New(class, props, children)
    local inst = Instance.new(class)
    if props then
        local parent = props.Parent
        props.Parent = nil
        for k, v in pairs(props) do
            inst[k] = v
        end
        if parent then inst.Parent = parent end
    end
    if children then
        for _, c in ipairs(children) do c.Parent = inst end
    end
    if class == "TextLabel" or class == "TextButton" or class == "TextBox" then
        local role = computeRole(inst.Font)
        table.insert(Library.FontRegistry, { Obj = inst, Role = role })
        applyFontToObject(inst, role)
    end
    return inst
end

local function Corner(radius, parent)
    return New("UICorner", { CornerRadius = UDim.new(0, radius or 4), Parent = parent })
end

local function Stroke(parent, color, thickness, transparency)
    return New("UIStroke", {
        Color = color or Library.Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function Padding(parent, all, left, right, top, bottom)
    return New("UIPadding", {
        PaddingLeft   = UDim.new(0, left   or all or 0),
        PaddingRight  = UDim.new(0, right  or all or 0),
        PaddingTop    = UDim.new(0, top    or all or 0),
        PaddingBottom = UDim.new(0, bottom or all or 0),
        Parent = parent,
    })
end

local function Connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Library.Connections, c)
    return c
end

local function spawnFn(fn, ...)
    if type(fn) == "function" then task.spawn(fn, ...) end
end

local function pushCallback(list, fn)
    if type(fn) == "function" then table.insert(list, fn) end
end

local function formatImage(icon)
    if icon == nil or icon == "" then return nil end
    if type(icon) == "number" then
        if icon <= 0 then return nil end
        return "rbxassetid://" .. icon
    end
    local s = tostring(icon)
    if s == "0" then return nil end
    if s:find("rbxasset") then return s end
    local digits = s:match("^(%d+)$")
    if digits and tonumber(digits) <= 0 then return nil end
    return "rbxassetid://" .. s
end

local function formatDisplayValue(val)
    if val == nil then return "..." end
    local t = type(val)
    if t == "string" then return val == "" and "..." or val
    elseif t == "number" or t == "boolean" then return tostring(val)
    elseif t == "table" then return "..."
    end
    return "..."
end

local function normalizeKeybind(key)
    if key == nil or key == "" then return nil end
    if type(key) ~= "string" then return nil end
    return key
end

local function resolveDropdownDefault(values, default, multi)
    if default == nil then return multi and {} or nil end
    if multi then
        if type(default) == "table" then
            local t = {}
            for k, v in pairs(default) do
                if type(k) == "string" and v == true then
                    t[k] = true
                elseif type(v) == "string" then
                    t[v] = true
                end
            end
            return t
        end
        return {}
    end
    if type(default) == "number" then
        local idx = default <= 0 and 1 or default
        return values[idx]
    end
    return default
end

local function parseTitle(raw, fallbackIcon)
    local text, icon = "void", nil
    if type(raw) == "string" then
        text = raw
    elseif type(raw) == "table" then
        text = raw[1] or raw.Text or raw.text or raw.Name or raw.name or "void"
        icon = raw[2] or raw.Icon or raw.icon or raw.Image or raw.image
    elseif raw ~= nil then
        text = tostring(raw)
    end
    if not icon then icon = fallbackIcon end
    return tostring(text), formatImage(icon)
end

local function Tween(obj, time, props)
    local t = TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, startPos, framePos
    Connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = input.Position
            framePos = frame.Position
        end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - startPos
            frame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + d.X,
                framePos.Y.Scale, framePos.Y.Offset + d.Y)
        end
    end)
    Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

function Library:AddToRegistry(instance, property, themeKey)
    table.insert(self.Registry, { Instance = instance, Property = property, Key = themeKey })
    instance[property] = self.Theme[themeKey]
    return instance
end

function Library:SetTheme(themeKey, color)
    self.Theme[themeKey] = color
    for _, entry in ipairs(self.Registry) do
        if entry.Key == themeKey and entry.Instance and entry.Instance.Parent then
            pcall(function() entry.Instance[entry.Property] = color end)
        end
    end
    if self.SyncTheme and self.SyncTheme[themeKey] and not self._themeSync then
        self._themeSync = true
        pcall(function() self.SyncTheme[themeKey]:SetValue(color) end)
        self._themeSync = false
    end
    self:_RefreshThemeDynamic()
end

function Library:_RefreshThemeDynamic()
    if self._currentTabSelect then pcall(self._currentTabSelect) end
    for _, t in pairs(self.Toggles) do
        if t._boxStroke then
            t._boxStroke.Color = t.Value and self.Theme.Accent or self.Theme.Border
        end
    end
    self:_UpdateKeybindList()
end

local boldMap = {
    [Enum.Font.Gotham] = Enum.Font.GothamBold,
    [Enum.Font.GothamMedium] = Enum.Font.GothamBold,
    [Enum.Font.SourceSans] = Enum.Font.SourceSansBold,
    [Enum.Font.SourceSansSemibold] = Enum.Font.SourceSansBold,
    [Enum.Font.Arial] = Enum.Font.ArialBold,
}
function Library:_BoldVariant(enum)
    return boldMap[enum] or enum
end

function Library:DownloadFont(name, link)
    if not (fs.writefile and fs.readfile and fs.isfile and getCustomAsset and link) then return nil end

    ensureFontFolders()

    local safeName = cleanFileName(name)
    local fontPath = "void/fonts/" .. safeName .. ".ttf"
    local familyPath = "void/fonts/" .. safeName .. ".font"

    local data
    if fs.isfile(fontPath) then
        local ok, cached = pcall(fs.readfile, fontPath)
        if ok and looksLikeFontData(cached) then
            data = cached
        else
            pcall(function()
                if fs.delfile then fs.delfile(fontPath) end
            end)
        end
    end

    if not data then
        data = httpGet(link)
        if not looksLikeFontData(data) then return nil end

        local ok = pcall(fs.writefile, fontPath, data)
        if not ok then return nil end
    end

    local okTtf, ttfAsset = pcall(getCustomAsset, fontPath)
    if not okTtf or not ttfAsset then return nil end

    local family = {
        name = tostring(name),
        faces = {
            {
                name = "Regular",
                weight = 400,
                style = "Normal",
                assetId = ttfAsset,
            },
            {
                name = "Medium",
                weight = 500,
                style = "Normal",
                assetId = ttfAsset,
            },
            {
                name = "Bold",
                weight = 700,
                style = "Normal",
                assetId = ttfAsset,
            },
        },
    }

    local encoded = HttpService:JSONEncode(family)
    local needsWrite = true
    if fs.isfile(familyPath) then
        local ok, cached = pcall(fs.readfile, familyPath)
        needsWrite = not ok or cached ~= encoded
    end

    if needsWrite then
        local ok = pcall(fs.writefile, familyPath, encoded)
        if not ok then return nil end
    end

    local okAsset, asset = pcall(getCustomAsset, familyPath)
    if okAsset and asset then
        self.CustomFontAssets[name] = asset
        return asset
    end

    return nil
end

function Library:FontIsCached(name)
    if not (fs.isfile and fs.readfile) then
        return false
    end

    if self.CustomFontAssets[name] then
        return true
    end

    local safeName = cleanFileName(name)
    local fontPath = "void/fonts/" .. safeName .. ".ttf"
    local familyPath = "void/fonts/" .. safeName .. ".font"

    if not fs.isfile(fontPath) or not fs.isfile(familyPath) then
        return false
    end

    local ok, cached = pcall(fs.readfile, fontPath)
    return ok and looksLikeFontData(cached)
end

function Library:AnyFontsNeedDownload()
    if not (fs.writefile and fs.readfile and fs.isfile and getCustomAsset) then
        return false
    end

    for name, info in pairs(self.FontsToDownload) do
        if info and info.Link and not self:FontIsCached(name) then
            return true
        end
    end

    return false
end

function Library:SetFont(spec)
    if spec and spec.custom and not self.CustomFontAssets[spec.custom] then
        local info = self.FontsToDownload[spec.custom]
        if info and info.Link then
            self:DownloadFont(spec.custom, info.Link)
        end
    end

    self.CurrentFontSpec = spec
    for _, e in ipairs(self.FontRegistry) do
        if e.Obj.Parent then
            applyFontToObject(e.Obj, e.Role)
        end
    end
end

function Library:DownloadAllFonts()
    local notify
    if self:AnyFontsNeedDownload() then
        notify = self:Notify("downloading fonts", false)
    end

    for name, info in pairs(self.FontsToDownload) do
        if info and info.Link then
            self:DownloadFont(name, info.Link)
        end
    end

    if notify then
        notify:Dismiss()
    end

    return self.CustomFontAssets
end

local function isGuiShown(obj)
    local current = obj
    while current do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        end
        current = current.Parent
    end
    return true
end

local function within(pos, obj)
    if not obj or not obj.Parent or not isGuiShown(obj) then
        return false
    end

    local p, s = obj.AbsolutePosition, obj.AbsoluteSize
    if s.X <= 0 or s.Y <= 0 then
        return false
    end

    return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
end

function Library:OpenPopup(popup, anchor, posFn)
    self:CloseAllPopups(popup)
    if posFn then posFn() end
    popup.Visible = true
    self.ActivePopups[popup] = { Anchor = anchor, PosFn = posFn }
end

function Library:ClosePopup(popup)
    popup.Visible = false
    self.ActivePopups[popup] = nil
end

function Library:CloseAllPopups(except)
    for popup, data in pairs(self.ActivePopups) do
        if popup ~= except and popup.Parent then
            popup.Visible = false
            self.ActivePopups[popup] = nil
        end
    end
end

function Library:CloseAllSearchPanels()
    for _, panel in ipairs(self.ActiveSearchPanels) do
        if panel.Clear then
            panel.Clear()
        end
    end
end

function Library:Notify(text, duration)
    if duration == nil then
        duration = 4
    end

    local holder = self.NotifyHolder
    if not holder then return nil end

    local frame = New("Frame", {
        Parent = holder,
        BackgroundColor3 = self.Theme.SectionBackground,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 10, 0, 32),
        AutomaticSize = Enum.AutomaticSize.X,
        ClipsDescendants = true,
    })
    self:AddToRegistry(frame, "BackgroundColor3", "SectionBackground")
    Corner(5, frame)
    self:AddToRegistry(Stroke(frame, self.Theme.Border, 1, 0), "Color", "Border")
    New("Frame", {
        Parent = frame, Size = UDim2.new(0, 2, 1, 0), BorderSizePixel = 0,
        BackgroundColor3 = self.Theme.Accent,
    })
    local lbl = New("TextLabel", {
        Parent = frame, BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
        Font = self.Font, Text = text, TextSize = 14, TextColor3 = self.Theme.LightText,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    New("UIPadding", { Parent = frame, PaddingRight = UDim.new(0, 12) })

    local notify = { Frame = frame, Label = lbl, Dismissed = false }
    function notify:Dismiss()
        if self.Dismissed then return self end
        self.Dismissed = true
        local f, l = self.Frame, self.Label
        if f and f.Parent then
            Tween(f, 0.2, { BackgroundTransparency = 1 })
            Tween(l, 0.2, { TextTransparency = 1 })
            task.delay(0.25, function()
                if f and f.Parent then
                    f:Destroy()
                end
            end)
        end
        return self
    end

    if duration ~= false then
        task.delay(duration, function()
            notify:Dismiss()
        end)
    end

    return notify
end

local function makeRow(parent, height, order)
    if not order then
        order = (parent:GetAttribute("VoidRowOrder") or 0) + 1
        parent:SetAttribute("VoidRowOrder", order)
    end

    return New("Frame", {
        Parent = parent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height),
        LayoutOrder = order,
    })
end

local function makeAddonHolder(row)
    local holder = New("Frame", {
        Name = "Addons",
        Parent = row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
    })
    New("UIListLayout", {
        Parent = holder,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    })
    return holder
end

local function nextAddonOrder(holder)
    local n = holder:GetAttribute("AddonCount") or 0
    n += 1
    holder:SetAttribute("AddonCount", n)
    return n
end

function Library:_RegisterSearchFromRow(row, text, id, ctx)
    ctx = ctx or self._currentSectionCtx
    if not ctx or not ctx.Tab then return end
    text = text or id
    if not text or text == "" then return end
    local tab = ctx.Tab
    table.insert(self.SearchIndex, {
        Text = text,
        Id = id,
        GroupTitle = ctx.GroupTitle or "",
        TabName = tab.Name,
        TabIcon = tab.Icon,
        TabSelect = tab.Select,
        TabboxSelect = ctx.TabboxSelect,
        Row = row,
        ScrollFrame = ctx.ScrollFrame,
    })
end

local function searchEntryMatches(entry, query)
    local hay = string.lower(
        (entry.Text or "") .. " "
        .. (entry.Id or ""):gsub("_", " ") .. " "
        .. (entry.TabName or "") .. " "
        .. (entry.GroupTitle or "")
    )
    local compactHay = hay:gsub("%s+", "")
    local compactQuery = query:gsub("%s+", "")
    if compactQuery ~= "" and compactHay:find(compactQuery, 1, true) then
        return true
    end
    for word in query:gmatch("%S+") do
        if not hay:find(word, 1, true) then
            return false
        end
    end
    return query ~= ""
end

function Library:_FlashSearchRow(row)
    if not row or not row.Parent then return end
    local flash = New("Frame", {
        Parent = row,
        BackgroundColor3 = self.Theme.Accent,
        BackgroundTransparency = 0.82,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 5,
    })
    Corner(4, flash)
    Tween(flash, 0.35, { BackgroundTransparency = 1 })
    task.delay(0.4, function()
        if flash.Parent then flash:Destroy() end
    end)
end

function Library:_NavigateToSearchEntry(entry)
    if not entry then return end
    self:CloseAllPopups()
    if entry.TabSelect then entry.TabSelect() end
    if entry.TabboxSelect then entry.TabboxSelect() end
    task.defer(function()
        RunService.Heartbeat:Wait()
        local scroll = entry.ScrollFrame
        local row = entry.Row
        if scroll and row and row.Parent then
            local relY = row.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y
            scroll.CanvasPosition = Vector2.new(0, math.max(0, relY - 20))
            self:_FlashSearchRow(row)
        end
    end)
end

function Library:_CreateTabSearchHeader(page, Tab)
    local HEADER_H = 36
    local SEARCH_H = 28

    local header = New("Frame", {
        Name = "SearchHeader",
        Parent = page,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, HEADER_H),
        ZIndex = 2,
    })

    New("UIListLayout", {
        Parent = header,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 12),
    })

    local tabInfo = New("Frame", {
        Name = "TabInfo",
        Parent = header,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, HEADER_H),
        LayoutOrder = 1,
    })
    New("UIListLayout", {
        Parent = tabInfo,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    })

    if Tab.Icon then
        local tabIcon = New("ImageLabel", {
            Name = "TabIcon",
            Parent = tabInfo,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(18, 18),
            Image = Tab.Icon,
            ImageColor3 = self.Theme.Accent,
            LayoutOrder = 1,
        })
        self:AddToRegistry(tabIcon, "ImageColor3", "Accent")
    else
        local dot = New("Frame", {
            Parent = tabInfo,
            Size = UDim2.fromOffset(8, 8),
            BackgroundColor3 = self.Theme.Accent,
            BorderSizePixel = 0,
            LayoutOrder = 1,
        })
        Corner(4, dot)
        self:AddToRegistry(dot, "BackgroundColor3", "Accent")
    end

    local tabNameLabel = New("TextLabel", {
        Name = "TabName",
        Parent = tabInfo,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Font = self.FontBold,
        Text = Tab.Name or "tab",
        TextSize = 16,
        TextColor3 = self.Theme.LightText,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
    })
    self:AddToRegistry(tabNameLabel, "TextColor3", "LightText")

    local searchWrap = New("Frame", {
        Name = "SearchBar",
        Parent = header,
        BackgroundColor3 = self.Theme.Inline,
        Size = UDim2.new(1, 0, 0, SEARCH_H),
        LayoutOrder = 2,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    self:AddToRegistry(searchWrap, "BackgroundColor3", "Inline")
    self:AddToRegistry(Stroke(searchWrap, self.Theme.Border, 1, 0), "Color", "Border")
    Corner(1, searchWrap)

    New("ImageLabel", {
        Name = "SearchIcon",
        Parent = searchWrap,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(9, 5),
        Size = UDim2.fromOffset(18, 18),
        Image = self.SearchIconAsset,
        ScaleType = Enum.ScaleType.Fit,
    })

    local searchBox = New("TextBox", {
        Parent = searchWrap,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(32, 0),
        Size = UDim2.new(1, -38, 1, 0),
        Font = self.Font,
        Text = "",
        PlaceholderText = "search",
        PlaceholderColor3 = self.Theme.DarkText,
        TextColor3 = self.Theme.LightText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    })
    self:AddToRegistry(searchBox, "TextColor3", "LightText")

    local results = New("Frame", {
        Name = "SearchResults",
        Parent = page,
        BackgroundColor3 = self.Theme.SectionBackground,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, HEADER_H + 6),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 20,
    })
    Corner(6, results)
    self:AddToRegistry(results, "BackgroundColor3", "SectionBackground")
    self:AddToRegistry(Stroke(results, self.Theme.Border, 1, 0), "Color", "Border")
    New("UISizeConstraint", { Parent = results, MaxSize = Vector2.new(10000, 240) })
    Padding(results, 4)

    local function alignResults()
        local tabW = tabInfo.AbsoluteSize.X
        local gap = 12
        results.Position = UDim2.fromOffset(tabW + gap, HEADER_H + 6)
        results.Size = UDim2.new(1, -(tabW + gap), 0, 0)
    end

    local resultsList = New("ScrollingFrame", {
        Parent = results,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = self.Theme.Accent,
        Active = true,
        ZIndex = 11,
    })
    New("UIListLayout", {
        Parent = resultsList,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 0),
    })

    local resultRows = {}

    local function clearResults()
        for _, row in ipairs(resultRows) do row:Destroy() end
        table.clear(resultRows)
        results.Visible = false
    end

    local function addResultRow(entry, layoutOrder)
        local rowBtn = New("TextButton", {
            Parent = resultsList,
            BackgroundColor3 = self.Theme.Inline,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            Size = UDim2.new(1, 0, 0, 30),
            LayoutOrder = layoutOrder,
            ZIndex = 12,
        })
        Corner(4, rowBtn)

        local inner = New("Frame", {
            Parent = rowBtn,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -8, 1, 0),
            Position = UDim2.fromOffset(4, 0),
        })
        New("UIListLayout", {
            Parent = inner,
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
        })

        if entry.TabIcon then
            local icon = New("ImageLabel", {
                Parent = inner,
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(14, 14),
                Image = entry.TabIcon,
                ImageColor3 = self.Theme.Accent,
                LayoutOrder = 1,
            })
            self:AddToRegistry(icon, "ImageColor3", "Accent")
        else
            local dot = New("Frame", {
                Parent = inner,
                Size = UDim2.fromOffset(6, 6),
                BackgroundColor3 = self.Theme.Accent,
                BorderSizePixel = 0,
                LayoutOrder = 1,
            })
            Corner(3, dot)
            self:AddToRegistry(dot, "BackgroundColor3", "Accent")
        end

        New("TextLabel", {
            Parent = inner,
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromScale(0, 1),
            Font = self.Font,
            Text = entry.TabName or "tab",
            TextSize = 13,
            TextColor3 = self.Theme.DarkText,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
        })

        New("TextLabel", {
            Parent = inner,
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromScale(0, 1),
            Font = self.Font,
            Text = entry.Text or "",
            TextSize = 13,
            TextColor3 = self.Theme.LightText,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 3,
        })

        if entry.GroupTitle and entry.GroupTitle ~= "" then
            New("TextLabel", {
                Parent = inner,
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.fromScale(0, 1),
                Font = self.Font,
                Text = "· " .. entry.GroupTitle,
                TextSize = 12,
                TextColor3 = self.Theme.DarkText,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 4,
            })
        end

        Connect(rowBtn.MouseEnter, function()
            rowBtn.BackgroundTransparency = 0
        end)
        Connect(rowBtn.MouseLeave, function()
            rowBtn.BackgroundTransparency = 1
        end)
        Connect(rowBtn.MouseButton1Click, function()
            clearResults()
            searchBox.Text = ""
            self:_NavigateToSearchEntry(entry)
        end)

        table.insert(resultRows, rowBtn)
    end

    local function refreshResults()
        for _, row in ipairs(resultRows) do row:Destroy() end
        table.clear(resultRows)

        local query = string.lower((searchBox.Text or ""):match("^%s*(.-)%s*$") or "")
        if query == "" then
            results.Visible = false
            return
        end

        local matches = {}
        for _, entry in ipairs(self.SearchIndex) do
            if searchEntryMatches(entry, query) then
                table.insert(matches, entry)
            end
        end

        alignResults()

        if #matches == 0 then
            local empty = New("TextLabel", {
                Parent = resultsList,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 28),
                Font = self.Font,
                Text = "no results",
                TextSize = 13,
                TextColor3 = self.Theme.DarkText,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            table.insert(resultRows, empty)
            results.Visible = true
            return
        end

        for i, entry in ipairs(matches) do
            if i > 24 then break end
            addResultRow(entry, i)
        end
        results.Visible = true
    end

    Connect(searchBox:GetPropertyChangedSignal("Text"), refreshResults)

    local searchPanel = {
        Clear = clearResults,
        Results = results,
        Hits = { searchWrap, results, searchBox },
    }
    table.insert(self.ActiveSearchPanels, searchPanel)

    return HEADER_H
end

function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local title, titleIcon = parseTitle(cfg.Title, cfg.Icon or cfg.TitleIcon)
    Library.Title = title
    Library.TitleIcon = titleIcon
    local mobile   = self.IsMobile or cfg.Mobile
    local baseSize = cfg.Size or UDim2.fromOffset(720, 540)
    local sidebarW = cfg.SidebarWidth or 150

    local gui = New("ScreenGui", {
        Name = "void_" .. tostring(math.random(1000, 9999)),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 9999,
    })
    local ok = pcall(function()
        if gethui then
            gui.Parent = gethui()
        elseif syn and syn.protect_gui then
            syn.protect_gui(gui)
            gui.Parent = game:GetService("CoreGui")
        else
            gui.Parent = game:GetService("CoreGui")
        end
    end)
    if not ok then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    Library.ScreenGui = gui

    local centered = mobile or cfg.Center ~= false
    local main = New("Frame", {
        Name = "Main",
        Parent = gui,
        Size = baseSize,
        AnchorPoint = centered and Vector2.new(0.5, 0.5) or Vector2.new(0, 0),
        Position = centered and UDim2.fromScale(0.5, 0.5) or UDim2.fromOffset(60, 60),
        BackgroundColor3 = Library.Theme.DarkBackground,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    Library:AddToRegistry(main, "BackgroundColor3", "DarkBackground")
    Corner(6, main)
    Stroke(main, Color3.fromRGB(0, 0, 0), 1, 0.3)
    Library.MainFrame = main

    local uiScale = New("UIScale", { Parent = main, Scale = 1 })
    if mobile then uiScale.Scale = cfg.MobileScale or 0.6 end
    Library.UIScale = uiScale

    local sidebar = New("Frame", {
        Name = "Sidebar",
        Parent = main,
        Size = UDim2.new(0, sidebarW, 1, 0),
        BackgroundColor3 = Library.Theme.DarkBackground,
        BorderSizePixel = 0,
    })
    Library:AddToRegistry(sidebar, "BackgroundColor3", "DarkBackground")

    Library:AddToRegistry(New("Frame", {
        Parent = sidebar,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BorderSizePixel = 0,
    }), "BackgroundColor3", "Border")

    local titleHolder = New("Frame", {
        Name = "TitleHolder",
        Parent = sidebar,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 20),
        Size = UDim2.new(1, -16, 0, 32),
    })
    local titleParent = titleHolder
    if titleIcon then
        local titleInner = New("Frame", {
            Name = "TitleInner",
            Parent = titleHolder,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            AutomaticSize = Enum.AutomaticSize.XY,
        })
        titleParent = titleInner
        New("UIListLayout", {
            Parent = titleInner,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
        })
        local titleIconObj = New("ImageLabel", {
            Name = "TitleIcon",
            Parent = titleInner,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(22, 22),
            Image = titleIcon,
            ImageColor3 = Library.Theme.TitleColor,
            LayoutOrder = 1,
        })
        Library:AddToRegistry(titleIconObj, "ImageColor3", "TitleColor")
        Library.TitleIconLabel = titleIconObj
    end
    local titleLabel = New("TextLabel", {
        Name = "Title",
        Parent = titleParent,
        BackgroundTransparency = 1,
        AutomaticSize = titleIcon and Enum.AutomaticSize.XY or Enum.AutomaticSize.None,
        AnchorPoint = titleIcon and Vector2.new(0, 0) or Vector2.new(0.5, 0.5),
        Position = titleIcon and UDim2.fromScale(0, 0) or UDim2.fromScale(0.5, 0.5),
        Size = titleIcon and UDim2.fromScale(0, 0) or UDim2.new(1, 0, 1, 0),
        Font = Library.FontBold,
        Text = title,
        TextSize = 23,
        TextColor3 = Library.Theme.TitleColor,
        TextXAlignment = titleIcon and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
        LayoutOrder = 2,
    })
    Library:AddToRegistry(titleLabel, "TextColor3", "TitleColor")
    Library.TitleLabel = titleLabel

    local tabHolder = New("Frame", {
        Name = "TabHolder",
        Parent = sidebar,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 72),
        Size = UDim2.new(1, -16, 1, -84),
    })
    New("UIListLayout", {
        Parent = tabHolder,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    })

    local content = New("Frame", {
        Name = "Content",
        Parent = main,
        Position = UDim2.fromOffset(sidebarW, 0),
        Size = UDim2.new(1, -sidebarW, 1, 0),
        BackgroundColor3 = Library.Theme.PageBackground,
        BorderSizePixel = 0,
    })
    Library:AddToRegistry(content, "BackgroundColor3", "PageBackground")

    do
        local dragging, dragStart, startPos
        local dragZone = New("TextButton", {
            Parent = sidebar,
            BackgroundTransparency = 1,
            Text = "",
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, 0, 0, 64),
            AutoButtonColor = false,
        })
        Connect(dragZone.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = main.Position
                Library:CloseAllPopups()
            end
        end)
        Connect(UserInputService.InputChanged, function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        Connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    Library.NotifyHolder = New("Frame", {
        Parent = gui,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 12),
        Size = UDim2.new(0, 280, 1, -24),
    })
    New("UIListLayout", {
        Parent = Library.NotifyHolder,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    })

    local Window = { Tabs = {}, TabHolder = tabHolder, Content = content, Gui = gui, Main = main }

    function Window:AddTab(name, icon)
        local tabButton = New("TextButton", {
            Name = name,
            Parent = tabHolder,
            BackgroundColor3 = Library.Theme.SectionBackground,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 34),
            AutoButtonColor = false,
            Text = "",
        })
        Corner(5, tabButton)
        Library:AddToRegistry(tabButton, "BackgroundColor3", "SectionBackground")

        local iconObj
        local imageId = formatImage(icon)
        if imageId then
            iconObj = New("ImageLabel", {
                Parent = tabButton,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 9),
                Size = UDim2.fromOffset(16, 16),
                Image = imageId,
                ImageColor3 = Library.Theme.DarkText,
            })
        else
            iconObj = New("Frame", {
                Parent = tabButton,
                Position = UDim2.fromOffset(14, 14),
                Size = UDim2.fromOffset(6, 6),
                BackgroundColor3 = Library.Theme.DarkText,
                BorderSizePixel = 0,
            })
            Corner(3, iconObj)
        end

        local tabText = New("TextLabel", {
            Parent = tabButton,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(36, 0),
            Size = UDim2.new(1, -44, 1, 0),
            Font = Library.Font,
            Text = name,
            TextSize = 14,
            TextColor3 = Library.Theme.DarkText,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        local page = New("Frame", {
            Name = name .. "_Page",
            Parent = content,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
        })
        Padding(page, 14)

        local Tab = {
            Page = page,
            Button = tabButton,
            Name = name,
            Icon = imageId,
            Select = nil,
        }
        local headerH = Library:_CreateTabSearchHeader(page, Tab)

        local contentArea = New("Frame", {
            Name = "ContentArea",
            Parent = page,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, headerH + 8),
            Size = UDim2.new(1, 0, 1, -(headerH + 8)),
        })

        local left = New("ScrollingFrame", {
            Name = "Left",
            Parent = contentArea,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0.5, -7, 1, 0),
            Position = UDim2.fromScale(0, 0),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 0,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        })
        New("UIListLayout", { Parent = left, Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder })

        local right = New("ScrollingFrame", {
            Name = "Right",
            Parent = contentArea,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0.5, -7, 1, 0),
            Position = UDim2.new(0.5, 7, 0, 0),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 0,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        })
        New("UIListLayout", { Parent = right, Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder })

        Tab.LeftColumn = left
        Tab.RightColumn = right

        local function select()
            Library:CloseAllPopups()
            Library:CloseAllSearchPanels()
            Library._currentTabSelect = select
            for _, t in ipairs(Window.Tabs) do
                t.Page.Visible = false
                t.Button.BackgroundTransparency = 1
                t._text.TextColor3 = Library.Theme.DarkText
                if t._icon:IsA("ImageLabel") then
                    t._icon.ImageColor3 = Library.Theme.DarkText
                else
                    t._icon.BackgroundColor3 = Library.Theme.DarkText
                end
            end
            page.Visible = true
            tabButton.BackgroundTransparency = 0
            tabButton.BackgroundColor3 = Library.Theme.SectionBackground
            tabText.TextColor3 = Library.Theme.Accent
            if iconObj:IsA("ImageLabel") then
                iconObj.ImageColor3 = Library.Theme.Accent
            else
                iconObj.BackgroundColor3 = Library.Theme.Accent
            end
        end

        Tab._text = tabText
        Tab._icon = iconObj
        Tab.Select = select

        Connect(tabButton.MouseButton1Click, select)
        Connect(tabButton.MouseEnter, function()
            if not page.Visible then tabText.TextColor3 = Library.Theme.Text end
        end)
        Connect(tabButton.MouseLeave, function()
            if not page.Visible then tabText.TextColor3 = Library.Theme.DarkText end
        end)

        local function makeSection(parentColumn, sTitle, sSub)
            local section = New("Frame", {
                Parent = parentColumn,
                BackgroundColor3 = Library.Theme.SectionBackground,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
            })
            Library:AddToRegistry(section, "BackgroundColor3", "SectionBackground")
            Corner(5, section)
            Library:AddToRegistry(Stroke(section, Library.Theme.Border, 1, 0), "Color", "Border")
            Padding(section, 12)
            section:SetAttribute("VoidRowOrder", 0)

            New("UIListLayout", {
                Parent = section,
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            local header = New("Frame", {
                Parent = section,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, sSub and 33 or 19),
                LayoutOrder = -1,
            })
            local tl = New("TextLabel", {
                Parent = header,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 17),
                Font = Library.FontBold,
                Text = sTitle or "section",
                TextSize = 14,
                TextColor3 = Library.Theme.LightText,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            Library:AddToRegistry(tl, "TextColor3", "LightText")
            if sSub then
                local sl = New("TextLabel", {
                    Parent = header,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 17),
                    Size = UDim2.new(1, 0, 0, 14),
                    Font = Library.Font,
                    Text = sSub,
                    TextSize = 12,
                    TextColor3 = Library.Theme.DarkText,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                Library:AddToRegistry(sl, "TextColor3", "DarkText")
            end

            return Library:_BuildSection(section, {
                Tab = Tab,
                GroupTitle = sTitle,
                ScrollFrame = parentColumn,
            })
        end

        local function makeTabbox(parentColumn)
            local box = New("Frame", {
                Parent = parentColumn,
                BackgroundColor3 = Library.Theme.SectionBackground,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
            })
            Library:AddToRegistry(box, "BackgroundColor3", "SectionBackground")
            Corner(5, box)
            Library:AddToRegistry(Stroke(box, Library.Theme.Border, 1, 0), "Color", "Border")
            Padding(box, 12)

            New("UIListLayout", {
                Parent = box,
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            local tabButtons = New("Frame", {
                Parent = box,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 26),
                LayoutOrder = 0,
            })
            New("UIListLayout", {
                Parent = tabButtons,
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            local contentHolder = New("Frame", {
                Parent = box,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = 1,
            })

            local Tabbox = { Tabs = {}, _current = nil }

            local function selectTab(tab)
                Library:CloseAllPopups()
                Tabbox._current = tab
                for _, t in ipairs(Tabbox.Tabs) do
                    t.Page.Visible = false
                    t.Button.BackgroundColor3 = Library.Theme.Inline
                    t._label.TextColor3 = Library.Theme.DarkText
                    if t._stroke then
                        t._stroke.Color = Library.Theme.Border
                    end
                end
                tab.Page.Visible = true
                tab.Button.BackgroundColor3 = Library.Theme.Inline
                tab._label.TextColor3 = Library.Theme.Accent
                if tab._stroke then
                    tab._stroke.Color = Library.Theme.Accent
                end
            end

            function Tabbox:AddTab(name)
                local tabBtn = New("TextButton", {
                    Parent = tabButtons,
                    AutoButtonColor = false,
                    Text = "",
                    BackgroundColor3 = Library.Theme.Inline,
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                })
                Library:AddToRegistry(tabBtn, "BackgroundColor3", "Inline")
                Corner(4, tabBtn)
                local tabStroke = Stroke(tabBtn, Library.Theme.Border, 1, 0)
                Library:AddToRegistry(tabStroke, "Color", "Border")
                Padding(tabBtn, nil, 10, 10, 0, 0)

                local tabLabel = New("TextLabel", {
                    Parent = tabBtn,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Font = Library.Font,
                    Text = name or "tab",
                    TextSize = 13,
                    TextColor3 = Library.Theme.DarkText,
                })
                Library:AddToRegistry(tabLabel, "TextColor3", "DarkText")

                local page = New("Frame", {
                    Parent = contentHolder,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Visible = false,
                })
                New("UIListLayout", {
                    Parent = page,
                    Padding = UDim.new(0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                })

                local tab = {
                    Name = name,
                    Page = page,
                    Button = tabBtn,
                    _label = tabLabel,
                    _stroke = tabStroke,
                }

                Connect(tabBtn.MouseButton1Click, function()
                    selectTab(tab)
                end)
                Connect(tabBtn.MouseEnter, function()
                    if Tabbox._current ~= tab then
                        tabLabel.TextColor3 = Library.Theme.Text
                    end
                end)
                Connect(tabBtn.MouseLeave, function()
                    if Tabbox._current ~= tab then
                        tabLabel.TextColor3 = Library.Theme.DarkText
                    end
                end)

                table.insert(Tabbox.Tabs, tab)
                if #Tabbox.Tabs == 1 then
                    selectTab(tab)
                end

                return Library:_BuildSection(page, {
                    Tab = Tab,
                    GroupTitle = name,
                    ScrollFrame = parentColumn,
                    TabboxSelect = function() selectTab(tab) end,
                })
            end

            return Tabbox
        end

        function Tab:AddLeftTabbox()  return makeTabbox(left) end
        function Tab:AddRightTabbox() return makeTabbox(right) end
        Tab.AddTabbox = function(_, side)
            return makeTabbox(side == "right" and right or left)
        end

        function Tab:AddLeftGroupbox(t, sub)  return makeSection(left, t, sub) end
        function Tab:AddRightGroupbox(t, sub) return makeSection(right, t, sub) end
        Tab.AddSection = function(_, t, side, sub)
            return makeSection(side == "right" and right or left, t, sub)
        end

        function Tab:AddSkinChangerPage(cfg)
            left.Visible = false
            right.Visible = false
            return Library:_BuildSkinChangerPage(page, cfg or {})
        end

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then select() end
        return Tab
    end

    function Window:Toggle()
        Library.Open = not Library.Open
        main.Visible = Library.Open
        if not Library.Open then
            Library:CloseAllPopups()
        end
    end

    Library.Window = Window
    Library.Open = true
    Library:_InitGlobals(main, mobile)

    task.spawn(function()
        Library:DownloadAllFonts()
    end)

    return Window
end

function Library:_InitGlobals(main, mobile)
    if self._globalsInit then return end
    self._globalsInit = true

    Connect(RunService.RenderStepped, function()
        for popup, data in pairs(self.ActivePopups) do
            if popup.Visible and data.PosFn then
                local anchor = data.Anchor
                if not anchor or not anchor.Parent or not isGuiShown(anchor) then
                    self:ClosePopup(popup)
                else
                    data.PosFn()
                end
            elseif not popup.Visible then
                self.ActivePopups[popup] = nil
            end
        end
        self:_UpdateWatermark()
    end)

    Connect(UserInputService.InputBegan, function(input, gpe)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            for popup, data in pairs(self.ActivePopups) do
                if popup.Visible then
                    if not within(pos, popup) and not within(pos, data.Anchor) then
                        self:ClosePopup(popup)
                    end
                end
            end
            for _, panel in ipairs(self.ActiveSearchPanels) do
                if panel.Results and panel.Results.Visible then
                    local hit = false
                    for _, obj in ipairs(panel.Hits) do
                        if within(pos, obj) then
                            hit = true
                            break
                        end
                    end
                    if not hit and panel.Clear then
                        panel.Clear()
                    end
                end
            end
        end
        if input.UserInputType == Enum.UserInputType.Keyboard and not self._capturing then
            if self.MenuKeybind and input.KeyCode == self.MenuKeybind then
                self.Window:Toggle()
            end
        end
    end)

    if mobile then
        self:_CreateMobileButton(main)
    end
end

function Library:SetMenuKeybind(keyCode)
    self.MenuKeybind = keyCode
end

function Library:_CreateMobileButton(main)
    local btn = New("TextButton", {
        Parent = self.ScreenGui,
        Size = UDim2.fromOffset(46, 46),
        Position = UDim2.fromOffset(20, 120),
        BackgroundColor3 = self.Theme.SectionBackground,
        AutoButtonColor = false,
        Font = self.FontBold,
        Text = "ui",
        TextSize = 16,
        TextColor3 = self.Theme.Accent,
        ZIndex = 200,
    })
    Corner(23, btn)
    self:AddToRegistry(btn, "BackgroundColor3", "SectionBackground")
    self:AddToRegistry(Stroke(btn, self.Theme.Accent, 1, 0), "Color", "Accent")

    local dragging, moved, startPos, btnStart
    Connect(btn.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            moved = false
            startPos = input.Position
            btnStart = btn.Position
        end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - startPos
            if delta.Magnitude > 6 then moved = true end
            btn.Position = UDim2.new(btnStart.X.Scale, btnStart.X.Offset + delta.X,
                btnStart.Y.Scale, btnStart.Y.Offset + delta.Y)
        end
    end)
    Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragging and not moved then
                self.Window:Toggle()
            end
            dragging = false
        end
    end)
    self.MobileButton = btn
end

function Library:CreateWatermark(text)
    self.WatermarkText = text or self.Title or "void"
    local wm = New("Frame", {
        Parent = self.ScreenGui,
        Position = UDim2.fromOffset(20, 20),
        Size = UDim2.new(0, 10, 0, 26),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = self.Theme.SectionBackground,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 150,
    })
    self:AddToRegistry(wm, "BackgroundColor3", "SectionBackground")
    Corner(5, wm)
    self:AddToRegistry(Stroke(wm, self.Theme.Border, 1, 0), "Color", "Border")
    New("Frame", { Parent = wm, Size = UDim2.new(0, 2, 1, 0), BorderSizePixel = 0,
        BackgroundColor3 = self.Theme.Accent, ZIndex = 151 })
    self:AddToRegistry(wm:FindFirstChildOfClass("Frame"), "BackgroundColor3", "Accent")
    local lbl = New("TextLabel", {
        Parent = wm, BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
        Font = self.Font, TextSize = 14, TextColor3 = self.Theme.LightText, Text = self.WatermarkText,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 151,
    })
    New("UIPadding", { Parent = wm, PaddingRight = UDim.new(0, 12) })
    makeDraggable(wm)
    self.Watermark = wm
    self.WatermarkLabel = lbl
    return wm
end

function Library:SetWatermarkVisible(v)
    if not self.Watermark then self:CreateWatermark() end
    self.Watermark.Visible = v and true or false
end

function Library:_UpdateWatermark()
    if not (self.Watermark and self.Watermark.Visible) then return end
    local now = tick()
    self._wmAccum = (self._wmAccum or 0) + 1
    if now - (self._wmLast or 0) < 0.5 then return end
    local dt = now - (self._wmLast or now)
    local fps = self._wmLast and math.floor(self._wmAccum / dt) or 60
    self._wmLast = now
    self._wmAccum = 0
    local ping = 0
    if Stats then
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
    end
    self.WatermarkLabel.Text = string.format("%s  |  %d fps  |  %d ms", self.WatermarkText or "void", fps, ping)
end

local function resolveIgnoreConfig(info)
    if info and info.IgnoreConfig ~= nil then return info.IgnoreConfig end
    return Library._ignoreConfig
end

function Library:_BuildSection(container, ctx)
    ctx = ctx or {}
    local prevCtx = self._currentSectionCtx
    self._currentSectionCtx = ctx
    local Section = { Container = container, _searchCtx = ctx }

    local function registerSearch(row, text, id)
        Library:_RegisterSearchFromRow(row, text, id, ctx)
    end

    function Section:AddLabel(text, doesWrap)
        local row = makeRow(container, doesWrap and 0 or 19)
        if doesWrap then row.AutomaticSize = Enum.AutomaticSize.Y end
        local label = New("TextLabel", {
            Parent = row,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, doesWrap and 0 or -60, doesWrap and 0 or 1, 0),
            AutomaticSize = doesWrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            Font = Library.Font,
            Text = text or "label",
            TextSize = 14,
            TextColor3 = Library.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = doesWrap or false,
            TextYAlignment = Enum.TextYAlignment.Center,
        })
        Library:AddToRegistry(label, "TextColor3", "Text")
        local holder = makeAddonHolder(row)
        local Label = { Instance = label, Row = row, AddonHolder = holder }
        function Label:SetText(t) label.Text = t return Label end
        function Label:AddColorPicker(id, info) return Library:_ColorPicker(holder, id, info) end
        function Label:AddKeyPicker(id, info)   return Library:_KeyPicker(holder, id, info) end
        return Label
    end

    function Section:AddDivider()
        local row = makeRow(container, 10)
        local line = New("Frame", {
            Parent = row,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, 0, 0, 2),
            BackgroundColor3 = Library.Theme.Border,
            BorderSizePixel = 0,
        })
        Library:AddToRegistry(line, "BackgroundColor3", "Border")
        New("UICorner", { Parent = line, CornerRadius = UDim.new(1, 0) })
        return { Instance = line, Row = row }
    end

    local function normalizeButton(a, b)
        if type(a) == "string" and type(b) == "table" then
            b.Id = b.Id or a
            return b
        elseif type(a) == "string" and type(b) == "function" then
            return { Text = a, Func = b }
        elseif type(a) == "string" then
            return { Text = a, Id = a }
        elseif type(a) == "table" then
            return a
        elseif type(a) == "function" then
            return { Text = "button", Func = a }
        end
        return {}
    end

    function Section:AddButton(a, b)
        local info = normalizeButton(a, b)
        local rowHolder = makeRow(container, 30)
        New("UIListLayout", {
            Parent = rowHolder,
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
        })
        local buttons = {}
        local function resize()
            local n = #buttons
            for _, b in ipairs(buttons) do
                b.Size = UDim2.new(1 / n, n > 1 and -3 or 0, 1, 0)
            end
        end
        local function build(c)
            c = c or {}
            local btn = New("TextButton", {
                Parent = rowHolder,
                BackgroundColor3 = Library.Theme.Inline,
                AutoButtonColor = false,
                Font = Library.Font,
                Text = c.Text or "button",
                TextSize = 14,
                TextColor3 = Library.Theme.Text,
                Size = UDim2.new(1, 0, 1, 0),
            })
            Library:AddToRegistry(btn, "BackgroundColor3", "Inline")
            Library:AddToRegistry(btn, "TextColor3", "Text")
            Corner(5, btn)
            Library:AddToRegistry(Stroke(btn, Library.Theme.Border, 1, 0), "Color", "Border")
            table.insert(buttons, btn)
            resize()
            Connect(btn.MouseEnter, function() Tween(btn, 0.12, { BackgroundColor3 = Library.Theme.Border }) end)
            Connect(btn.MouseLeave, function() Tween(btn, 0.12, { BackgroundColor3 = Library.Theme.Inline }) end)
            Connect(btn.MouseButton1Click, function()
                spawnFn(c.Func)
                spawnFn(c.Callback)
            end)
            local Button = { Instance = btn, Type = "Button", Id = c.Id, IgnoreConfig = true }
            if c.Id then Library.Options[c.Id] = Button end
            registerSearch(rowHolder, c.Text or "button", c.Id)
            function Button:SetText(t) btn.Text = t return Button end
            function Button:AddButton(a2, b2) return build(normalizeButton(a2, b2)) end
            return Button
        end
        return build(info)
    end

    function Section:AddToggle(id, info)
        info = info or {}
        local row = makeRow(container, 19)
        local label = New("TextLabel", {
            Parent = row,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -60, 1, 0),
            Font = Library.Font,
            Text = info.Text or id,
            TextSize = 14,
            TextColor3 = Library.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        Library:AddToRegistry(label, "TextColor3", "Text")
        local holder = makeAddonHolder(row)
        local box = New("TextButton", {
            Parent = holder,
            LayoutOrder = 1000,
            AutoButtonColor = false,
            Text = "",
            BackgroundColor3 = Library.Theme.Inline,
            Size = UDim2.fromOffset(16, 16),
        })
        Library:AddToRegistry(box, "BackgroundColor3", "Inline")
        Corner(4, box)
        local boxStroke = Stroke(box, Library.Theme.Border, 1, 0)
        local fill = New("Frame", {
            Parent = box,
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Library.Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        Library:AddToRegistry(fill, "BackgroundColor3", "Accent")
        Corner(4, fill)
        local Toggle = {
            Value = info.Default or false,
            Callbacks = {},
            Type = "Toggle",
            Instance = box,
            AddonHolder = holder,
            Id = id,
            IgnoreConfig = resolveIgnoreConfig(info),
        }
        function Toggle:OnChanged(fn) pushCallback(self.Callbacks, fn) return self end
        function Toggle:_fire()
            for _, fn in ipairs(self.Callbacks) do spawnFn(fn, self.Value) end
            spawnFn(info.Callback, self.Value)
            Library:_UpdateDependencies()
        end
        function Toggle:SetValue(v)
            self.Value = v and true or false
            Tween(fill, 0.12, { BackgroundTransparency = self.Value and 0 or 1 })
            Tween(boxStroke, 0.12, { Color = self.Value and Library.Theme.Accent or Library.Theme.Border })
            self:_fire()
            return self
        end
        Toggle._boxStroke = boxStroke
        Connect(box.MouseButton1Click, function() Toggle:SetValue(not Toggle.Value) end)
        function Toggle:AddColorPicker(cid, cinfo) return Library:_ColorPicker(holder, cid, cinfo) end
        function Toggle:AddKeyPicker(kid, kinfo)
            kinfo = kinfo or {}
            if kinfo.SyncToggleState then kinfo._toggle = Toggle end
            local kp = Library:_KeyPicker(holder, kid, kinfo)
            kp._linkedToggle = Toggle
            return kp
        end

        Toggle:SetValue(Toggle.Value)

        Library.Toggles[id] = Toggle
        registerSearch(row, info.Text or id, id)
        return Toggle
    end

    function Section:AddSlider(id, info)
        local function buildSlider(sid, sinfo)
            sinfo = sinfo or {}
            local min      = sinfo.Min or 0
            local max      = sinfo.Max or 100
            local rounding = sinfo.Rounding or 0
            local suffix   = sinfo.Suffix or ""
            local default  = math.clamp(sinfo.Default or min, min, max)
            local row = makeRow(container, 34)
            local label = New("TextLabel", {
                Parent = row, BackgroundTransparency = 1, Size = UDim2.new(1, -90, 0, 16),
                Font = Library.Font, Text = sinfo.Text or sid, TextSize = 14,
                TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
            })
            Library:AddToRegistry(label, "TextColor3", "Text")
            local valueLabel = New("TextLabel", {
                Parent = row, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 90, 0, 16),
                Font = Library.Font, Text = "", TextSize = 14, TextColor3 = Library.Theme.DarkText,
                TextXAlignment = Enum.TextXAlignment.Right,
            })
            Library:AddToRegistry(valueLabel, "TextColor3", "DarkText")
            local track = New("Frame", {
                Parent = row, Position = UDim2.new(0, 0, 1, -8), Size = UDim2.new(1, 0, 0, 4),
                BackgroundColor3 = Library.Theme.Inline, BorderSizePixel = 0,
            })
            Library:AddToRegistry(track, "BackgroundColor3", "Inline")
            Corner(2, track)
            Library:AddToRegistry(Stroke(track, Library.Theme.Border, 1, 0), "Color", "Border")
            local fill = New("Frame", {
                Parent = track, Size = UDim2.fromScale(0, 1), BackgroundColor3 = Library.Theme.Accent, BorderSizePixel = 0,
            })
            Library:AddToRegistry(fill, "BackgroundColor3", "Accent")
            Corner(2, fill)
            local Slider = { Value = default, Callbacks = {}, Type = "Slider", Id = sid, IgnoreConfig = resolveIgnoreConfig(sinfo) }
            function Slider:OnChanged(fn) pushCallback(self.Callbacks, fn) return self end
            local function round(v)
                if rounding <= 0 then return math.floor(v + 0.5) end
                local m = 10 ^ rounding
                return math.floor(v * m + 0.5) / m
            end
            function Slider:SetValue(v, skipCb)
                v = math.clamp(round(v), min, max)
                self.Value = v
                local alpha = (max - min) == 0 and 0 or (v - min) / (max - min)
                fill.Size = UDim2.fromScale(alpha, 1)
                valueLabel.Text = tostring(v) .. (suffix ~= "" and (" " .. suffix) or "")
                if not skipCb then
                    for _, fn in ipairs(self.Callbacks) do spawnFn(fn, v) end
                    spawnFn(sinfo.Callback, v)
                end
                return self
            end
            function Slider:AddSlider(a, b)
                local nextId, nextInfo = sid, sinfo
                if type(a) == "string" and type(b) == "table" then
                    nextId, nextInfo = a, b
                elseif type(a) == "table" then
                    nextInfo = a
                    nextId = a.Id or sid .. "_2"
                end
                return buildSlider(nextId, nextInfo)
            end
            local dragging = false
            local function update(inputX)
                local rel = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                Slider:SetValue(min + (max - min) * rel)
            end
            Connect(track.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    update(input.Position.X)
                end
            end)
            Connect(UserInputService.InputChanged, function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input.Position.X)
                end
            end)
            Connect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            Slider:SetValue(default, true)
            Library.Options[sid] = Slider
            registerSearch(row, sinfo.Text or sid, sid)
            return Slider
        end
        return buildSlider(id, info)
    end

    function Section:AddInput(id, info)
        info = info or {}
        local hasLabel = info.Text ~= nil
        local row = makeRow(container, hasLabel and 44 or 28)
        if hasLabel then
            local l = New("TextLabel", {
                Parent = row, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
                Font = Library.Font, Text = info.Text, TextSize = 14,
                TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
            })
            Library:AddToRegistry(l, "TextColor3", "Text")
        end
        local boxFrame = New("Frame", {
            Parent = row, Position = UDim2.new(0, 0, 0, hasLabel and 22 or 0),
            Size = UDim2.new(1, 0, 0, hasLabel and 22 or 28),
            BackgroundColor3 = Library.Theme.Inline, BorderSizePixel = 0,
        })
        Library:AddToRegistry(boxFrame, "BackgroundColor3", "Inline")
        Corner(5, boxFrame)
        Library:AddToRegistry(Stroke(boxFrame, Library.Theme.Border, 1, 0), "Color", "Border")
        Padding(boxFrame, nil, 8, 8, 0, 0)
        local textBox = New("TextBox", {
            Parent = boxFrame, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
            Font = Library.Font, Text = info.Default or "", PlaceholderText = info.Placeholder or "",
            PlaceholderColor3 = Library.Theme.DarkText, TextColor3 = Library.Theme.LightText,
            TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
            ClipsDescendants = true,
        })
        Library:AddToRegistry(textBox, "TextColor3", "LightText")
        local Input = { Value = info.Default or "", Callbacks = {}, Type = "Input", Id = id, IgnoreConfig = resolveIgnoreConfig(info) }
        function Input:OnChanged(fn) pushCallback(self.Callbacks, fn) return self end
        function Input:SetValue(v)
            textBox.Text = tostring(v)
            Input.Value = textBox.Text
            for _, fn in ipairs(Input.Callbacks) do spawnFn(fn, Input.Value) end
            spawnFn(info.Callback, Input.Value)
            return Input
        end
        if info.Numeric then
            Connect(textBox:GetPropertyChangedSignal("Text"), function()
                textBox.Text = textBox.Text:gsub("[^%d%.%-]", "")
            end)
        end
        local function commit()
            Input.Value = textBox.Text
            for _, fn in ipairs(Input.Callbacks) do spawnFn(fn, Input.Value) end
            spawnFn(info.Callback, Input.Value)
        end
        if info.Finished then
            Connect(textBox.FocusLost, function(enter) if enter then commit() end end)
        else
            Connect(textBox.FocusLost, commit)
            Connect(textBox:GetPropertyChangedSignal("Text"), function() Input.Value = textBox.Text end)
        end
        Library.Options[id] = Input
        registerSearch(row, info.Text or id, id)
        return Input
    end

    function Section:AddDropdown(id, info) return Library:_Dropdown(container, id, info, ctx) end

    function Section:AddKeyPicker(id, info)
        info = info or {}
        local row = makeRow(container, 19)
        local l = New("TextLabel", {
            Parent = row, BackgroundTransparency = 1, Size = UDim2.new(1, -90, 1, 0),
            Font = Library.Font, Text = info.Text or id, TextSize = 14,
            TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        })
        Library:AddToRegistry(l, "TextColor3", "Text")
        local holder = makeAddonHolder(row)
        registerSearch(row, info.Text or id, id)
        return Library:_KeyPicker(holder, id, info)
    end

    function Section:AddColorPicker(id, info)
        info = info or {}
        local row = makeRow(container, 19)
        local l = New("TextLabel", {
            Parent = row, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 1, 0),
            Font = Library.Font, Text = info.Title or info.Text or id, TextSize = 14,
            TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        })
        Library:AddToRegistry(l, "TextColor3", "Text")
        local holder = makeAddonHolder(row)
        registerSearch(row, info.Title or info.Text or id, id)
        return Library:_ColorPicker(holder, id, info)
    end

    function Section:AddDependencyBox()
        local order = (container:GetAttribute("VoidRowOrder") or 0) + 1
        container:SetAttribute("VoidRowOrder", order)

        local box = New("Frame", {
            Parent = container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, ClipsDescendants = true, Visible = false,
            LayoutOrder = order,
        })
        New("UIListLayout", { Parent = box, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
        box:SetAttribute("VoidRowOrder", 0)
        local inner = Library:_BuildSection(box, Section._searchCtx or ctx)
        inner._depBox = box
        inner._deps = {}
        function inner:SetupDependencies(list)
            self._deps = list or {}
            Library:_UpdateDependencies()
        end
        table.insert(Library.DependencyBoxes, inner)
        return inner
    end

    self._currentSectionCtx = prevCtx
    return Section
end

function Library:_UpdateDependencies()
    for _, box in ipairs(self.DependencyBoxes) do
        if box._depBox then
            local show = true
            for _, dep in ipairs(box._deps or {}) do
                local control, expected = dep[1], dep[2]
                if control and control.Value ~= nil then
                    if type(control.Value) == "table" then
                        if not control.Value[expected] then show = false end
                    else
                        if control.Value ~= expected then show = false end
                    end
                end
            end
            box._depBox.Visible = show
        end
    end
end

function Library:_Dropdown(container, id, info, ctx)
    info = info or {}
    local multi    = info.Multi or false
    local values   = info.Values or {}
    local hasLabel = info.Text ~= nil
    local row = makeRow(container, hasLabel and 44 or 28)
    if hasLabel then
        local l = New("TextLabel", {
            Parent = row, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
            Font = Library.Font, Text = info.Text, TextSize = 14,
            TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        })
        Library:AddToRegistry(l, "TextColor3", "Text")
    end
    local boxBtn = New("TextButton", {
        Parent = row, Position = UDim2.new(0, 0, 0, hasLabel and 22 or 0),
        Size = UDim2.new(1, 0, 0, hasLabel and 22 or 28),
        BackgroundColor3 = Library.Theme.Inline, AutoButtonColor = false, Text = "",
    })
    Library:AddToRegistry(boxBtn, "BackgroundColor3", "Inline")
    Corner(5, boxBtn)
    Library:AddToRegistry(Stroke(boxBtn, Library.Theme.Border, 1, 0), "Color", "Border")
    Padding(boxBtn, nil, 8, 8, 0, 0)
    local display = New("TextLabel", {
        Parent = boxBtn, BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, 0),
        Font = Library.Font, Text = "...", TextSize = 14, TextColor3 = Library.Theme.LightText,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    })
    Library:AddToRegistry(display, "TextColor3", "LightText")
    New("ImageLabel", {
        Parent = boxBtn, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(12, 12),
        Image = "rbxassetid://6031091004", ImageColor3 = Library.Theme.DarkText,
    })
    local popup = New("Frame", {
        Parent = Library.ScreenGui, BackgroundColor3 = Library.Theme.SectionBackground,
        BorderSizePixel = 0, Visible = false, ZIndex = 50, Size = UDim2.fromOffset(120, 0),
    })
    Library:AddToRegistry(popup, "BackgroundColor3", "SectionBackground")
    Corner(5, popup)
    Library:AddToRegistry(Stroke(popup, Library.Theme.Border, 1, 0), "Color", "Border")
    local scroller = New("ScrollingFrame", {
        Parent = popup, BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2, ZIndex = 51,
    })
    New("UIListLayout", { Parent = scroller, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })
    local Dropdown = { Value = multi and {} or nil, Values = values, Callbacks = {}, Type = "Dropdown", Id = id, IgnoreConfig = resolveIgnoreConfig(info) }
    if info.Default ~= nil then
        Dropdown.Value = resolveDropdownDefault(values, info.Default, multi)
    end
    if not multi and type(Dropdown.Value) ~= "string" and type(Dropdown.Value) ~= "number" then
        Dropdown.Value = nil
    end
    function Dropdown:OnChanged(fn) pushCallback(self.Callbacks, fn) return self end
    local function refreshDisplay()
        if multi then
            if type(Dropdown.Value) ~= "table" then Dropdown.Value = {} end
            local parts = {}
            for v, on in pairs(Dropdown.Value) do if on then table.insert(parts, v) end end
            table.sort(parts)
            display.Text = #parts > 0 and table.concat(parts, ", ") or "none"
        else
            display.Text = formatDisplayValue(Dropdown.Value)
        end
    end
    local function fire()
        for _, fn in ipairs(Dropdown.Callbacks) do spawnFn(fn, Dropdown.Value) end
        spawnFn(info.Callback, Dropdown.Value)
        Library:_UpdateDependencies()
    end
    local optionButtons = {}
    local function rebuild()
        for _, b in ipairs(optionButtons) do b:Destroy() end
        table.clear(optionButtons)
        for i, v in ipairs(Dropdown.Values) do
            local function selected()
                if multi then
                    return type(Dropdown.Value) == "table" and Dropdown.Value[v] == true
                else
                    return Dropdown.Value == v
                end
            end
            local opt = New("TextButton", {
                Parent = scroller, BackgroundColor3 = Library.Theme.Accent,
                BackgroundTransparency = selected() and 0 or 1, AutoButtonColor = false,
                Size = UDim2.new(1, 0, 0, 24), Font = Library.Font, Text = "  " .. tostring(v),
                TextSize = 14, TextColor3 = selected() and Color3.fromRGB(255, 255, 255) or Library.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 52, LayoutOrder = i,
            })
            Corner(4, opt)
            Connect(opt.MouseButton1Click, function()
                if multi then
                    if type(Dropdown.Value) ~= "table" then Dropdown.Value = {} end
                    if Dropdown.Value[v] then Dropdown.Value[v] = nil else Dropdown.Value[v] = true end
                else
                    Dropdown.Value = v
                    Library:ClosePopup(popup)
                end
                rebuild()
                refreshDisplay()
                fire()
            end)
            Connect(opt.MouseEnter, function()
                if not selected() then opt.BackgroundColor3 = Library.Theme.Inline; opt.BackgroundTransparency = 0 end
            end)
            Connect(opt.MouseLeave, function()
                if not selected() then opt.BackgroundTransparency = 1 end
            end)
            table.insert(optionButtons, opt)
        end
    end
    function Dropdown:SetValues(newValues) self.Values = newValues or {}; rebuild(); refreshDisplay(); return self end
    function Dropdown:SetValue(v)
        if multi then
            if type(v) ~= "table" then v = {} end
            self.Value = v
        else
            if type(v) == "function" or type(v) == "userdata" or type(v) == "thread" or type(v) == "table" then
                v = nil
            end
            self.Value = v
        end
        rebuild()
        refreshDisplay()
        fire()
        return self
    end
    local function posFn()
        local count = math.min(#Dropdown.Values, 7)
        local h = math.max(count * 26 + 8, 30)
        popup.Size = UDim2.fromOffset(boxBtn.AbsoluteSize.X, h)
        popup.Position = UDim2.fromOffset(boxBtn.AbsolutePosition.X, boxBtn.AbsolutePosition.Y + boxBtn.AbsoluteSize.Y + 4)
    end
    Connect(boxBtn.MouseButton1Click, function()
        if popup.Visible then Library:ClosePopup(popup) else Library:OpenPopup(popup, boxBtn, posFn) end
    end)
    rebuild()
    refreshDisplay()
    Library.Options[id] = Dropdown
    Library:_RegisterSearchFromRow(row, (hasLabel and info.Text) or id, id, ctx)
    return Dropdown
end

local digitNames = { ["0"] = "Zero", ["1"] = "One", ["2"] = "Two", ["3"] = "Three", ["4"] = "Four",
    ["5"] = "Five", ["6"] = "Six", ["7"] = "Seven", ["8"] = "Eight", ["9"] = "Nine" }
local function charToKeyCode(text)
    if not text or text == "" then return nil end
    local c = text:sub(1, 1)
    if c == " " then return "Space" end
    local upper = c:upper()
    if upper:match("%a") then return upper end
    if c:match("%d") then return digitNames[c] end
    return nil
end

function Library:_KeyPicker(holder, id, info)
    info = info or {}
    local current = normalizeKeybind(info.Default)
    local btn = New("TextButton", {
        Parent = holder, LayoutOrder = nextAddonOrder(holder), BackgroundColor3 = Library.Theme.Inline,
        AutoButtonColor = false, Font = Library.Font,
        Text = current and string.lower(tostring(current)) or "none", TextSize = 13,
        TextColor3 = Library.Theme.DarkText, Size = UDim2.fromOffset(0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
    })
    Library:AddToRegistry(btn, "BackgroundColor3", "Inline")
    Corner(4, btn)
    Library:AddToRegistry(Stroke(btn, Library.Theme.Border, 1, 0), "Color", "Border")
    Padding(btn, nil, 6, 6, 0, 0)
    local KeyPicker = {
        Value = current, Mode = info.Mode or "Toggle", State = false,
        Callbacks = {}, Type = "KeyPicker", Id = id, Text = info.Text or id,
        IgnoreConfig = resolveIgnoreConfig(info),
    }
    function KeyPicker:OnChanged(fn) pushCallback(self.Callbacks, fn) return self end
    function KeyPicker:OnClick(fn) self._click = type(fn) == "function" and fn or nil return self end
    function KeyPicker:GetState() return self.State end
    function KeyPicker:SetMode(mode)
        if mode == "Always" or mode == "Toggle" or mode == "Hold" then
            self.Mode = mode
            Library:_UpdateKeybindList()
        end
        return self
    end
    function KeyPicker:SetValue(key)
        key = normalizeKeybind(key)
        self.Value = key
        btn.Text = key and string.lower(key) or "none"
        if self._onRebind then spawnFn(self._onRebind, key) end
        Library:_UpdateKeybindList()
        return self
    end
    local modePopup
    local function buildModePopup()
        modePopup = New("Frame", {
            Parent = Library.ScreenGui, Visible = false, BackgroundColor3 = Library.Theme.SectionBackground,
            BorderSizePixel = 0, ZIndex = 70, Size = UDim2.fromOffset(90, 0), AutomaticSize = Enum.AutomaticSize.Y,
        })
        Library:AddToRegistry(modePopup, "BackgroundColor3", "SectionBackground")
        Corner(5, modePopup)
        Library:AddToRegistry(Stroke(modePopup, Library.Theme.Border, 1, 0), "Color", "Border")
        Padding(modePopup, 4)
        New("UIListLayout", { Parent = modePopup, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })
        for i, m in ipairs({ { "always", "Always" }, { "toggle", "Toggle" }, { "hold", "Hold" } }) do
            local opt = New("TextButton", {
                Parent = modePopup, BackgroundColor3 = Library.Theme.Accent, BackgroundTransparency = 1,
                AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 22), Font = Library.Font,
                Text = "  " .. m[1], TextSize = 13, TextColor3 = Library.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 71, LayoutOrder = i,
            })
            Corner(4, opt)
            Connect(opt.MouseButton1Click, function()
                KeyPicker.Mode = m[2]
                Library:ClosePopup(modePopup)
                Library:_UpdateKeybindList()
            end)
            Connect(opt.MouseEnter, function()
                if KeyPicker.Mode ~= m[2] then opt.BackgroundColor3 = Library.Theme.Inline; opt.BackgroundTransparency = 0 end
            end)
            Connect(opt.MouseLeave, function()
                if KeyPicker.Mode ~= m[2] then opt.BackgroundTransparency = 1 end
            end)
        end
    end
    local function modePosFn()
        modePopup.Position = UDim2.fromOffset(btn.AbsolutePosition.X, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + 4)
    end
    Connect(btn.MouseButton2Click, function()
        if not modePopup then buildModePopup() end
        if modePopup.Visible then Library:ClosePopup(modePopup) else Library:OpenPopup(modePopup, btn, modePosFn) end
    end)

    local captureBox = New("TextBox", {
        Parent = btn, BackgroundTransparency = 1, Text = "", TextTransparency = 1,
        PlaceholderText = "", Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0, 0),
        ClearTextOnFocus = true, Visible = false, TextEditable = true, ZIndex = 5,
    })
    local listening = false
    local function finishCapture(key)
        key = normalizeKeybind(key)
        if key == "Backspace" or key == "Escape" then key = nil end
        KeyPicker.Value = key
        btn.Text = key and string.lower(key) or "none"
        btn.TextColor3 = Library.Theme.DarkText
        listening = false
        Library._capturing = false
        KeyPicker._boundAt = tick()
        captureBox.Visible = false
        pcall(function() captureBox:ReleaseFocus() end)
        if KeyPicker._onRebind then spawnFn(KeyPicker._onRebind, key) end
        Library:_UpdateKeybindList()
    end
    local function startListening()
        listening = true
        Library._capturing = true
        btn.Text = "..."
        btn.TextColor3 = Library.Theme.Accent
        if Library.IsMobile then
            captureBox.Text = ""
            captureBox.Visible = true
            task.defer(function() pcall(function() captureBox:CaptureFocus() end) end)
        end
    end
    Connect(btn.MouseButton1Click, startListening)
    Connect(captureBox:GetPropertyChangedSignal("Text"), function()
        if not listening then return end
        if captureBox.Text == "" then return end
        local key = charToKeyCode(captureBox.Text)
        if key then finishCapture(key) end
    end)
    Connect(captureBox.FocusLost, function()
        if not listening then return end
        captureBox.Visible = false
        listening = false
        Library._capturing = false
        btn.Text = KeyPicker.Value and string.lower(tostring(KeyPicker.Value)) or "none"
        btn.TextColor3 = Library.Theme.DarkText
        Library:_UpdateKeybindList()
    end)
    Connect(UserInputService.InputBegan, function(input, gpe)
        if listening then
            local key
            if input.UserInputType == Enum.UserInputType.Keyboard then key = input.KeyCode.Name
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then key = "MB1"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then key = "MB2" end
            if key then finishCapture(key) end
            return
        end
        if gpe then return end
        if KeyPicker._boundAt and tick() - KeyPicker._boundAt < 0.2 then return end
        local match = false
        if KeyPicker.Value then
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == KeyPicker.Value then match = true end
            if input.UserInputType == Enum.UserInputType.MouseButton1 and KeyPicker.Value == "MB1" then match = true end
            if input.UserInputType == Enum.UserInputType.MouseButton2 and KeyPicker.Value == "MB2" then match = true end
        end
        if match then
            if KeyPicker.Mode == "Toggle" then KeyPicker.State = not KeyPicker.State
            elseif KeyPicker.Mode == "Hold" then KeyPicker.State = true
            elseif KeyPicker.Mode == "Always" then KeyPicker.State = true end
            if info._toggle and info.SyncToggleState then info._toggle:SetValue(KeyPicker.State) end
            for _, fn in ipairs(KeyPicker.Callbacks) do spawnFn(fn, KeyPicker.State) end
            spawnFn(KeyPicker._click)
            spawnFn(info.Callback, KeyPicker.State)
            Library:_UpdateKeybindList()
        end
    end)
    Connect(UserInputService.InputEnded, function(input)
        if KeyPicker.Mode == "Hold" and KeyPicker.Value then
            local match = (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == KeyPicker.Value)
                or (input.UserInputType == Enum.UserInputType.MouseButton1 and KeyPicker.Value == "MB1")
                or (input.UserInputType == Enum.UserInputType.MouseButton2 and KeyPicker.Value == "MB2")
            if match then
                KeyPicker.State = false
                if info._toggle and info.SyncToggleState then info._toggle:SetValue(false) end
                for _, fn in ipairs(KeyPicker.Callbacks) do spawnFn(fn, false) end
                Library:_UpdateKeybindList()
            end
        end
    end)
    if info.NoUI then btn.Visible = false end
    KeyPicker._showInList = (not info.NoUI) and (not info.NoList)
    table.insert(Library.KeybindEntries, KeyPicker)
    Library.Options[id] = KeyPicker
    Library:_UpdateKeybindList()
    return KeyPicker
end

function Library:_ColorPicker(holder, id, info)
    info = info or {}
    local color = info.Default or Color3.fromRGB(255, 255, 255)
    local transparency = info.Transparency or 0
    local swatch = New("TextButton", {
        Parent = holder, LayoutOrder = nextAddonOrder(holder), BackgroundColor3 = color,
        AutoButtonColor = false, Text = "", Size = UDim2.fromOffset(16, 16),
    })
    Corner(8, swatch)
    Library:AddToRegistry(Stroke(swatch, Library.Theme.Border, 1, 0), "Color", "Border")
    local ColorPicker = { Value = color, Transparency = transparency, Callbacks = {}, Type = "ColorPicker", Id = id, IgnoreConfig = resolveIgnoreConfig(info) }
    function ColorPicker:OnChanged(fn) pushCallback(self.Callbacks, fn) return self end
    local h, s, v = Color3.toHSV(color)
    local popup = New("Frame", {
        Parent = Library.ScreenGui, Visible = false, BackgroundColor3 = Library.Theme.SectionBackground,
        BorderSizePixel = 0, Size = UDim2.fromOffset(200, info.Transparency ~= nil and 224 or 206), ZIndex = 60,
    })
    Library:AddToRegistry(popup, "BackgroundColor3", "SectionBackground")
    Corner(5, popup)
    Library:AddToRegistry(Stroke(popup, Library.Theme.Border, 1, 0), "Color", "Border")
    Padding(popup, 10)
    local svBox = New("ImageButton", {
        Parent = popup, Size = UDim2.new(1, 0, 0, 120), BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        AutoButtonColor = false, ZIndex = 61,
    })
    Corner(4, svBox)
    local whiteGrad = New("Frame", { Parent = svBox, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = 61 })
    Corner(4, whiteGrad)
    New("UIGradient", { Parent = whiteGrad, Color = ColorSequence.new(Color3.new(1,1,1)),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) })
    local blackGrad = New("Frame", { Parent = svBox, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0,0,0), BorderSizePixel = 0, ZIndex = 62 })
    Corner(4, blackGrad)
    New("UIGradient", { Parent = blackGrad, Rotation = 90, Color = ColorSequence.new(Color3.new(0,0,0)),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) })
    local svCursor = New("Frame", { Parent = svBox, Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = 63 })
    Corner(4, svCursor)
    Stroke(svCursor, Color3.new(0,0,0), 1, 0)
    local hueBar = New("ImageButton", { Parent = popup, Position = UDim2.new(0, 0, 0, 130), Size = UDim2.new(1, 0, 0, 14),
        AutoButtonColor = false, BackgroundColor3 = Color3.new(1,1,1), ZIndex = 61 })
    Corner(4, hueBar)
    New("UIGradient", { Parent = hueBar, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0)),
    }) })
    local hueCursor = New("Frame", { Parent = hueBar, Size = UDim2.new(0, 3, 1, 2), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = 62 })
    Stroke(hueCursor, Color3.new(0,0,0), 1, 0)
    local alphaBar, alphaCursor, alphaGrad
    if info.Transparency ~= nil then
        alphaBar = New("ImageButton", { Parent = popup, Position = UDim2.new(0, 0, 0, 150), Size = UDim2.new(1, 0, 0, 14),
            AutoButtonColor = false, BackgroundColor3 = Color3.new(1,1,1), ZIndex = 61 })
        Corner(4, alphaBar)
        alphaGrad = New("UIGradient", { Parent = alphaBar, Color = ColorSequence.new(color),
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) })
        alphaCursor = New("Frame", { Parent = alphaBar, Size = UDim2.new(0, 3, 1, 2), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(1 - transparency, 0.5), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = 62 })
        Stroke(alphaCursor, Color3.new(0,0,0), 1, 0)
    end
    local hexBox = New("TextBox", { Parent = popup, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = Library.Theme.Inline, BorderSizePixel = 0,
        Font = Library.Font, TextSize = 14, TextColor3 = Library.Theme.LightText, Text = "#ffffff",
        ClearTextOnFocus = false, ZIndex = 61 })
    Library:AddToRegistry(hexBox, "BackgroundColor3", "Inline")
    Corner(4, hexBox)
    Stroke(hexBox, Library.Theme.Border, 1, 0)
    local function fire()
        for _, fn in ipairs(ColorPicker.Callbacks) do spawnFn(fn, ColorPicker.Value, ColorPicker.Transparency) end
        spawnFn(info.Callback, ColorPicker.Value, ColorPicker.Transparency)
    end
    local function refresh(skipFire)
        local col = Color3.fromHSV(h, s, v)
        ColorPicker.Value = col
        swatch.BackgroundColor3 = col
        swatch.BackgroundTransparency = ColorPicker.Transparency
        svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.fromScale(s, 1 - v)
        hueCursor.Position = UDim2.fromScale(h, 0.5)
        hexBox.Text = "#" .. col:ToHex()
        if alphaBar then
            alphaGrad.Color = ColorSequence.new(col)
            alphaCursor.Position = UDim2.fromScale(1 - ColorPicker.Transparency, 0.5)
        end
        if not skipFire then fire() end
    end
    local function bindDrag(obj, fn)
        local down = false
        Connect(obj.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                down = true
                fn(input.Position)
            end
        end)
        Connect(UserInputService.InputChanged, function(input)
            if down and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then fn(input.Position) end
        end)
        Connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then down = false end
        end)
    end
    bindDrag(svBox, function(pos)
        s = math.clamp((pos.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
        v = 1 - math.clamp((pos.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
        refresh()
    end)
    bindDrag(hueBar, function(pos)
        h = math.clamp((pos.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
        refresh()
    end)
    if alphaBar then
        bindDrag(alphaBar, function(pos)
            ColorPicker.Transparency = 1 - math.clamp((pos.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
            refresh()
        end)
    end
    Connect(hexBox.FocusLost, function()
        local clean = hexBox.Text:gsub("#", "")
        local okHex, col = pcall(Color3.fromHex, clean)
        if okHex and col then h, s, v = Color3.toHSV(col); refresh() end
    end)
    function ColorPicker:SetValueRGB(col) h, s, v = Color3.toHSV(col); refresh(); return self end
    function ColorPicker:SetValue(value, trans)
        if typeof(value) == "Color3" then h, s, v = Color3.toHSV(value)
        elseif type(value) == "table" then h, s, v = value[1] or h, value[2] or s, value[3] or v end
        if trans ~= nil then ColorPicker.Transparency = trans end
        refresh()
        return self
    end
    local function posFn()
        local vp = workspace.CurrentCamera.ViewportSize
        popup.Position = UDim2.fromOffset(
            math.clamp(swatch.AbsolutePosition.X - 184, 4, vp.X - 210),
            math.clamp(swatch.AbsolutePosition.Y + 22, 4, vp.Y - popup.AbsoluteSize.Y - 4))
    end
    Connect(swatch.MouseButton1Click, function()
        if popup.Visible then Library:ClosePopup(popup) else Library:OpenPopup(popup, swatch, posFn) end
    end)
    refresh(true)
    Library.Options[id] = ColorPicker
    return ColorPicker
end

function Library:CreateKeybindList()
    if self.KeybindFrame then return self.KeybindFrame end
    local frame = New("Frame", {
        Parent = self.ScreenGui, Position = UDim2.fromOffset(20, 220),
        Size = UDim2.new(0, 200, 0, 30), BackgroundColor3 = self.Theme.SectionBackground,
        BorderSizePixel = 0, ZIndex = 140, AutomaticSize = Enum.AutomaticSize.Y,
    })
    self:AddToRegistry(frame, "BackgroundColor3", "SectionBackground")
    Corner(5, frame)
    self:AddToRegistry(Stroke(frame, self.Theme.Border, 1, 0), "Color", "Border")
    Padding(frame, 8)
    New("UIListLayout", { Parent = frame, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
    local title = New("TextLabel", {
        Parent = frame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = -1,
        Font = self.FontBold, Text = "keybinds", TextSize = 14, TextColor3 = self.Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 141,
    })
    self:AddToRegistry(title, "TextColor3", "Accent")
    makeDraggable(frame)
    self.KeybindFrame = frame
    self.KeybindListContent = frame
    self:_UpdateKeybindList()
    return frame
end

function Library:_UpdateKeybindList()
    local frame = self.KeybindFrame
    if typeof(frame) ~= "Instance" or not frame:IsA("GuiObject") then return end
    if not self.KeybindListVisible then frame.Visible = false return end
    for _, c in ipairs(frame:GetChildren()) do
        if c:IsA("TextLabel") and c.LayoutOrder >= 0 then c:Destroy() end
    end
    local shown = 0
    for i, kp in ipairs(self.KeybindEntries) do
        local keyName = normalizeKeybind(kp.Value)
        if kp._showInList and keyName then
            local include = false
            local mode = string.lower(self.KeybindListMode or "toggled")
            if mode == "all" then include = true
            elseif mode == "toggled" then include = (kp.Mode == "Toggle")
            elseif mode == "active" then include = kp.State end
            if include then
                shown += 1
                local row = New("TextLabel", {
                    Parent = frame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15),
                    LayoutOrder = i, Font = self.Font, TextSize = 13,
                    TextColor3 = kp.State and self.Theme.Accent or self.Theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 141,
                    Text = string.format("%s [%s]", kp.Text, string.lower(keyName)),
                })
            end
        end
    end
    frame.Visible = shown > 0
end

local function ensureFolders()
    if not hasFS() then return end
    pcall(function()
        if not fs.isfolder("void") then fs.makefolder("void") end
        if not fs.isfolder("void/configs") then fs.makefolder("void/configs") end
        if not fs.isfolder("void/themes") then fs.makefolder("void/themes") end
        if not fs.isfolder("void/fonts") then fs.makefolder("void/fonts") end
    end)
end

local function serializeValue(opt)
    if opt.Type == "ColorPicker" then
        return { __t = "color", hex = opt.Value:ToHex(), transparency = opt.Transparency }
    elseif opt.Type == "Dropdown" then
        if type(opt.Value) == "table" then
            local t = {}
            for k, on in pairs(opt.Value) do if on then table.insert(t, k) end end
            return { __t = "multidropdown", values = t }
        end
        return { __t = "dropdown", value = opt.Value }
    elseif opt.Type == "KeyPicker" then
        return { __t = "key", value = opt.Value, mode = opt.Mode }
    else
        return { __t = "value", value = opt.Value }
    end
end

function Library:GetConfigData()
    local data = { toggles = {}, options = {}, custom = {} }
    for id, t in pairs(self.Toggles) do
        if not t.IgnoreConfig then data.toggles[id] = t.Value end
    end
    for id, o in pairs(self.Options) do
        if not o.IgnoreConfig and o.Type ~= "Button" then data.options[id] = serializeValue(o) end
    end
    for name, provider in pairs(self._configProviders or {}) do
        if provider and type(provider.get) == "function" then
            local ok, value = pcall(provider.get)
            if ok and value ~= nil then
                data.custom[name] = value
            end
        end
    end
    return data
end

function Library:RegisterConfigProvider(name, getFn, applyFn)
    self._configProviders = self._configProviders or {}
    self._configProviders[name] = { get = getFn, apply = applyFn }
    return self
end

function Library:ApplyConfigData(data)
    if not data then return end
    self._applyingConfig = true
    local keyEntries = {}
    for id, ser in pairs(data.options or {}) do
        if ser.__t == "key" then
            keyEntries[id] = ser
        else
            local opt = self.Options[id]
            if opt and type(opt.SetValue) == "function" then
                pcall(function()
                    if ser.__t == "color" then
                        opt:SetValue(Color3.fromHex(ser.hex), ser.transparency)
                    elseif ser.__t == "multidropdown" then
                        local t = {}
                        for _, v in ipairs(ser.values) do t[v] = true end
                        opt:SetValue(t)
                    elseif ser.__t == "dropdown" then
                        opt:SetValue(ser.value)
                    else
                        opt:SetValue(ser.value)
                    end
                end)
            end
        end
    end
    for id, val in pairs(data.toggles or {}) do
        local toggle = self.Toggles[id]
        if toggle and type(toggle.SetValue) == "function" then
            pcall(function() toggle:SetValue(val == true) end)
        end
    end
    for id, ser in pairs(keyEntries) do
        local opt = self.Options[id]
        if opt and opt.Type == "KeyPicker" then
            pcall(function()
                if ser.mode then opt:SetMode(ser.mode) end
                opt:SetValue(ser.value)
                if opt._linkedToggle then
                    opt.State = opt._linkedToggle.Value == true
                end
            end)
        end
    end
    for name, customData in pairs(data.custom or {}) do
        local provider = self._configProviders and self._configProviders[name]
        if provider and type(provider.apply) == "function" then
            pcall(provider.apply, customData)
        end
    end
    self._applyingConfig = false
    self:_UpdateKeybindList()
end

function Library:SaveConfig(name)
    if not hasFS() then self:Notify("file system not supported") return false end
    if not name or name == "" then self:Notify("enter a config name") return false end
    ensureFolders()
    local data = self:GetConfigData()
    local ok = pcall(function()
        fs.writefile("void/configs/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
    if ok then self:Notify("saved config: " .. name) else self:Notify("failed to save config") end
    return ok
end

function Library:LoadConfig(name)
    if not hasFS() then self:Notify("file system not supported") return false end
    local path = "void/configs/" .. name .. ".json"
    if not fs.isfile(path) then self:Notify("config not found") return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(fs.readfile(path)) end)
    if ok and data then self:ApplyConfigData(data); self:Notify("loaded config: " .. name); return true end
    self:Notify("failed to load config")
    return false
end

function Library:DeleteConfig(name)
    if not hasFS() then return false end
    local path = "void/configs/" .. name .. ".json"
    if fs.isfile(path) then pcall(fs.delfile, path); self:Notify("deleted config: " .. name); return true end
    return false
end

function Library:GetConfigList()
    local list = {}
    if not hasFS() then return list end
    ensureFolders()
    local ok, files = pcall(fs.listfiles, "void/configs")
    if ok and files then
        for _, f in ipairs(files) do
            local name = f:match("([^/\\]+)%.json$")
            if name then table.insert(list, name) end
        end
    end
    return list
end

function Library:SetAutoload(name)
    if not hasFS() then return end
    ensureFolders()
    pcall(fs.writefile, "void/configs/autoload.txt", name)
end

function Library:GetAutoload()
    if not hasFS() then return nil end
    if fs.isfile("void/configs/autoload.txt") then
        local ok, n = pcall(fs.readfile, "void/configs/autoload.txt")
        if ok then return n end
    end
    return nil
end

function Library:SaveTheme(name)
    if not hasFS() then return false end
    ensureFolders()
    local data = { font = self.CurrentFontSpec, colors = {} }
    for k, c in pairs(self.Theme) do data.colors[k] = c:ToHex() end
    local ok = pcall(function() fs.writefile("void/themes/" .. name .. ".json", HttpService:JSONEncode(data)) end)
    if ok then self:Notify("saved theme: " .. name) end
    return ok
end

function Library:LoadTheme(name)
    if not hasFS() then return false end
    local path = "void/themes/" .. name .. ".json"
    if not fs.isfile(path) then return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(fs.readfile(path)) end)
    if ok and data then
        for k, hex in pairs(data.colors or {}) do
            pcall(function() self:SetTheme(k, Color3.fromHex(hex)) end)
        end
        if data.font then
            if data.font.custom then
                self:DownloadFont(data.font.custom, self.FontsToDownload[data.font.custom] and self.FontsToDownload[data.font.custom].Link)
                self:SetFont({ custom = data.font.custom })
            elseif data.font.enum then
                self:SetFont({ enum = data.font.enum })
            end
        end
        self:Notify("loaded theme: " .. name)
        return true
    end
    return false
end

function Library:GetThemeList()
    local list = {}
    if not hasFS() then return list end
    ensureFolders()
    local ok, files = pcall(fs.listfiles, "void/themes")
    if ok and files then
        for _, f in ipairs(files) do
            local name = f:match("([^/\\]+)%.json$")
            if name then table.insert(list, name) end
        end
    end
    return list
end

function Library:CopyJobId()
    if setClipboard then setClipboard(game.JobId); self:Notify("copied job id") else self:Notify("clipboard not supported") end
end

function Library:CopyGameId()
    if setClipboard then setClipboard(tostring(game.PlaceId)); self:Notify("copied place id") else self:Notify("clipboard not supported") end
end

function Library:CopyJoinScript()
    local script = string.format(
        "game:GetService(\"TeleportService\"):TeleportToPlaceInstance(%d, \"%s\")",
        game.PlaceId, game.JobId)
    if setClipboard then setClipboard(script); self:Notify("copied join script") else self:Notify("clipboard not supported") end
end

function Library:Rejoin()
    self:Notify("rejoining...")
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
end

function Library:ServerHop(minP, maxP)
    minP = minP or 1
    maxP = maxP or 100
    self:Notify("finding a server...")
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
    local body = httpGet(url)
    if not body then self:Notify("server list request failed") return end
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or not data then self:Notify("failed to parse server list") return end
    local candidates = {}
    for _, srv in ipairs(data.data or {}) do
        if srv.playing and srv.maxPlayers and srv.id ~= game.JobId
            and srv.playing < srv.maxPlayers and srv.playing >= minP and srv.playing <= maxP then
            table.insert(candidates, srv.id)
        end
    end
    if #candidates > 0 then
        local pick = candidates[math.random(1, #candidates)]
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, pick, LocalPlayer) end)
    else
        self:Notify("no matching servers found")
    end
end

function Library:BuildSettingsTab(tab)
    self._ignoreConfig = true
    local cfgBox = tab:AddLeftGroupbox("configs", "save / load / delete")
    local nameInput = cfgBox:AddInput("config_name", { Default = "", Placeholder = "config name" })
    local listDropdown = cfgBox:AddDropdown("config_list", {
        Text = "configs", Values = self:GetConfigList(), Default = 1,
    })
    if #self:GetConfigList() == 0 then
        listDropdown:SetValues({ "no configs" })
        listDropdown:SetValue("no configs")
    end
    local function refreshList()
        local list = self:GetConfigList()
        if #list == 0 then list = { "no configs" } end
        listDropdown:SetValues(list)
    end
    cfgBox:AddButton({ Text = "save", Func = function()
        if nameInput.Value ~= "" then self:SaveConfig(nameInput.Value); refreshList() end
    end })
    cfgBox:AddButton({ Text = "load", Func = function()
        local n = listDropdown.Value
        if n and n ~= "no configs" then self:LoadConfig(n) end
    end })
    cfgBox:AddButton({ Text = "overwrite", Func = function()
        local n = listDropdown.Value
        if n and n ~= "no configs" then self:SaveConfig(n) end
    end })
    cfgBox:AddButton({ Text = "delete", Func = function()
        local n = listDropdown.Value
        if n and n ~= "no configs" then self:DeleteConfig(n); refreshList() end
    end })
    cfgBox:AddButton({ Text = "refresh list", Func = refreshList })
    cfgBox:AddButton({ Text = "set as autoload", Func = function()
        local n = listDropdown.Value
        if n and n ~= "no configs" then self:SetAutoload(n); self:Notify("autoload set: " .. n) end
    end })
    cfgBox:AddLabel("current autoload: " .. (self:GetAutoload() or "none"))

    self._ignoreConfig = false
    local themeBox = tab:AddRightGroupbox("theme", "customize colors")
    local wm = themeBox:AddToggle("watermark", { Text = "watermark", Default = false, Callback = function(v)
        self:SetWatermarkVisible(v)
    end })
    local menuKp = themeBox:AddLabel("menu toggle"):AddKeyPicker("menu_keybind", {
        Default = "RightShift", Mode = "Toggle", Text = "menu toggle", NoList = true,
    })
    menuKp._onRebind = function(key)
        if key then pcall(function() self:SetMenuKeybind(Enum.KeyCode[key]) end) else self.MenuKeybind = nil end
    end
    if menuKp.Value then
        pcall(function() self:SetMenuKeybind(Enum.KeyCode[menuKp.Value]) end)
    end

    local fontMap = {}
    local fontValues = {}
    for _, pair in ipairs(self.Fonts) do
        local ln = string.lower(pair[1])
        fontMap[ln] = { enum = pair[2] }
        table.insert(fontValues, ln)
    end
    for name in pairs(self.FontsToDownload) do
        local ln = string.lower(name)
        fontMap[ln] = { custom = name }
        table.insert(fontValues, ln)
    end
    table.sort(fontValues)
    themeBox:AddDropdown("ui_font", {
        Text = "ui font", Values = fontValues, Default = "gotham",
        Callback = function(ln)
            local m = fontMap[string.lower(ln)]
            if not m then return end
            if m.enum then
                self:SetFont({ enum = m.enum })
            elseif m.custom then
                self:Notify("downloading font: " .. m.custom)
                task.spawn(function()
                    local asset = self:DownloadFont(m.custom, self.FontsToDownload[m.custom].Link)
                    if asset then self:SetFont({ custom = m.custom }); self:Notify("applied font: " .. m.custom)
                    else self:Notify("failed to load font: " .. m.custom) end
                end)
            end
        end,
    })

    self._ignoreConfig = true
    self.SyncTheme = {}
    local themeOrder = {
        { "dark background", "DarkBackground" },
        { "page background", "PageBackground" },
        { "section background", "SectionBackground" },
        { "inline", "Inline" },
        { "border", "Border" },
        { "text", "Text" },
        { "dark text", "DarkText" },
        { "light text", "LightText" },
        { "title color", "TitleColor" },
        { "accent", "Accent" },
    }
    for _, pair in ipairs(themeOrder) do
        local label, key = pair[1], pair[2]
        local cp = themeBox:AddColorPicker("themecol_" .. key, {
            Title = label, Default = self.Theme[key], IgnoreConfig = true,
            Callback = function(col) self:SetTheme(key, col) end,
        })
        self.SyncTheme[key] = cp
    end

    local themeNameInput = themeBox:AddInput("theme_name", { Default = "", Placeholder = "theme name" })
    local themeDropdown = themeBox:AddDropdown("theme_list", { Text = "themes", Values = self:GetThemeList(), Default = 1 })
    if #self:GetThemeList() == 0 then
        themeDropdown:SetValues({ "no themes" })
        themeDropdown:SetValue("no themes")
    end
    themeBox:AddButton({ Text = "save theme", Func = function()
        if themeNameInput.Value ~= "" then self:SaveTheme(themeNameInput.Value); themeDropdown:SetValues(self:GetThemeList()) end
    end }):AddButton({ Text = "load theme", Func = function()
        local n = themeDropdown.Value
        if n and n ~= "no themes" then self:LoadTheme(n) end
    end })

    self._ignoreConfig = true
    local panel = tab:AddRightGroupbox("game panel", "usefull utilities")
    panel:AddButton({ Text = "copy jobid", Func = function() self:CopyJobId() end })
    panel:AddButton({ Text = "copy gameid", Func = function() self:CopyGameId() end })
    panel:AddButton({ Text = "copy join script", Func = function() self:CopyJoinScript() end })
    panel:AddButton({ Text = "rejoin", Func = function() self:Rejoin() end })
    local minSlider = panel:AddSlider("min_players", { Text = "min players", Min = 1, Max = 50, Default = 1 })
    local maxSlider = panel:AddSlider("max_players", { Text = "max players", Min = 1, Max = 50, Default = 30 })
    panel:AddButton({ Text = "join new server", Func = function()
        self:ServerHop(minSlider.Value, maxSlider.Value)
    end })

    self._ignoreConfig = false
    local uiBox = tab:AddLeftGroupbox("ui settings", "interface")
    self:CreateKeybindList()
    uiBox:AddToggle("keybind_list", { Text = "show keybind list", Default = true, Callback = function(v)
        self.KeybindListVisible = v
        self:_UpdateKeybindList()
    end })
    uiBox:AddDropdown("keybind_mode", {
        Text = "keybind list mode", Values = { "all", "toggled", "active" }, Default = "toggled",
        Callback = function(v) self.KeybindListMode = v; self:_UpdateKeybindList() end,
    })
    uiBox:AddSlider("ui_scale", { Text = "ui scale", Min = 50, Max = 130, Default = self.IsMobile and 60 or 100, Suffix = "%", Callback = function(v)
        if self.UIScale then self.UIScale.Scale = v / 100 end
    end })
    self._ignoreConfig = true
    uiBox:AddButton({ Text = "unload", Func = function() self:Unload() end })

    self._ignoreConfig = false
    return tab
end

function Library:LoadAutoload()
    local name = self:GetAutoload()
    if name and name ~= "" then
        task.spawn(function() self:LoadConfig(name) end)
    end
end

function Library:_BuildSkinChangerPage(page, cfg)
    local root = New("Frame", {
        Name = "SkinChangerRoot",
        Parent = page,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 2,
    })

    local body = New("Frame", {
        Name = "Body",
        Parent = root,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 2,
    })

    local mainBody = New("Frame", {
        Name = "MainBody",
        Parent = body,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
    })

    local function attachPreviewInput(holder, onZoom, onDrag)
        local catcher = New("TextButton", {
            Parent = holder,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            Size = UDim2.fromScale(1, 1),
            ZIndex = 10,
        })

        local dragging = false
        local lastPos = nil

        Connect(catcher.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                lastPos = input.Position
            end
        end)

        Connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                lastPos = nil
            end
        end)

        Connect(catcher.InputChanged, function(input)
            if input.UserInputType == Enum.UserInputType.MouseWheel then
                onZoom(input.Position.Z)
                return
            end
            if not dragging or not onDrag then
                return
            end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            if lastPos then
                local delta = input.Position - lastPos
                onDrag(delta.X, delta.Y)
            end
            lastPos = input.Position
        end)
    end

    local function makePreviewBlock(parent, defaultAutoRotate)
        local viewportHolder = New("Frame", {
            Parent = parent,
            BackgroundColor3 = self.Theme.Inline,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, -96),
        })
        Corner(4, viewportHolder)
        self:AddToRegistry(viewportHolder, "BackgroundColor3", "Inline")

        local viewport = New("ViewportFrame", {
            Parent = viewportHolder,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Ambient = Color3.fromRGB(180, 180, 190),
            LightColor = Color3.fromRGB(255, 255, 255),
            LightDirection = Vector3.new(-1, -1, -1),
        })

        local worldModel = New("WorldModel", { Parent = viewport })

        local previewControls = New("Frame", {
            Parent = parent,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 1, -88),
            Size = UDim2.new(1, 0, 0, 88),
        })
        New("UIListLayout", {
            Parent = previewControls,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
        })

        return viewportHolder, viewport, worldModel, previewControls
    end

    local function makePanel(parent, title, widthScale, xOffset)
        local panel = New("Frame", {
            Parent = parent,
            BackgroundColor3 = self.Theme.SectionBackground,
            BorderSizePixel = 0,
            Position = UDim2.new(widthScale and 0 or 0, xOffset or 0, 0, 0),
            Size = widthScale and UDim2.new(widthScale, -6, 1, 0) or UDim2.new(1, 0, 1, 0),
        })
        self:AddToRegistry(panel, "BackgroundColor3", "SectionBackground")
        Corner(5, panel)
        self:AddToRegistry(Stroke(panel, self.Theme.Border, 1, 0), "Color", "Border")
        Padding(panel, 10)

        local header = New("TextLabel", {
            Parent = panel,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Font = self.FontBold,
            Text = title,
            TextSize = 13,
            TextColor3 = self.Theme.LightText,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        self:AddToRegistry(header, "TextColor3", "LightText")

        local content = New("Frame", {
            Name = "Content",
            Parent = panel,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 22),
            Size = UDim2.new(1, 0, 1, -22),
        })

        return panel, content
    end

    local generalPanel, generalContent = makePanel(mainBody, "general", 0.28, 0)
    local modPanel, modContent = makePanel(mainBody, "weapon modification", 0.28, 0)
    modPanel.Position = UDim2.new(0.28, 4, 0, 0)
    local previewPanel, previewContent = makePanel(mainBody, "preview", 0.44, 0)
    previewPanel.Position = UDim2.new(0.56, 4, 0, 0)

    local enableRow = New("Frame", {
        Parent = generalContent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
    })
    local enableBox = New("TextButton", {
        Parent = enableRow,
        BackgroundColor3 = self.Theme.Inline,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.fromOffset(0, 3),
    })
    Corner(3, enableBox)
    self:AddToRegistry(Stroke(enableBox, self.Theme.Border, 1, 0), "Color", "Border")
    local enableMark = New("Frame", {
        Parent = enableBox,
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(8, 8),
        Position = UDim2.fromOffset(3, 3),
        Visible = cfg.DefaultEnabled or false,
    })
    Corner(2, enableMark)
    New("TextLabel", {
        Parent = enableRow,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(22, 0),
        Size = UDim2.new(1, -22, 1, 0),
        Font = self.Font,
        Text = "enable",
        TextSize = 13,
        TextColor3 = self.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local function makeSearchList(parent, labelText, yPos, height)
        local holder = New("Frame", {
            Parent = parent,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, yPos),
            Size = UDim2.new(1, 0, 0, height),
        })

        New("TextLabel", {
            Parent = holder,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            Font = self.Font,
            Text = labelText,
            TextSize = 12,
            TextColor3 = self.Theme.DarkText,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        local searchRow = New("Frame", {
            Parent = holder,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 18),
            Size = UDim2.new(1, 0, 0, 24),
        })

        local searchBox = New("TextBox", {
            Parent = searchRow,
            BackgroundColor3 = self.Theme.Inline,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -88, 1, 0),
            Font = self.Font,
            Text = "",
            PlaceholderText = "search...",
            TextSize = 12,
            TextColor3 = self.Theme.LightText,
            PlaceholderColor3 = self.Theme.DarkText,
            ClearTextOnFocus = false,
        })
        Corner(4, searchBox)
        self:AddToRegistry(searchBox, "BackgroundColor3", "Inline")

        local searchBtn = New("TextButton", {
            Parent = searchRow,
            BackgroundColor3 = self.Theme.Inline,
            AutoButtonColor = false,
            Position = UDim2.new(1, -82, 0, 0),
            Size = UDim2.fromOffset(38, 24),
            Font = self.Font,
            Text = "search",
            TextSize = 11,
            TextColor3 = self.Theme.Text,
        })
        Corner(4, searchBtn)
        self:AddToRegistry(searchBtn, "BackgroundColor3", "Inline")

        local clearBtn = New("TextButton", {
            Parent = searchRow,
            BackgroundColor3 = self.Theme.Inline,
            AutoButtonColor = false,
            Position = UDim2.new(1, -40, 0, 0),
            Size = UDim2.fromOffset(40, 24),
            Font = self.Font,
            Text = "clear",
            TextSize = 11,
            TextColor3 = self.Theme.Text,
        })
        Corner(4, clearBtn)
        self:AddToRegistry(clearBtn, "BackgroundColor3", "Inline")

        local list = New("ScrollingFrame", {
            Parent = holder,
            BackgroundColor3 = self.Theme.Inline,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, 46),
            Size = UDim2.new(1, 0, 1, -46),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = self.Theme.Accent,
            Active = true,
            ZIndex = 3,
        })
        Corner(4, list)
        self:AddToRegistry(list, "BackgroundColor3", "Inline")
        New("UIListLayout", {
            Parent = list,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2),
        })
        Padding(list, 4)

        return holder, searchBox, searchBtn, clearBtn, list
    end

    local generalListHolder, weaponSearch, weaponSearchBtn, weaponClearBtn, weaponList =
        makeSearchList(generalContent, "weapon", 26, 9999)
    generalListHolder.Size = UDim2.new(1, 0, 1, -26)
    generalListHolder.Position = UDim2.fromOffset(0, 26)
    generalListHolder.AnchorPoint = Vector2.new(0, 0)
    generalListHolder.AutomaticSize = Enum.AutomaticSize.None

    local skinListHolder, skinSearch, skinSearchBtn, skinClearBtn, skinList =
        makeSearchList(modContent, "skin select", 0, 9999)
    skinListHolder.Size = UDim2.new(1, 0, 1, 0)
    skinListHolder.Position = UDim2.fromOffset(0, 0)

    local viewportHolder, viewport, worldModel, previewControls =
        makePreviewBlock(previewContent, cfg.DefaultAutoRotate)

    local autoRotateRow = New("Frame", {
        Parent = previewControls,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        LayoutOrder = 1,
    })
    local autoRotateBox = New("TextButton", {
        Parent = autoRotateRow,
        BackgroundColor3 = self.Theme.Inline,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.fromOffset(0, 3),
    })
    Corner(3, autoRotateBox)
    local autoRotateMark = New("Frame", {
        Parent = autoRotateBox,
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(8, 8),
        Position = UDim2.fromOffset(3, 3),
        Visible = cfg.DefaultAutoRotate ~= false,
    })
    Corner(2, autoRotateMark)
    New("TextLabel", {
        Parent = autoRotateRow,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(22, 0),
        Size = UDim2.new(1, -22, 1, 0),
        Font = self.Font,
        Text = "auto rotate",
        TextSize = 12,
        TextColor3 = self.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local rotSliderBg = New("Frame", {
        Parent = previewControls,
        BackgroundColor3 = self.Theme.Inline,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 28),
        LayoutOrder = 2,
    })
    Corner(4, rotSliderBg)
    New("TextLabel", {
        Parent = rotSliderBg,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 2),
        Size = UDim2.new(1, -16, 0, 12),
        Font = self.Font,
        Text = "rotation speed",
        TextSize = 11,
        TextColor3 = self.Theme.DarkText,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local rotFill = New("Frame", {
        Parent = rotSliderBg,
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 18),
        Size = UDim2.new(0.5, -8, 0, 4),
    })
    Corner(2, rotFill)
    local rotKnob = New("TextButton", {
        Parent = rotSliderBg,
        BackgroundColor3 = self.Theme.LightText,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.fromOffset(10, 10),
        Position = UDim2.new(0.5, -5, 0, 15),
    })
    Corner(5, rotKnob)

    local zoomSliderBg = New("Frame", {
        Parent = previewControls,
        BackgroundColor3 = self.Theme.Inline,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 28),
        LayoutOrder = 3,
    })
    Corner(4, zoomSliderBg)
    New("TextLabel", {
        Parent = zoomSliderBg,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 2),
        Size = UDim2.new(1, -16, 0, 12),
        Font = self.Font,
        Text = "zoom",
        TextSize = 11,
        TextColor3 = self.Theme.DarkText,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local zoomFill = New("Frame", {
        Parent = zoomSliderBg,
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 18),
        Size = UDim2.new(0.25, -8, 0, 4),
    })
    Corner(2, zoomFill)
    local zoomKnob = New("TextButton", {
        Parent = zoomSliderBg,
        BackgroundColor3 = self.Theme.LightText,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.fromOffset(10, 10),
        Position = UDim2.new(0.25, -5, 0, 15),
    })
    Corner(5, zoomKnob)

    local weaponButtons = {}
    local skinButtons = {}
    local selectedWeaponBtn = nil
    local selectedSkinBtn = nil
    local weaponFilter = ""
    local skinFilter = ""
    local rotationSpeed = cfg.DefaultRotationSpeed or 0.002
    local zoomMultiplier = cfg.DefaultZoom or 1
    local autoRotate = cfg.DefaultAutoRotate ~= false
    local previewModel = nil
    local previewYaw = 0
    local previewPitch = 0
    local previewAngle = 0
    local previewConn = nil
    local ZOOM_MIN = 0.001
    local SLIDER_ZOOM_MIN = 0.01
    local SLIDER_ZOOM_MAX = 100

    local function setSliderKnob(sliderBg, fill, knob, value, minV, maxV)
        local alpha = (value - minV) / (maxV - minV)
        alpha = math.clamp(alpha, 0, 1)
        local trackPad = 8
        fill.Position = UDim2.fromOffset(trackPad, 18)
        fill.Size = UDim2.new(alpha, -trackPad, 0, 4)
        if knob.AnchorPoint ~= Vector2.new(0.5, 0.5) then
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
        end
        knob.Position = UDim2.new(alpha, trackPad, 0, 18)
    end

    local function applyPreviewRotation(model, yaw, pitch)
        if not model then return end
        local rot = CFrame.Angles(pitch, yaw, 0)
        pcall(function()
            if model:IsA("Model") then
                model:PivotTo(rot)
            elseif model:IsA("BasePart") then
                model.CFrame = rot
            elseif model:IsA("Tool") then
                model:PivotTo(rot)
            end
        end)
    end

    local function applyScrollZoom(current, wheelDelta)
        local factor = 1.15 ^ wheelDelta
        return math.max(ZOOM_MIN, current * factor)
    end

    local function syncZoomSlider(sliderBg, fill, knob, value)
        setSliderKnob(
            sliderBg,
            fill,
            knob,
            math.clamp(value, SLIDER_ZOOM_MIN, SLIDER_ZOOM_MAX),
            SLIDER_ZOOM_MIN,
            SLIDER_ZOOM_MAX
        )
    end

    setSliderKnob(rotSliderBg, rotFill, rotKnob, rotationSpeed, 0.001, 0.01)
    setSliderKnob(zoomSliderBg, zoomFill, zoomKnob, zoomMultiplier, SLIDER_ZOOM_MIN, SLIDER_ZOOM_MAX)

    local function bindSlider(sliderBg, fill, knob, minV, maxV, onChange)
        local dragging = false
        Connect(knob.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)
        Connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        Connect(UserInputService.InputChanged, function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            local rel = sliderBg.AbsolutePosition.X
            local width = sliderBg.AbsoluteSize.X - 16
            local alpha = math.clamp((input.Position.X - rel - 8) / width, 0, 1)
            local value = minV + (maxV - minV) * alpha
            onChange(value)
            setSliderKnob(sliderBg, fill, knob, value, minV, maxV)
        end)
    end

    bindSlider(rotSliderBg, rotFill, rotKnob, 0.001, 0.01, function(v)
        rotationSpeed = v
        if cfg.OnRotationSpeedChanged then cfg.OnRotationSpeedChanged(v) end
    end)

    local function clearListButtons(buttons)
        for _, btn in ipairs(buttons) do
            btn:Destroy()
        end
        table.clear(buttons)
    end

    local function populateList(list, items, buttons, selectedName, filterText, onSelect)
        clearListButtons(buttons)
        local filter = string.lower(filterText or "")
        for i, name in ipairs(items) do
            if filter == "" or string.find(string.lower(name), filter, 1, true) then
                local btn = New("TextButton", {
                    Parent = list,
                    BackgroundColor3 = self.Theme.PageBackground,
                    AutoButtonColor = false,
                    Size = UDim2.new(1, 0, 0, 22),
                    Font = self.Font,
                    Text = name,
                    TextSize = 12,
                    TextColor3 = name == selectedName and self.Theme.Accent or self.Theme.Text,
                    LayoutOrder = i,
                    ZIndex = 4,
                })
                Corner(3, btn)
                table.insert(buttons, btn)
                Connect(btn.MouseButton1Click, function()
                    onSelect(name, btn)
                end)
            end
        end
    end

    local function getPreviewBounds(model)
        if model:IsA("BasePart") then
            return model.CFrame, model.Size
        end

        if model:IsA("Model") and model.GetBoundingBox then
            local ok, cf, size = pcall(function()
                return model:GetBoundingBox()
            end)
            if ok and cf then
                return cf, size
            end
        end

        local minV, maxV
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                local pos = part.Position
                if not minV then
                    minV = pos
                    maxV = pos
                else
                    minV = Vector3.new(
                        math.min(minV.X, pos.X),
                        math.min(minV.Y, pos.Y),
                        math.min(minV.Z, pos.Z)
                    )
                    maxV = Vector3.new(
                        math.max(maxV.X, pos.X),
                        math.max(maxV.Y, pos.Y),
                        math.max(maxV.Z, pos.Z)
                    )
                end
            end
        end

        if minV and maxV then
            return CFrame.new((minV + maxV) * 0.5), (maxV - minV)
        end

        return CFrame.new(), Vector3.new(2, 2, 2)
    end

    local function updatePreviewCamera()
        if not previewModel then return end
        local cf, size = getPreviewBounds(previewModel)
        local dist = math.max(size.X, size.Y, size.Z, 1) * (2.5 / zoomMultiplier)
        viewport.CurrentCamera = viewport.CurrentCamera or Instance.new("Camera")
        viewport.CurrentCamera.CFrame = CFrame.new(cf.Position + Vector3.new(dist, dist * 0.35, dist), cf.Position)
    end

    attachPreviewInput(viewportHolder, function(wheelDelta)
        zoomMultiplier = applyScrollZoom(zoomMultiplier, wheelDelta)
        syncZoomSlider(zoomSliderBg, zoomFill, zoomKnob, zoomMultiplier)
        updatePreviewCamera()
        if cfg.OnZoomChanged then
            cfg.OnZoomChanged(zoomMultiplier)
        end
    end, function(deltaX, deltaY)
        previewYaw = previewYaw + deltaX * 0.012
        previewPitch = math.clamp(previewPitch + deltaY * 0.012, -1.4, 1.4)
        applyPreviewRotation(previewModel, previewYaw + previewAngle, previewPitch)
        updatePreviewCamera()
    end)

    bindSlider(zoomSliderBg, zoomFill, zoomKnob, SLIDER_ZOOM_MIN, SLIDER_ZOOM_MAX, function(v)
        zoomMultiplier = v
        updatePreviewCamera()
        if cfg.OnZoomChanged then cfg.OnZoomChanged(v) end
    end)

    local SkinPage = {
        _worldModel = worldModel,
        _viewport = viewport,
    }

    function SkinPage:SetWeaponList(items, selected)
        populateList(weaponList, items, weaponButtons, selected, weaponFilter, function(name, btn)
            if selectedWeaponBtn then
                selectedWeaponBtn.TextColor3 = Library.Theme.Text
            end
            selectedWeaponBtn = btn
            btn.TextColor3 = Library.Theme.Accent
            if cfg.OnWeaponSelected then cfg.OnWeaponSelected(name) end
        end)
    end

    function SkinPage:SetSkinList(items, selected)
        populateList(skinList, items, skinButtons, selected, skinFilter, function(name, btn)
            if selectedSkinBtn then
                selectedSkinBtn.TextColor3 = Library.Theme.Text
            end
            selectedSkinBtn = btn
            btn.TextColor3 = Library.Theme.Accent
            if cfg.OnSkinSelected then cfg.OnSkinSelected(name) end
        end)
    end

    function SkinPage:SetPreviewModel(model)
        for _, child in ipairs(worldModel:GetChildren()) do
            child:Destroy()
        end
        previewModel = nil
        if previewConn then
            previewConn:Disconnect()
            previewConn = nil
        end
        if not model then return end
        previewModel = model
        model.Parent = worldModel
        if model:IsA("Model") then
            local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
            if primary then
                model:PivotTo(CFrame.new())
            end
        elseif model:IsA("Tool") then
            local handle = model:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                model:PivotTo(CFrame.new())
            end
        elseif model:IsA("BasePart") then
            model.CFrame = CFrame.new()
        end
        updatePreviewCamera()
        previewAngle = 0
        previewYaw = 0
        previewPitch = 0
        previewConn = Connect(RunService.RenderStepped, function(dt)
            if autoRotate and previewModel and previewModel.Parent then
                previewAngle = previewAngle + dt * (rotationSpeed * 1000)
            end
            if previewModel and previewModel.Parent then
                applyPreviewRotation(previewModel, previewYaw + previewAngle, previewPitch)
                updatePreviewCamera()
            end
        end)
    end

    function SkinPage:SetEnabled(state)
        enableMark.Visible = state == true
    end

    function SkinPage:SetAutoRotate(state)
        autoRotate = state == true
        autoRotateMark.Visible = autoRotate
    end

    function SkinPage:SetRotationSpeed(value)
        rotationSpeed = tonumber(value) or rotationSpeed
        setSliderKnob(rotSliderBg, rotFill, rotKnob, rotationSpeed, 0.001, 0.01)
    end

    function SkinPage:SetZoom(value)
        zoomMultiplier = tonumber(value) or zoomMultiplier
        syncZoomSlider(zoomSliderBg, zoomFill, zoomKnob, zoomMultiplier)
        updatePreviewCamera()
    end

    Connect(enableBox.MouseButton1Click, function()
        enableMark.Visible = not enableMark.Visible
        if cfg.OnEnabledChanged then cfg.OnEnabledChanged(enableMark.Visible) end
    end)

    Connect(autoRotateBox.MouseButton1Click, function()
        autoRotateMark.Visible = not autoRotateMark.Visible
        autoRotate = autoRotateMark.Visible
        if cfg.OnAutoRotateChanged then cfg.OnAutoRotateChanged(autoRotate) end
    end)

    Connect(weaponSearch:GetPropertyChangedSignal("Text"), function()
        weaponFilter = weaponSearch.Text
        if cfg.OnWeaponSearch then
            cfg.OnWeaponSearch(weaponFilter)
        elseif cfg._refreshWeapons then
            cfg._refreshWeapons()
        end
    end)
    Connect(weaponSearchBtn.MouseButton1Click, function()
        weaponFilter = weaponSearch.Text
        if cfg._refreshWeapons then cfg._refreshWeapons() end
    end)
    Connect(weaponClearBtn.MouseButton1Click, function()
        weaponSearch.Text = ""
        weaponFilter = ""
        if cfg._refreshWeapons then cfg._refreshWeapons() end
    end)

    Connect(skinSearch:GetPropertyChangedSignal("Text"), function()
        skinFilter = skinSearch.Text
        if cfg.OnSkinSearch then
            cfg.OnSkinSearch(skinFilter)
        elseif cfg._refreshSkins then
            cfg._refreshSkins()
        end
    end)
    Connect(skinSearchBtn.MouseButton1Click, function()
        skinFilter = skinSearch.Text
        if cfg._refreshSkins then cfg._refreshSkins() end
    end)
    Connect(skinClearBtn.MouseButton1Click, function()
        skinSearch.Text = ""
        skinFilter = ""
        if cfg._refreshSkins then cfg._refreshSkins() end
    end)

    SkinPage._cfg = cfg
    return SkinPage
end

function Library:CreatePreviewPanel(cfg)
    cfg = cfg or {}
    if not self.ScreenGui then
        return {
            Panel = { Visible = false },
            EspAnchor = nil,
            Overlay = nil,
            SetVisible = function() end,
            RebuildCharacter = function() end,
        }
    end

    local panel = New("Frame", {
        Name = "PreviewPanel",
        Parent = self.ScreenGui,
        Size = UDim2.fromOffset(280, 336),
        Position = cfg.Position or UDim2.fromOffset(740, 80),
        BackgroundColor3 = self.Theme.DarkBackground,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 25,
    })
    self:AddToRegistry(panel, "BackgroundColor3", "DarkBackground")
    Corner(8, panel)
    self:AddToRegistry(Stroke(panel, self.Theme.Border, 1, 0), "Color", "Border")

    local titleBar = New("Frame", {
        Parent = panel,
        BackgroundColor3 = self.Theme.SectionBackground,
        Size = UDim2.new(1, 0, 0, 34),
        BorderSizePixel = 0,
    })
    self:AddToRegistry(titleBar, "BackgroundColor3", "SectionBackground")

    New("TextLabel", {
        Parent = titleBar,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Font = self.FontBold,
        Text = cfg.Title or "esp preview",
        TextSize = 14,
        TextColor3 = self.Theme.LightText,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local closeBtn = New("TextButton", {
        Parent = titleBar,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(24, 24),
        Font = self.Font,
        Text = "×",
        TextSize = 18,
        TextColor3 = self.Theme.DarkText,
    })
    makeDraggable(panel, titleBar)

    local body = New("Frame", {
        Parent = panel,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 1, -34),
    })
    Padding(body, 10)

    local previewArea = New("Frame", {
        Parent = body,
        BackgroundColor3 = self.Theme.Inline,
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
    })
    self:AddToRegistry(previewArea, "BackgroundColor3", "Inline")
    Corner(6, previewArea)

    local espHost = New("Frame", {
        Name = "EspPreviewHost",
        Parent = previewArea,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 5,
        ClipsDescendants = false,
        Visible = true,
    })

    Connect(closeBtn.MouseButton1Click, function()
        panel.Visible = false
    end)

    local api = {
        Panel = panel,
        PreviewHost = espHost,
        EspAnchor = espHost,
        Overlay = espHost,
        RebuildCharacter = function() end,
        GetCharacter = function()
            return nil
        end,
    }

    function api:SetVisible(v)
        panel.Visible = v and true or false
    end

    Connect(RunService.RenderStepped, function()
        if not panel.Visible then
            return
        end
        if cfg.OnStep then
            pcall(cfg.OnStep)
        end
    end)

    self:OnUnload(function()
        if panel.Parent then
            panel:Destroy()
        end
    end)

    api:SetVisible(cfg.Visible ~= false)
    return api
end

function Library:OnUnload(fn)
    if type(fn) == "function" then
        table.insert(self.UnloadCallbacks, fn)
    end
    return self
end

function Library:Unload()
    if self.Unloaded then return end
    self.Unloaded = true
    for _, fn in ipairs(self.UnloadCallbacks) do
        pcall(fn)
    end
    for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
    table.clear(self.Connections)
    if self.ScreenGui then self.ScreenGui:Destroy() end
end

return Library
