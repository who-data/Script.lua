--[[
    RiverLib - Biblioteca de UI para Roblox
    Baseada no estilo visual do script River
    
    USO BÁSICO:
    
        local RiverLib = loadstring(...)()
        
        local window = RiverLib.new({
            title = "MeuScript",
            name  = "MeuScript",   -- nome do ScreenGui
        })
        
        local tab = window:create_tab("Combat", "rbxassetid://123456")
        
        local mod = tab:create_module({
            title       = "Auto Parry",
            flag        = "AutoParry",
            description = "Automatically parry balls",
            section     = "left",   -- "left" ou "right"
            callback    = function(value) print("Toggle:", value) end
        })
        
        mod:create_checkbox({
            title    = "Enable Trail",
            flag     = "EnableTrail",
            callback = function(v) end
        })
        
        mod:create_slider({
            title         = "Delay (ms)",
            flag          = "ParryDelay",
            min           = 0,
            max           = 500,
            default       = 100,
            round_number  = true,
            callback      = function(v) end
        })
        
        mod:create_dropdown({
            title    = "Mode",
            flag     = "ParryMode",
            options  = {"Auto", "Manual", "Hybrid"},
            callback = function(selected) end
        })
        
        mod:create_textbox({
            title       = "Custom Key",
            flag        = "CustomKey",
            placeholder = "Enter value...",
            callback    = function(text) end
        })
        
        mod:create_divider({})
        
        mod:create_paragraph({
            title = "Info",
            text  = "This module controls the auto parry system."
        })
        
        mod:create_text({
            text = "Status: Running"
        })
        
        window:load()
        
    NOTIFICAÇÕES:
        RiverLib.notify({
            title    = "Success",
            text     = "Auto parry activated!",
            duration = 3
        })
        
    TEMAS:
        window:apply_theme("Blue Neon")
        -- Temas: "Default (White)", "Blue Neon", "Purple Void", "Cyberpunk",
        --        "Midnight", "Blood", "Hacker", "Vaporwave", "Dracula", "Nord",
        --        "Sakura", "Emerald", "Gold", "Ocean", "Solar", "Frost"
]]

local RiverLib = {}
RiverLib.__index = RiverLib

-- ─── Serviços ───────────────────────────────────────────────────────────────
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local CoreGui        = game:GetService("CoreGui")
local HttpService    = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local TextService    = game:GetService("TextService")
local Debris         = game:GetService("Debris")

local LocalPlayer    = Players.LocalPlayer

-- ─── Helpers de Conexão ─────────────────────────────────────────────────────
local function make_connections()
    local conns = {}
    function conns:add(key, c) conns[key] = c end
    function conns:disconnect(key)
        if conns[key] then
            conns[key]:Disconnect()
            conns[key] = nil
        end
    end
    function conns:disconnect_all()
        for k, c in pairs(conns) do
            if typeof(c) == "RBXScriptConnection" then
                pcall(c.Disconnect, c)
            end
        end
    end
    return conns
end

-- ─── Tema ───────────────────────────────────────────────────────────────────
local ThemeColors = {
    Primary      = Color3.fromRGB(255, 255, 255),
    PrimaryDark  = Color3.fromRGB(200, 200, 200),
    PrimaryLight = Color3.fromRGB(255, 255, 255),
    Accent       = Color3.fromRGB(255, 255, 255),
    Background   = Color3.fromRGB(0,   0,   0  ),
    SecondaryBg  = Color3.fromRGB(10,  10,  10 ),
    TertiaryBg   = Color3.fromRGB(20,  20,  20 ),
    Border       = Color3.fromRGB(255, 255, 255),
    TextPrimary  = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(200, 200, 200),
    TextDisabled = Color3.fromRGB(100, 100, 100),
}

local Themes = {
    ["Default (White)"] = { Primary=Color3.fromRGB(255,255,255), PrimaryDark=Color3.fromRGB(200,200,200), PrimaryLight=Color3.fromRGB(255,255,255), Accent=Color3.fromRGB(255,255,255), Border=Color3.fromRGB(255,255,255) },
    ["Blue Neon"]       = { Primary=Color3.fromRGB(0,170,255),   PrimaryDark=Color3.fromRGB(0,100,200),   PrimaryLight=Color3.fromRGB(100,210,255), Accent=Color3.fromRGB(0,200,255),   Border=Color3.fromRGB(0,170,255)   },
    ["Purple Void"]     = { Primary=Color3.fromRGB(170,0,255),   PrimaryDark=Color3.fromRGB(100,0,150),   PrimaryLight=Color3.fromRGB(200,100,255), Accent=Color3.fromRGB(180,0,255),   Border=Color3.fromRGB(170,0,255)   },
    ["Cyberpunk"]       = { Primary=Color3.fromRGB(0,255,255),   PrimaryDark=Color3.fromRGB(255,0,255),   PrimaryLight=Color3.fromRGB(0,255,127),   Accent=Color3.fromRGB(255,255,0),   Border=Color3.fromRGB(0,255,255)   },
    ["Midnight"]        = { Primary=Color3.fromRGB(50,50,50),    PrimaryDark=Color3.fromRGB(20,20,20),    PrimaryLight=Color3.fromRGB(100,100,100), Accent=Color3.fromRGB(255,255,255), Border=Color3.fromRGB(50,50,50)    },
    ["Blood"]           = { Primary=Color3.fromRGB(255,0,0),     PrimaryDark=Color3.fromRGB(100,0,0),     PrimaryLight=Color3.fromRGB(255,100,100), Accent=Color3.fromRGB(200,0,0),     Border=Color3.fromRGB(255,0,0)     },
    ["Hacker"]          = { Primary=Color3.fromRGB(0,255,0),     PrimaryDark=Color3.fromRGB(0,100,0),     PrimaryLight=Color3.fromRGB(150,255,150), Accent=Color3.fromRGB(0,200,0),     Border=Color3.fromRGB(0,255,0)     },
    ["Vaporwave"]       = { Primary=Color3.fromRGB(255,113,206), PrimaryDark=Color3.fromRGB(1,205,254),   PrimaryLight=Color3.fromRGB(5,255,161),   Accent=Color3.fromRGB(185,103,255), Border=Color3.fromRGB(255,113,206) },
    ["Dracula"]         = { Primary=Color3.fromRGB(189,147,249), PrimaryDark=Color3.fromRGB(98,114,164),  PrimaryLight=Color3.fromRGB(255,121,198), Accent=Color3.fromRGB(80,250,123),  Border=Color3.fromRGB(189,147,249) },
    ["Nord"]            = { Primary=Color3.fromRGB(136,192,208), PrimaryDark=Color3.fromRGB(76,86,106),   PrimaryLight=Color3.fromRGB(236,239,244), Accent=Color3.fromRGB(163,190,140), Border=Color3.fromRGB(136,192,208) },
    ["Sakura"]          = { Primary=Color3.fromRGB(255,183,197), PrimaryDark=Color3.fromRGB(255,105,180), PrimaryLight=Color3.fromRGB(255,240,245), Accent=Color3.fromRGB(219,112,147), Border=Color3.fromRGB(255,183,197) },
    ["Emerald"]         = { Primary=Color3.fromRGB(80,200,120),  PrimaryDark=Color3.fromRGB(40,120,60),   PrimaryLight=Color3.fromRGB(150,255,180), Accent=Color3.fromRGB(0,255,127),   Border=Color3.fromRGB(80,200,120)  },
    ["Gold"]            = { Primary=Color3.fromRGB(255,215,0),   PrimaryDark=Color3.fromRGB(184,134,11),  PrimaryLight=Color3.fromRGB(255,255,100), Accent=Color3.fromRGB(255,140,0),   Border=Color3.fromRGB(255,215,0)   },
    ["Ocean"]           = { Primary=Color3.fromRGB(0,100,200),   PrimaryDark=Color3.fromRGB(0,50,100),    PrimaryLight=Color3.fromRGB(0,150,255),   Accent=Color3.fromRGB(0,255,255),   Border=Color3.fromRGB(0,100,200)   },
    ["Solar"]           = { Primary=Color3.fromRGB(255,165,0),   PrimaryDark=Color3.fromRGB(200,100,0),   PrimaryLight=Color3.fromRGB(255,215,0),   Accent=Color3.fromRGB(255,69,0),    Border=Color3.fromRGB(255,165,0)   },
    ["Frost"]           = { Primary=Color3.fromRGB(165,242,243), PrimaryDark=Color3.fromRGB(100,200,220), PrimaryLight=Color3.fromRGB(220,255,255), Accent=Color3.fromRGB(0,255,255),   Border=Color3.fromRGB(165,242,243) },
    ["Blood Moon"]      = { Primary=Color3.fromRGB(138,3,3),     PrimaryDark=Color3.fromRGB(60,0,0),      PrimaryLight=Color3.fromRGB(255,50,50),   Accent=Color3.fromRGB(255,0,0),     Border=Color3.fromRGB(138,3,3)     },
}

-- ─── Config save/load ────────────────────────────────────────────────────────
local function make_config(game_id)
    local folder = "RiverLib"
    pcall(function()
        if not isfolder(folder) then
            makefolder(folder)
        end
    end)
    local Config = {}
    function Config:save(flags)
        pcall(function()
            writefile(folder.."/"..tostring(game_id)..".json", HttpService:JSONEncode(flags))
        end)
    end
    function Config:load(default)
        local ok, result = pcall(function()
            local path = folder.."/"..tostring(game_id)..".json"
            if isfile and isfile(path) then
                return HttpService:JSONDecode(readfile(path))
            end
        end)
        return (ok and result) or default
    end
    return Config
end

-- ─── Container de Notificações ───────────────────────────────────────────────
local NotifContainer

local function ensure_notif_container()
    if NotifContainer and NotifContainer.Parent and NotifContainer:IsDescendantOf(game) then
        return NotifContainer
    end
    local sg = Instance.new("ScreenGui")
    sg.Name = "RiverLibNotifications"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local ok = pcall(function() sg.Parent = CoreGui end)
    if not ok then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local frame = Instance.new("Frame")
    frame.Name = "Container"
    frame.Size = UDim2.new(0, 300, 0, 0)
    frame.Position = UDim2.new(1, -310, 0, 10)
    frame.BackgroundTransparency = 1
    frame.ClipsDescendants = false
    frame.ZIndex = 100
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Parent = sg

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = frame

    NotifContainer = frame
    return NotifContainer
end

-- ─── Notificação Pública ─────────────────────────────────────────────────────
function RiverLib.notify(settings)
    local container = ensure_notif_container()

    local wrapper = Instance.new("Frame")
    wrapper.Size = UDim2.new(1, 0, 0, 0)
    wrapper.BackgroundTransparency = 1
    wrapper.AutomaticSize = Enum.AutomaticSize.Y
    wrapper.LayoutOrder = #container:GetChildren()
    wrapper.Parent = container

    Instance.new("UICorner").CornerRadius = UDim.new(0, 8)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = wrapper

    local inner = Instance.new("Frame")
    inner.Size = UDim2.new(1, 0, 0, 0)
    inner.Position = UDim2.new(1, 310, 0, 0)
    inner.BackgroundColor3 = ThemeColors.SecondaryBg
    inner.BackgroundTransparency = 0.1
    inner.AutomaticSize = Enum.AutomaticSize.Y
    inner.ZIndex = 101
    inner.Parent = wrapper

    local ic = Instance.new("UICorner")
    ic.CornerRadius = UDim.new(0, 8)
    ic.Parent = inner

    local stroke = Instance.new("UIStroke")
    stroke.Color = ThemeColors.Primary
    stroke.Transparency = 0.3
    stroke.Thickness = 1
    stroke.Parent = inner

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Text = settings.title or "Notification"
    titleLbl.TextColor3 = ThemeColors.PrimaryLight
    titleLbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    titleLbl.TextSize = 14
    titleLbl.Size = UDim2.new(1, -20, 0, 20)
    titleLbl.Position = UDim2.new(0, 10, 0, 8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextWrapped = true
    titleLbl.AutomaticSize = Enum.AutomaticSize.Y
    titleLbl.ZIndex = 102
    titleLbl.Parent = inner

    local bodyLbl = Instance.new("TextLabel")
    bodyLbl.Text = settings.text or ""
    bodyLbl.TextColor3 = ThemeColors.TextSecondary
    bodyLbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    bodyLbl.TextSize = 12
    bodyLbl.Size = UDim2.new(1, -20, 0, 0)
    bodyLbl.Position = UDim2.new(0, 10, 0, 30)
    bodyLbl.BackgroundTransparency = 1
    bodyLbl.TextXAlignment = Enum.TextXAlignment.Left
    bodyLbl.TextYAlignment = Enum.TextYAlignment.Top
    bodyLbl.TextWrapped = true
    bodyLbl.AutomaticSize = Enum.AutomaticSize.Y
    bodyLbl.ZIndex = 102
    bodyLbl.Parent = inner

    task.spawn(function()
        TweenService:Create(inner, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(0,0,0,0) }):Play()
        task.wait(settings.duration or 4)
        local out = TweenService:Create(inner, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Position = UDim2.new(1, 310, 0, 0) })
        out:Play()
        out.Completed:Connect(function() wrapper:Destroy() end)
    end)
end

-- ─── Constructor Principal ────────────────────────────────────────────────────
--[[
    settings = {
        title    = "Script Name",
        name     = "ScreenGuiName",  -- opcional, padrão = title
        icon     = "rbxassetid://...", -- ícone no header (opcional)
        keybind  = Enum.KeyCode.RightShift, -- tecla para abrir/fechar (opcional)
    }
]]
function RiverLib.new(settings)
    settings = settings or {}
    local self = setmetatable({}, RiverLib)

    self._title      = settings.title   or "RiverLib"
    self._name       = settings.name    or settings.title or "RiverLib"
    self._icon       = settings.icon    or "rbxassetid://107819132007001"
    self._keybind    = settings.keybind or Enum.KeyCode.RightShift
    self._tab_count  = 0
    self._open       = true
    self._dragging   = false
    self._connections = make_connections()

    local Config = make_config(game.GameId)
    self._config = Config:load({ _flags = {}, _keybinds = {} })
    self._cfg_obj = Config

    -- Limpar instância antiga
    local old = CoreGui:FindFirstChild(self._name)
    if old then Debris:AddItem(old, 0) end

    -- ── ScreenGui ─────────────────────────────────────────────────
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = self._name
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local ok = pcall(function() ScreenGui.Parent = CoreGui end)
    if not ok then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    self._gui = ScreenGui

    -- ── Container principal ────────────────────────────────────────
    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.ClipsDescendants = true
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.BackgroundTransparency = 0.1
    Container.BackgroundColor3 = ThemeColors.Background
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.Parent = ScreenGui

    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = Container

        local s = Instance.new("UIStroke")
        s.Color = ThemeColors.Primary
        s.Transparency = 0.3
        s.Thickness = 1.5
        s.Parent = Container
        self._main_stroke = s
    end

    -- ── Handler (conteúdo interno 698×479) ────────────────────────
    local Handler = Instance.new("Frame")
    Handler.Name = "Handler"
    Handler.BackgroundTransparency = 1
    Handler.Size = UDim2.new(0, 698, 0, 479)
    Handler.Parent = Container

    -- ── Painel de Abas (sidebar esquerda 129×401) ─────────────────
    local Tabs = Instance.new("ScrollingFrame")
    Tabs.Name = "Tabs"
    Tabs.Size = UDim2.new(0, 129, 0, 401)
    Tabs.Position = UDim2.new(0.026, 0, 0.111, 0)
    Tabs.BackgroundTransparency = 1
    Tabs.ScrollBarThickness = 0
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.XY
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Selectable = false
    Tabs.Parent = Handler

    do
        local ul = Instance.new("UIListLayout")
        ul.Padding = UDim.new(0, 3)
        ul.SortOrder = Enum.SortOrder.LayoutOrder
        ul.Parent = Tabs
    end

    -- ── Título (ClientName) ────────────────────────────────────────
    local ClientName = Instance.new("TextLabel")
    ClientName.Name = "ClientName"
    ClientName.Text = self._title
    ClientName.TextColor3 = ThemeColors.PrimaryLight
    ClientName.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    ClientName.TextSize = 15
    ClientName.Size = UDim2.new(0, 80, 0, 15)
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0.056, 0, 0.055, 0)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.Parent = Handler
    self._client_name = ClientName

    do
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, ThemeColors.PrimaryLight),
            ColorSequenceKeypoint.new(1, ThemeColors.Accent)
        }
        g.Rotation = 90
        g.Parent = ClientName
    end

    -- ── Pin (indicador da tab selecionada) ────────────────────────
    local Pin = Instance.new("Frame")
    Pin.Name = "Pin"
    Pin.Size = UDim2.new(0, 3, 0, 16)
    Pin.Position = UDim2.new(0.026, 0, 0.136, 0)
    Pin.BackgroundColor3 = ThemeColors.Accent
    Pin.BorderSizePixel = 0
    Pin.Parent = Handler
    self._pin = Pin

    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = Pin
    end

    -- ── Ícone do header ───────────────────────────────────────────
    local HeaderIcon = Instance.new("ImageLabel")
    HeaderIcon.Name = "HeaderIcon"
    HeaderIcon.Image = self._icon
    HeaderIcon.Size = UDim2.new(0, 18, 0, 18)
    HeaderIcon.AnchorPoint = Vector2.new(0, 0.5)
    HeaderIcon.Position = UDim2.new(0.025, 0, 0.055, 0)
    HeaderIcon.BackgroundTransparency = 1
    HeaderIcon.ImageColor3 = ThemeColors.PrimaryLight
    HeaderIcon.ScaleType = Enum.ScaleType.Fit
    HeaderIcon.Parent = Handler

    -- ── Divisor vertical (sidebar | conteúdo) ────────────────────
    local SideDiv = Instance.new("Frame")
    SideDiv.Name = "SideDiv"
    SideDiv.Size = UDim2.new(0, 1, 0, 479)
    SideDiv.Position = UDim2.new(0.235, 0, 0, 0)
    SideDiv.BackgroundColor3 = ThemeColors.Primary
    SideDiv.BackgroundTransparency = 0.7
    SideDiv.BorderSizePixel = 0
    SideDiv.Parent = Handler
    self._side_div = SideDiv

    -- ── Pasta das seções ──────────────────────────────────────────
    local Sections = Instance.new("Folder")
    Sections.Name = "Sections"
    Sections.Parent = Handler
    self._sections = Sections

    -- ── Botão Minimize ────────────────────────────────────────────
    local MinBtn = Instance.new("TextButton")
    MinBtn.Name = "Minimize"
    MinBtn.Size = UDim2.new(0, 24, 0, 24)
    MinBtn.Position = UDim2.new(0.020, 0, 0.029, 0)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Text = ""
    MinBtn.AutoButtonColor = false
    MinBtn.Parent = Handler

    do
        local icon = Instance.new("ImageLabel")
        icon.Image = "rbxassetid://107349188422229"
        icon.Size = UDim2.new(0, 16, 0, 16)
        icon.Position = UDim2.new(0.5, 0, 0.5, 0)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.BackgroundTransparency = 1
        icon.ImageColor3 = ThemeColors.TextSecondary
        icon.Parent = MinBtn
    end

    -- ── UIScale (mobile) ──────────────────────────────────────────
    local UIScale = Instance.new("UIScale")
    UIScale.Parent = Container
    self._ui_scale_obj = UIScale

    -- ── Drag ──────────────────────────────────────────────────────
    Container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            self._dragging = true
            self._drag_start = input.Position
            self._drag_origin = Container.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    self._dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not self._dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - self._drag_start
            TweenService:Create(Container, TweenInfo.new(0.15), {
                Position = UDim2.new(
                    self._drag_origin.X.Scale, self._drag_origin.X.Offset + delta.X,
                    self._drag_origin.Y.Scale, self._drag_origin.Y.Offset + delta.Y
                )
            }):Play()
        end
    end)

    -- ── Minimize ──────────────────────────────────────────────────
    MinBtn.MouseButton1Click:Connect(function()
        self._open = not self._open
        self:change_visibility(self._open)
    end)

    -- ── Keybind para abrir/fechar ─────────────────────────────────
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == self._keybind then
            self._open = not self._open
            self:change_visibility(self._open)
        end
    end)

    -- ── Referências internas ──────────────────────────────────────
    self._container = Container
    self._tabs      = Tabs
    self._handler   = Handler

    return self
end

-- ─── Helpers internos ────────────────────────────────────────────────────────
function RiverLib:change_visibility(open)
    if open then
        TweenService:Create(self._container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(698, 479)
        }):Play()
    else
        TweenService:Create(self._container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(104, 52)
        }):Play()
    end
end

function RiverLib:_get_flag(flag)
    return self._config._flags[flag]
end
function RiverLib:_set_flag(flag, value)
    self._config._flags[flag] = value
    self._cfg_obj:save(self._config)
end
function RiverLib:_get_keybind(flag)
    return self._config._keybinds[flag]
end
function RiverLib:_set_keybind(flag, key)
    self._config._keybinds[flag] = key
    self._cfg_obj:save(self._config)
end

function RiverLib:_update_tabs(active_tab)
    for _, obj in self._tabs:GetChildren() do
        if obj.Name ~= "Tab" then continue end
        if obj == active_tab then
            TweenService:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.3,
                BackgroundColor3 = ThemeColors.SecondaryBg
            }):Play()
            local lbl = obj:FindFirstChild("TextLabel")
            if lbl then
                TweenService:Create(lbl, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0.1, TextColor3 = ThemeColors.PrimaryLight
                }):Play()
                local g = lbl:FindFirstChildOfClass("UIGradient")
                if g then g.Enabled = false end
            end
            local ic = obj:FindFirstChild("Icon")
            if ic then
                TweenService:Create(ic, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.1, ImageColor3 = ThemeColors.PrimaryLight
                }):Play()
            end
            -- mover pin
            local offset = obj.LayoutOrder * (0.113 / 1.3)
            TweenService:Create(self._pin, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.fromScale(0.026, 0.135 + offset)
            }):Play()
        else
            TweenService:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            }):Play()
            local lbl = obj:FindFirstChild("TextLabel")
            if lbl then
                TweenService:Create(lbl, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0.5, TextColor3 = ThemeColors.TextSecondary
                }):Play()
                local g = lbl:FindFirstChildOfClass("UIGradient")
                if g then g.Enabled = true end
            end
            local ic = obj:FindFirstChild("Icon")
            if ic then
                TweenService:Create(ic, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.5, ImageColor3 = ThemeColors.TextSecondary
                }):Play()
            end
        end
    end
end

function RiverLib:_update_sections(left, right)
    for _, obj in self._sections:GetChildren() do
        obj.Visible = (obj == left or obj == right)
    end
end

-- ─── apply_theme ─────────────────────────────────────────────────────────────
function RiverLib:apply_theme(name)
    local t = Themes[name]
    if not t then return end
    for k, v in pairs(t) do
        ThemeColors[k] = v
    end
    -- notifica
    RiverLib.notify({ title = "Theme", text = name .. " applied!", duration = 2 })
end

-- ─── load ────────────────────────────────────────────────────────────────────
function RiverLib:load()
    -- Detectar mobile e escalar UI
    local function detect_and_scale()
        local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
        if isMobile then
            local vp = workspace.CurrentCamera.ViewportSize.X
            self._ui_scale_obj.Scale = vp / 1400
        end
    end
    detect_and_scale()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(detect_and_scale)

    -- Abrir com tween
    TweenService:Create(self._container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(698, 479)
    }):Play()
end

-- ─── create_tab ──────────────────────────────────────────────────────────────
--[[
    title = "Tab Name"
    icon  = "rbxassetid://..."   (opcional)
]]
function RiverLib:create_tab(title, icon)
    icon = icon or "rbxassetid://79095934438045"
    self._tab_count = self._tab_count + 1
    local is_first = not self._tabs:FindFirstChild("Tab")

    -- ── Botão da aba ──────────────────────────────────────────────
    local Tab = Instance.new("TextButton")
    Tab.Name = "Tab"
    Tab.Text = ""
    Tab.AutoButtonColor = false
    Tab.BackgroundTransparency = 1
    Tab.BackgroundColor3 = ThemeColors.TertiaryBg
    Tab.Size = UDim2.new(0, 129, 0, 36)
    Tab.LayoutOrder = self._tab_count
    Tab.Parent = self._tabs

    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = Tab

        -- Calcular largura do texto
        local fp = Instance.new("GetTextBoundsParams")
        fp.Text = title
        fp.Font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
        fp.Size = 12
        fp.Width = 10000
        local sz = TextService:GetTextBoundsAsync(fp)

        local lbl = Instance.new("TextLabel")
        lbl.Text = title
        lbl.TextColor3 = ThemeColors.TextSecondary
        lbl.TextTransparency = 0.5
        lbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
        lbl.TextSize = 12
        lbl.Size = UDim2.new(0, sz.X, 0, 15)
        lbl.AnchorPoint = Vector2.new(0, 0.5)
        lbl.Position = UDim2.new(0.240, 0, 0.5, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = Tab

        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, ThemeColors.TextPrimary),
            ColorSequenceKeypoint.new(0.5, ThemeColors.TextSecondary),
            ColorSequenceKeypoint.new(1, ThemeColors.TextDisabled)
        }
        g.Parent = lbl

        local ic = Instance.new("ImageLabel")
        ic.Name = "Icon"
        ic.Image = icon
        ic.Size = UDim2.new(0, 14, 0, 14)
        ic.AnchorPoint = Vector2.new(0, 0.5)
        ic.Position = UDim2.new(0.100, 0, 0.5, 0)
        ic.BackgroundTransparency = 1
        ic.ImageTransparency = 0.5
        ic.ImageColor3 = ThemeColors.TextSecondary
        ic.ScaleType = Enum.ScaleType.Fit
        ic.Parent = Tab
    end

    -- ── Seção Esquerda ────────────────────────────────────────────
    local function make_section(pos_scale)
        local sf = Instance.new("ScrollingFrame")
        sf.AutomaticCanvasSize = Enum.AutomaticSize.XY
        sf.ScrollBarThickness = 0
        sf.Size = UDim2.new(0, 243, 0, 445)
        sf.Selectable = false
        sf.AnchorPoint = Vector2.new(0, 0.5)
        sf.ScrollBarImageTransparency = 1
        sf.BackgroundTransparency = 1
        sf.Position = UDim2.new(pos_scale, 0, 0.5, 0)
        sf.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        sf.Visible = false
        sf.Parent = self._sections

        local ul = Instance.new("UIListLayout")
        ul.Padding = UDim.new(0, 11)
        ul.HorizontalAlignment = Enum.HorizontalAlignment.Center
        ul.SortOrder = Enum.SortOrder.LayoutOrder
        ul.Parent = sf

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 1)
        pad.Parent = sf

        return sf
    end

    local LeftSection  = make_section(0.259)
    local RightSection = make_section(0.629)
    LeftSection.Name  = "LeftSection"
    RightSection.Name = "RightSection"

    if is_first then
        self:_update_tabs(Tab)
        self:_update_sections(LeftSection, RightSection)
    end

    Tab.MouseButton1Click:Connect(function()
        self:_update_tabs(Tab)
        self:_update_sections(LeftSection, RightSection)
    end)

    -- ── TabManager ────────────────────────────────────────────────
    local TabManager = {}
    local lib_ref = self

    -- ── create_module ─────────────────────────────────────────────
    --[[
        settings = {
            title       = "Module Name",
            flag        = "unique_flag",
            description = "Short description",
            section     = "left" | "right",
            callback    = function(value: boolean) end,
            default     = false,
        }
    ]]
    function TabManager:create_module(settings)
        settings.flag = settings.flag or (settings.title or "Module"):gsub("%s+", "_")
        local target = (settings.section == "right") and RightSection or LeftSection

        local ModuleManager = {
            _state = false,
            _size  = 0,
            _mult  = 0,
        }

        -- Frame principal do módulo
        local Module = Instance.new("Frame")
        Module.Name = "Module"
        Module.ClipsDescendants = true
        Module.BackgroundTransparency = 0.15
        Module.BackgroundColor3 = ThemeColors.SecondaryBg
        Module.Size = UDim2.new(0, 241, 0, 85)
        Module.Parent = target

        do
            local ul = Instance.new("UIListLayout")
            ul.SortOrder = Enum.SortOrder.LayoutOrder
            ul.Parent = Module

            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = Module

            local st = Instance.new("UIStroke")
            st.Color = ThemeColors.Primary
            st.Transparency = 0.3
            st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            st.Thickness = 1
            st.Parent = Module
        end

        -- Header (clicável para toggle)
        local Header = Instance.new("TextButton")
        Header.Name = "Header"
        Header.Text = ""
        Header.AutoButtonColor = false
        Header.BackgroundTransparency = 1
        Header.Size = UDim2.new(0, 241, 0, 85)
        Header.Parent = Module

        -- Ícone do módulo
        local ModIcon = Instance.new("ImageLabel")
        ModIcon.Name = "Icon"
        ModIcon.Image = "rbxassetid://79095934438045"
        ModIcon.ImageColor3 = ThemeColors.PrimaryLight
        ModIcon.ImageTransparency = 0.5
        ModIcon.ScaleType = Enum.ScaleType.Fit
        ModIcon.Size = UDim2.new(0, 14, 0, 14)
        ModIcon.AnchorPoint = Vector2.new(0, 0.5)
        ModIcon.Position = UDim2.new(0.071, 0, 0.82, 0)
        ModIcon.BackgroundTransparency = 1
        ModIcon.Parent = Header

        -- Nome do módulo
        local ModName = Instance.new("TextLabel")
        ModName.Name = "ModuleName"
        ModName.Text = settings.title or "Module"
        ModName.TextColor3 = ThemeColors.PrimaryLight
        ModName.TextTransparency = 0.1
        ModName.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        ModName.TextSize = 13
        ModName.Size = UDim2.new(0, 205, 0, 13)
        ModName.AnchorPoint = Vector2.new(0, 0.5)
        ModName.Position = UDim2.new(0.073, 0, 0.24, 0)
        ModName.BackgroundTransparency = 1
        ModName.TextXAlignment = Enum.TextXAlignment.Left
        ModName.Parent = Header

        -- Descrição
        local ModDesc = Instance.new("TextLabel")
        ModDesc.Name = "Description"
        ModDesc.Text = settings.description or ""
        ModDesc.TextColor3 = ThemeColors.TextSecondary
        ModDesc.TextTransparency = 0.3
        ModDesc.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
        ModDesc.TextSize = 10
        ModDesc.Size = UDim2.new(0, 205, 0, 13)
        ModDesc.AnchorPoint = Vector2.new(0, 0.5)
        ModDesc.Position = UDim2.new(0.073, 0, 0.42, 0)
        ModDesc.BackgroundTransparency = 1
        ModDesc.TextXAlignment = Enum.TextXAlignment.Left
        ModDesc.Parent = Header

        -- Toggle (switch no header)
        local Toggle = Instance.new("Frame")
        Toggle.Name = "Toggle"
        Toggle.Size = UDim2.new(0, 28, 0, 14)
        Toggle.Position = UDim2.new(0.82, 0, 0.757, 0)
        Toggle.BackgroundColor3 = ThemeColors.TertiaryBg
        Toggle.BackgroundTransparency = 0.8
        Toggle.BorderSizePixel = 0
        Toggle.Parent = Header

        do
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(1, 0)
            c.Parent = Toggle
        end

        local Circle = Instance.new("Frame")
        Circle.Name = "Circle"
        Circle.Size = UDim2.new(0, 10, 0, 10)
        Circle.AnchorPoint = Vector2.new(0, 0.5)
        Circle.Position = UDim2.new(0, 2, 0.5, 0)
        Circle.BackgroundColor3 = ThemeColors.TextDisabled
        Circle.BackgroundTransparency = 0.3
        Circle.BorderSizePixel = 0
        Circle.Parent = Toggle

        do
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(1, 0)
            c.Parent = Circle
        end

        -- Keybind label
        local Keybind = Instance.new("Frame")
        Keybind.Name = "Keybind"
        Keybind.Size = UDim2.new(0, 33, 0, 15)
        Keybind.Position = UDim2.new(0.15, 0, 0.735, 0)
        Keybind.BackgroundColor3 = ThemeColors.Primary
        Keybind.BackgroundTransparency = 0.8
        Keybind.BorderSizePixel = 0
        Keybind.Parent = Header

        do
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 4)
            c.Parent = Keybind

            local saved_key = lib_ref:_get_keybind(settings.flag)
            local kb_lbl = Instance.new("TextLabel")
            kb_lbl.Name = "KeybindLabel"
            kb_lbl.Text = saved_key and tostring(saved_key):gsub("Enum.KeyCode.", "") or "None"
            kb_lbl.TextColor3 = ThemeColors.TextPrimary
            kb_lbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            kb_lbl.TextSize = 10
            kb_lbl.Size = UDim2.new(0, 25, 0, 13)
            kb_lbl.AnchorPoint = Vector2.new(0.5, 0.5)
            kb_lbl.Position = UDim2.new(0.5, 0, 0.5, 0)
            kb_lbl.BackgroundTransparency = 1
            kb_lbl.TextXAlignment = Enum.TextXAlignment.Left
            kb_lbl.Parent = Keybind
        end

        -- Divisor do header
        local function make_divider_line(pos_y)
            local d = Instance.new("Frame")
            d.Name = "Divider"
            d.Size = UDim2.new(0, 241, 0, 1)
            d.AnchorPoint = Vector2.new(0.5, 0)
            d.Position = UDim2.new(0.5, 0, pos_y, 0)
            d.BackgroundColor3 = ThemeColors.Primary
            d.BackgroundTransparency = 0.8
            d.BorderSizePixel = 0
            d.Parent = Header
        end
        make_divider_line(0.62)
        make_divider_line(1)

        -- Frame de opções (controls)
        local Options = Instance.new("Frame")
        Options.Name = "Options"
        Options.BackgroundTransparency = 1
        Options.Size = UDim2.new(0, 241, 0, 8)
        Options.Parent = Module

        do
            local pad = Instance.new("UIPadding")
            pad.PaddingTop = UDim.new(0, 8)
            pad.Parent = Options

            local ul = Instance.new("UIListLayout")
            ul.Padding = UDim.new(0, 5)
            ul.HorizontalAlignment = Enum.HorizontalAlignment.Center
            ul.SortOrder = Enum.SortOrder.LayoutOrder
            ul.Parent = Options
        end

        local layout_order = 0

        -- ── ModuleManager:change_state ─────────────────────────────
        function ModuleManager:change_state(state)
            self._state = state
            if self._state then
                TweenService:Create(Module, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(241, 85 + self._size + self._mult)
                }):Play()
                TweenService:Create(Toggle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = ThemeColors.PrimaryDark
                }):Play()
                TweenService:Create(Circle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = ThemeColors.Accent,
                    Position = UDim2.fromScale(0.53, 0.5)
                }):Play()
            else
                TweenService:Create(Module, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(241, 85)
                }):Play()
                TweenService:Create(Toggle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = ThemeColors.TertiaryBg
                }):Play()
                TweenService:Create(Circle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = ThemeColors.TextDisabled,
                    Position = UDim2.fromScale(0, 0.5)
                }):Play()
            end
            if settings.callback then
                settings.callback(self._state)
            end
            if settings.flag then
                lib_ref:_set_flag(settings.flag, self._state)
            end
        end

        -- Carregar estado salvo
        if settings.flag and lib_ref:_get_flag(settings.flag) ~= nil then
            ModuleManager:change_state(lib_ref:_get_flag(settings.flag))
        elseif settings.default then
            ModuleManager:change_state(settings.default)
        end

        Header.MouseButton1Click:Connect(function()
            ModuleManager:change_state(not ModuleManager._state)
        end)

        -- Keybind (right click no header)
        local choosing_kb = false
        Header.MouseButton2Click:Connect(function()
            if choosing_kb then return end
            choosing_kb = true
            local kb_lbl = Keybind:FindFirstChild("KeybindLabel")
            if kb_lbl then kb_lbl.Text = "..." end

            local conn
            conn = UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    conn:Disconnect()
                    choosing_kb = false
                    local key = input.KeyCode
                    if kb_lbl then
                        kb_lbl.Text = tostring(key):gsub("Enum.KeyCode.", "")
                    end
                    lib_ref:_set_keybind(settings.flag, tostring(key))

                    -- Conectar o keybind para acionar o toggle
                    UserInputService.InputBegan:Connect(function(inp, gpe2)
                        if gpe2 then return end
                        if tostring(inp.KeyCode) == tostring(key) then
                            ModuleManager:change_state(not ModuleManager._state)
                        end
                    end)
                end
            end)
        end)

        -- ─── Helpers para expandir o módulo ────────────────────────
        local function add_size(n)
            if ModuleManager._size == 0 then
                ModuleManager._size = 11
            end
            ModuleManager._size = ModuleManager._size + n
            if ModuleManager._state then
                Module.Size = UDim2.fromOffset(241, 85 + ModuleManager._size)
            end
            Options.Size = UDim2.fromOffset(241, ModuleManager._size)
        end

        -- ─── create_checkbox ───────────────────────────────────────
        --[[
            settings = {
                title    = "Label",
                flag     = "flag_key",
                callback = function(value: boolean) end,
                default  = false,
            }
        ]]
        function ModuleManager:create_checkbox(s)
            s.flag = s.flag or (s.title or "Checkbox"):gsub("%s+", "_")
            layout_order = layout_order + 1
            add_size(20)

            local CheckboxManager = { _state = false }

            local Row = Instance.new("TextButton")
            Row.Name = "Checkbox"
            Row.Text = ""
            Row.AutoButtonColor = false
            Row.BackgroundTransparency = 1
            Row.Size = UDim2.new(0, 207, 0, 15)
            Row.LayoutOrder = layout_order
            Row.Parent = Options

            local lbl = Instance.new("TextLabel")
            lbl.Name = "TitleLabel"
            lbl.Text = s.title or "Checkbox"
            lbl.TextColor3 = ThemeColors.TextPrimary
            lbl.TextTransparency = 0.2
            lbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
            lbl.TextSize = 11
            lbl.Size = UDim2.new(0, 142, 0, 13)
            lbl.AnchorPoint = Vector2.new(0, 0.5)
            lbl.Position = UDim2.new(0, 0, 0.5, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = Row

            local Box = Instance.new("Frame")
            Box.Name = "Box"
            Box.Size = UDim2.new(0, 15, 0, 15)
            Box.AnchorPoint = Vector2.new(1, 0.5)
            Box.Position = UDim2.new(1, 0, 0.5, 0)
            Box.BackgroundColor3 = ThemeColors.Primary
            Box.BackgroundTransparency = 0.9
            Box.BorderSizePixel = 0
            Box.Parent = Row

            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 4)
                c.Parent = Box
            end

            local Fill = Instance.new("Frame")
            Fill.Name = "Fill"
            Fill.AnchorPoint = Vector2.new(0.5, 0.5)
            Fill.Position = UDim2.new(0.5, 0, 0.5, 0)
            Fill.Size = UDim2.new(0, 0, 0, 0)
            Fill.BackgroundColor3 = ThemeColors.Accent
            Fill.BackgroundTransparency = 0.3
            Fill.BorderSizePixel = 0
            Fill.Parent = Box

            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 3)
                c.Parent = Fill
            end

            function CheckboxManager:change_state(state)
                self._state = state
                TweenService:Create(Fill, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = state and UDim2.new(0.75, 0, 0.75, 0) or UDim2.new(0, 0, 0, 0)
                }):Play()
                if s.flag then lib_ref:_set_flag(s.flag, self._state) end
                if s.callback then s.callback(self._state) end
            end

            -- Carregar salvo
            if s.flag and lib_ref:_get_flag(s.flag) ~= nil then
                CheckboxManager:change_state(lib_ref:_get_flag(s.flag))
            elseif s.default then
                CheckboxManager:change_state(s.default)
            end

            Row.MouseButton1Click:Connect(function()
                CheckboxManager:change_state(not CheckboxManager._state)
            end)

            return CheckboxManager
        end

        -- ─── create_slider ─────────────────────────────────────────
        --[[
            settings = {
                title        = "Label",
                flag         = "flag_key",
                min          = 0,
                max          = 100,
                default      = 50,
                round_number = true,
                callback     = function(value: number) end,
            }
        ]]
        function ModuleManager:create_slider(s)
            s.flag = s.flag or (s.title or "Slider"):gsub("%s+", "_")
            layout_order = layout_order + 1
            add_size(40)

            local SliderManager = {}

            local SliderFrame = Instance.new("TextButton")
            SliderFrame.Name = "Slider"
            SliderFrame.Text = ""
            SliderFrame.AutoButtonColor = false
            SliderFrame.BackgroundTransparency = 1
            SliderFrame.Size = UDim2.new(0, 207, 0, 30)
            SliderFrame.LayoutOrder = layout_order
            SliderFrame.Parent = Options

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Name = "SliderTitle"
            TitleLbl.Text = s.title or "Slider"
            TitleLbl.TextColor3 = ThemeColors.TextPrimary
            TitleLbl.TextTransparency = 0.2
            TitleLbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
            TitleLbl.TextSize = 10
            TitleLbl.Size = UDim2.new(0, 160, 0, 13)
            TitleLbl.Position = UDim2.new(0, 0, 0, 0)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.Parent = SliderFrame

            local ValLbl = Instance.new("TextLabel")
            ValLbl.Name = "Value"
            ValLbl.Text = tostring(s.default or s.min or 0)
            ValLbl.TextColor3 = ThemeColors.PrimaryLight
            ValLbl.TextTransparency = 0.2
            ValLbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ValLbl.TextSize = 10
            ValLbl.Size = UDim2.new(0, 42, 0, 13)
            ValLbl.AnchorPoint = Vector2.new(1, 0)
            ValLbl.Position = UDim2.new(1, 0, 0, 0)
            ValLbl.BackgroundTransparency = 1
            ValLbl.TextXAlignment = Enum.TextXAlignment.Right
            ValLbl.Parent = SliderFrame

            -- Track (área de drag)
            local Drag = Instance.new("Frame")
            Drag.Name = "Drag"
            Drag.Size = UDim2.new(0, 207, 0, 8)
            Drag.Position = UDim2.new(0, 0, 1, -8)
            Drag.BackgroundColor3 = ThemeColors.TertiaryBg
            Drag.BackgroundTransparency = 0.3
            Drag.BorderSizePixel = 0
            Drag.ClipsDescendants = true
            Drag.Parent = SliderFrame

            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(1, 0)
                c.Parent = Drag
            end

            -- Preenchimento colorido
            local FillBar = Instance.new("Frame")
            FillBar.Name = "Fill"
            FillBar.Size = UDim2.fromOffset(0, 8)
            FillBar.BackgroundColor3 = ThemeColors.Accent
            FillBar.BackgroundTransparency = 0
            FillBar.BorderSizePixel = 0
            FillBar.Parent = Drag

            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(1, 0)
                c.Parent = FillBar

                local g = Instance.new("UIGradient")
                g.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, ThemeColors.PrimaryLight),
                    ColorSequenceKeypoint.new(1, ThemeColors.Accent)
                }
                g.Parent = FillBar
            end

            local mouse = LocalPlayer:GetMouse()

            function SliderManager:set_value(val)
                local mn = s.min or 0
                local mx = s.max or 100
                local clamped = math.clamp(val, mn, mx)
                local rounded = s.round_number and math.floor(clamped) or (math.floor(clamped * 10) / 10)
                local pct = (rounded - mn) / (mx - mn)
                local fill_w = math.clamp(pct, 0.02, 1) * Drag.Size.X.Offset

                ValLbl.Text = tostring(rounded)
                TweenService:Create(FillBar, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(fill_w, 8)
                }):Play()

                if s.flag then lib_ref:_set_flag(s.flag, rounded) end
                if s.callback then s.callback(rounded) end
            end

            local dragging_slider = false
            SliderFrame.MouseButton1Down:Connect(function()
                dragging_slider = true
                local mn = s.min or 0
                local mx = s.max or 100
                local pct = (mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset
                SliderManager:set_value(mn + (mx - mn) * pct)

                local mc = mouse.Move:Connect(function()
                    if not dragging_slider then return end
                    local pct2 = (mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset
                    SliderManager:set_value(mn + (mx - mn) * pct2)
                end)
                local ue
                ue = UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and
                       inp.UserInputType ~= Enum.UserInputType.Touch then return end
                    dragging_slider = false
                    mc:Disconnect()
                    ue:Disconnect()
                    lib_ref._cfg_obj:save(lib_ref._config)
                end)
            end)

            -- Carregar salvo
            local saved = s.flag and lib_ref:_get_flag(s.flag)
            SliderManager:set_value(saved or s.default or s.min or 0)

            return SliderManager
        end

        -- ─── create_dropdown ───────────────────────────────────────
        --[[
            settings = {
                title    = "Label",
                flag     = "flag_key",
                options  = {"Option1", "Option2"},
                default  = "Option1",
                callback = function(selected: string) end,
            }
        ]]
        function ModuleManager:create_dropdown(s)
            s.flag = s.flag or (s.title or "Dropdown"):gsub("%s+", "_")
            layout_order = layout_order + 1
            add_size(44)

            local DropManager = { _open = false, _selected = nil }

            if not lib_ref._config._flags[s.flag] then
                lib_ref._config._flags[s.flag] = {}
            end

            local DDFrame = Instance.new("TextButton")
            DDFrame.Name = "Dropdown"
            DDFrame.Text = ""
            DDFrame.AutoButtonColor = false
            DDFrame.BackgroundTransparency = 1
            DDFrame.Size = UDim2.new(0, 207, 0, 39)
            DDFrame.LayoutOrder = layout_order
            DDFrame.Parent = Options

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Text = s.title or "Dropdown"
            TitleLbl.TextColor3 = ThemeColors.TextPrimary
            TitleLbl.TextTransparency = 0.3
            TitleLbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
            TitleLbl.TextSize = 10
            TitleLbl.Size = UDim2.new(0, 200, 0, 13)
            TitleLbl.Position = UDim2.new(0, 0, 0, 0)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.Parent = DDFrame

            -- Botão principal (selected)
            local Btn = Instance.new("Frame")
            Btn.Name = "DDBtn"
            Btn.Size = UDim2.new(0, 207, 0, 20)
            Btn.Position = UDim2.new(0, 0, 0, 15)
            Btn.BackgroundColor3 = ThemeColors.SecondaryBg
            Btn.BackgroundTransparency = 0.2
            Btn.BorderSizePixel = 0
            Btn.Parent = DDFrame

            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 4)
                c.Parent = Btn

                local st = Instance.new("UIStroke")
                st.Color = ThemeColors.Primary
                st.Transparency = 0.4
                st.Thickness = 1
                st.Parent = Btn
            end

            local SelLbl = Instance.new("TextLabel")
            SelLbl.Name = "Selected"
            SelLbl.Text = s.default or "Select..."
            SelLbl.TextColor3 = ThemeColors.PrimaryLight
            SelLbl.TextTransparency = 0.2
            SelLbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            SelLbl.TextSize = 10
            SelLbl.Size = UDim2.new(1, -25, 1, 0)
            SelLbl.Position = UDim2.new(0, 7, 0, 0)
            SelLbl.BackgroundTransparency = 1
            SelLbl.TextXAlignment = Enum.TextXAlignment.Left
            SelLbl.Parent = Btn

            -- Chevron
            local Arrow = Instance.new("TextLabel")
            Arrow.Text = "▼"
            Arrow.TextColor3 = ThemeColors.TextSecondary
            Arrow.TextSize = 8
            Arrow.Size = UDim2.new(0, 14, 1, 0)
            Arrow.AnchorPoint = Vector2.new(1, 0)
            Arrow.Position = UDim2.new(1, -4, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Parent = Btn

            -- Painel flutuante de opções (scroll)
            local OptionsPanel = Instance.new("ScrollingFrame")
            OptionsPanel.Name = "OptionsPanel"
            OptionsPanel.Size = UDim2.new(0, 207, 0, 0)
            OptionsPanel.Position = UDim2.new(0, 0, 0, 36)
            OptionsPanel.BackgroundColor3 = ThemeColors.SecondaryBg
            OptionsPanel.BackgroundTransparency = 0.05
            OptionsPanel.BorderSizePixel = 0
            OptionsPanel.ScrollBarThickness = 2
            OptionsPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
            OptionsPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
            OptionsPanel.Visible = false
            OptionsPanel.ZIndex = 10
            OptionsPanel.Parent = DDFrame

            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 4)
                c.Parent = OptionsPanel

                local ul = Instance.new("UIListLayout")
                ul.SortOrder = Enum.SortOrder.LayoutOrder
                ul.Padding = UDim.new(0, 2)
                ul.Parent = OptionsPanel

                local pad = Instance.new("UIPadding")
                pad.PaddingTop = UDim.new(0, 4)
                pad.PaddingBottom = UDim.new(0, 4)
                pad.Parent = OptionsPanel
            end

            local function populate()
                for _, ch in OptionsPanel:GetChildren() do
                    if ch:IsA("TextButton") then ch:Destroy() end
                end
                for _, opt in ipairs(s.options or {}) do
                    local optName = (type(opt) == "string") and opt or tostring(opt)
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Name = "Option"
                    OptBtn.Text = optName
                    OptBtn.TextColor3 = ThemeColors.TextSecondary
                    OptBtn.TextTransparency = 0.4
                    OptBtn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    OptBtn.TextSize = 10
                    OptBtn.Size = UDim2.new(1, -8, 0, 18)
                    OptBtn.BackgroundTransparency = 1
                    OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                    OptBtn.AutoButtonColor = false
                    OptBtn.ZIndex = 11
                    OptBtn.Parent = OptionsPanel

                    OptBtn.MouseEnter:Connect(function()
                        TweenService:Create(OptBtn, TweenInfo.new(0.15), { TextTransparency = 0 }):Play()
                    end)
                    OptBtn.MouseLeave:Connect(function()
                        TweenService:Create(OptBtn, TweenInfo.new(0.15), { TextTransparency = 0.4 }):Play()
                    end)

                    OptBtn.MouseButton1Click:Connect(function()
                        DropManager._selected = optName
                        SelLbl.Text = optName
                        if s.flag then lib_ref:_set_flag(s.flag, optName) end
                        if s.callback then s.callback(optName) end
                        -- fechar
                        DropManager._open = false
                        TweenService:Create(OptionsPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.new(0, 207, 0, 0)
                        }):Play()
                        task.delay(0.21, function() OptionsPanel.Visible = false end)
                    end)
                end
            end
            populate()

            DDFrame.MouseButton1Click:Connect(function()
                DropManager._open = not DropManager._open
                if DropManager._open then
                    OptionsPanel.Visible = true
                    -- calcula altura: máx 120
                    local h = math.min(#(s.options or {}) * 22 + 8, 120)
                    TweenService:Create(OptionsPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 207, 0, h)
                    }):Play()
                    -- expandir o módulo para caber
                    add_size(h)
                    if ModuleManager._state then
                        Module.Size = UDim2.fromOffset(241, 85 + ModuleManager._size)
                    end
                else
                    TweenService:Create(OptionsPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 207, 0, 0)
                    }):Play()
                    task.delay(0.21, function() OptionsPanel.Visible = false end)
                end
            end)

            function DropManager:set_options(new_opts)
                s.options = new_opts
                populate()
            end

            -- Carregar salvo
            local saved_sel = s.flag and lib_ref:_get_flag(s.flag)
            if saved_sel and type(saved_sel) == "string" then
                SelLbl.Text = saved_sel
                DropManager._selected = saved_sel
            elseif s.default then
                SelLbl.Text = s.default
                DropManager._selected = s.default
            end

            return DropManager
        end

        -- ─── create_textbox ────────────────────────────────────────
        --[[
            settings = {
                title       = "Label",
                flag        = "flag_key",
                placeholder = "Enter text...",
                callback    = function(text: string) end,
            }
        ]]
        function ModuleManager:create_textbox(s)
            s.flag = s.flag or (s.title or "Textbox"):gsub("%s+", "_")
            layout_order = layout_order + 1
            add_size(32)

            local TBManager = { _text = "" }

            local Lbl = Instance.new("TextLabel")
            Lbl.Text = s.title or "Text"
            Lbl.TextColor3 = ThemeColors.TextPrimary
            Lbl.TextTransparency = 0.2
            Lbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
            Lbl.TextSize = 10
            Lbl.Size = UDim2.new(0, 207, 0, 13)
            Lbl.Position = UDim2.new(0, 0, 0, 0)
            Lbl.BackgroundTransparency = 1
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.LayoutOrder = layout_order
            Lbl.Parent = Options

            local TB = Instance.new("TextBox")
            TB.Name = "Textbox"
            TB.Text = (s.flag and lib_ref:_get_flag(s.flag)) or ""
            TB.PlaceholderText = s.placeholder or "Enter text..."
            TB.PlaceholderColor3 = ThemeColors.TextDisabled
            TB.TextColor3 = ThemeColors.TextPrimary
            TB.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            TB.TextSize = 10
            TB.Size = UDim2.new(0, 207, 0, 15)
            TB.BackgroundColor3 = ThemeColors.SecondaryBg
            TB.BackgroundTransparency = 0.2
            TB.ClearTextOnFocus = false
            TB.LayoutOrder = layout_order
            TB.Parent = Options

            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 4)
                c.Parent = TB

                local st = Instance.new("UIStroke")
                st.Color = ThemeColors.Primary
                st.Transparency = 0.3
                st.Thickness = 1
                st.Parent = TB
            end

            TB.FocusLost:Connect(function()
                TBManager._text = TB.Text
                if s.flag then lib_ref:_set_flag(s.flag, TB.Text) end
                if s.callback then s.callback(TB.Text) end
            end)

            function TBManager:set_text(t)
                self._text = t
                TB.Text = t
            end

            return TBManager
        end

        -- ─── create_divider ────────────────────────────────────────
        --[[
            settings = {} (nenhum campo obrigatório)
        ]]
        function ModuleManager:create_divider(s)
            layout_order = layout_order + 1
            add_size(10)

            local Div = Instance.new("Frame")
            Div.Name = "DividerLine"
            Div.Size = UDim2.new(0, 207, 0, 1)
            Div.BackgroundColor3 = ThemeColors.Primary
            Div.BackgroundTransparency = 0.7
            Div.BorderSizePixel = 0
            Div.LayoutOrder = layout_order
            Div.Parent = Options
        end

        -- ─── create_paragraph ──────────────────────────────────────
        --[[
            settings = {
                title = "Section Title",
                text  = "Body text here...",
                rich  = false,
            }
        ]]
        function ModuleManager:create_paragraph(s)
            layout_order = layout_order + 1
            add_size(s.customScale or 70)

            local Para = Instance.new("Frame")
            Para.Name = "Paragraph"
            Para.BackgroundColor3 = ThemeColors.TertiaryBg
            Para.BackgroundTransparency = 0.3
            Para.Size = UDim2.new(0, 207, 0, 30)
            Para.AutomaticSize = Enum.AutomaticSize.Y
            Para.BorderSizePixel = 0
            Para.LayoutOrder = layout_order
            Para.Parent = Options

            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 6)
                c.Parent = Para
            end

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Text = s.title or "Title"
            TitleLbl.TextColor3 = ThemeColors.TextPrimary
            TitleLbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            TitleLbl.TextSize = 12
            TitleLbl.Size = UDim2.new(1, -10, 0, 20)
            TitleLbl.Position = UDim2.new(0, 5, 0, 5)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.AutomaticSize = Enum.AutomaticSize.XY
            TitleLbl.Parent = Para

            local BodyLbl = Instance.new("TextLabel")
            if not s.rich then
                BodyLbl.Text = s.text or ""
            else
                BodyLbl.RichText = true
                BodyLbl.Text = s.richtext or s.text or ""
            end
            BodyLbl.TextColor3 = ThemeColors.TextSecondary
            BodyLbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            BodyLbl.TextSize = 11
            BodyLbl.Size = UDim2.new(1, -10, 0, 20)
            BodyLbl.Position = UDim2.new(0, 5, 0, 30)
            BodyLbl.BackgroundTransparency = 1
            BodyLbl.TextXAlignment = Enum.TextXAlignment.Left
            BodyLbl.TextYAlignment = Enum.TextYAlignment.Top
            BodyLbl.TextWrapped = true
            BodyLbl.AutomaticSize = Enum.AutomaticSize.Y
            BodyLbl.Parent = Para

            Para.MouseEnter:Connect(function()
                TweenService:Create(Para, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = ThemeColors.SecondaryBg
                }):Play()
            end)
            Para.MouseLeave:Connect(function()
                TweenService:Create(Para, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = ThemeColors.TertiaryBg
                }):Play()
            end)
        end

        -- ─── create_text ───────────────────────────────────────────
        --[[
            settings = {
                text = "Any text here",
                rich = false,
            }
        ]]
        function ModuleManager:create_text(s)
            layout_order = layout_order + 1
            add_size(s.customScale or 30)

            local TextManager = {}

            local TF = Instance.new("Frame")
            TF.Name = "TextFrame"
            TF.BackgroundColor3 = ThemeColors.TertiaryBg
            TF.BackgroundTransparency = 0.3
            TF.Size = UDim2.new(0, 207, 0, s.CustomYSize or 22)
            TF.AutomaticSize = Enum.AutomaticSize.Y
            TF.BorderSizePixel = 0
            TF.LayoutOrder = layout_order
            TF.Parent = Options

            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 6)
                c.Parent = TF
            end

            local BodyLbl = Instance.new("TextLabel")
            if not s.rich then
                BodyLbl.Text = s.text or ""
            else
                BodyLbl.RichText = true
                BodyLbl.Text = s.richtext or s.text or ""
            end
            BodyLbl.TextColor3 = ThemeColors.TextSecondary
            BodyLbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            BodyLbl.TextSize = 10
            BodyLbl.Size = UDim2.new(1, -10, 1, 0)
            BodyLbl.Position = UDim2.new(0, 5, 0, 5)
            BodyLbl.BackgroundTransparency = 1
            BodyLbl.TextXAlignment = Enum.TextXAlignment.Left
            BodyLbl.TextYAlignment = Enum.TextYAlignment.Top
            BodyLbl.TextWrapped = true
            BodyLbl.AutomaticSize = Enum.AutomaticSize.Y
            BodyLbl.Parent = TF

            function TextManager:Set(new_s)
                if not new_s.rich then
                    BodyLbl.Text = new_s.text or ""
                else
                    BodyLbl.RichText = true
                    BodyLbl.Text = new_s.richtext or new_s.text or ""
                end
            end

            return TextManager
        end

        return ModuleManager
    end -- create_module

    return TabManager
end -- create_tab

-- ─── Retorno da lib ──────────────────────────────────────────────────────────
return RiverLib
