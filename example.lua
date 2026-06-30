local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kfclover67/lib/main/library.lua"))()

local Window = Library:CreateWindow({
    Title     = "tsunami",
    TitleIcon = 0,
    Size      = UDim2.fromOffset(720, 540),
    Center    = true,
})

local Tabs = {
    Test     = Window:AddTab("test"),
    Settings = Window:AddTab("settings"),
}

local components = Tabs.Test:AddLeftGroupbox("components", "every ui element")

components:AddLabel("plain label")
components:AddLabel("wrapped label that can span multiple lines if you need it", true)

local mainToggle = components:AddToggle("main_toggle", {
    Text = "main toggle",
    Default = false,
    Callback = function(v)
        print("[test] main toggle:", v)
    end,
})
mainToggle:AddColorPicker("main_color", {
    Title = "main color",
    Default = Color3.fromRGB(74, 140, 200),
    Callback = function(col)
        print("[test] main color:", col)
    end,
})
mainToggle:AddKeyPicker("main_key", {
    Text = "main toggle",
    Default = "",
    Mode = "Toggle",
    SyncToggleState = true,
})

components:AddSlider("test_slider", {
    Text = "slider",
    Min = 0,
    Max = 100,
    Default = 50,
    Rounding = 1,
    Suffix = "%",
    Callback = function(v)
        print("[test] slider:", v)
    end,
})

components:AddInput("test_input", {
    Text = "input",
    Default = "",
    Placeholder = "type something",
    Callback = function(v)
        print("[test] input:", v)
    end,
})

components:AddDropdown("test_dropdown", {
    Text = "dropdown",
    Values = { "option a", "option b", "option c" },
    Default = "option a",
    Callback = function(v)
        print("[test] dropdown:", v)
    end,
})

components:AddDropdown("test_multi", {
    Text = "multi dropdown",
    Values = { "red", "green", "blue" },
    Multi = true,
    Default = { "red" },
})

components:AddKeyPicker("standalone_key", {
    Text = "standalone keypicker",
    Default = "",
    Mode = "Toggle",
})

components:AddColorPicker("standalone_color", {
    Title = "standalone color",
    Default = Color3.fromRGB(255, 100, 100),
})

local btn = components:AddButton("action_btn", {
    Text = "button",
    Func = function()
        Library:Notify("button clicked")
    end,
})
btn:AddButton("action_btn2", {
    Text = "button 2",
    Func = function()
        Library:Notify("second button clicked")
    end,
})

local deps = Tabs.Test:AddRightGroupbox("dependencies", "show / hide based on other controls")

deps:AddLabel("toggle dependency")
local enableDep = deps:AddToggle("enable_dep", { Text = "enable section", Default = false })

local toggleDep = deps:AddDependencyBox()
toggleDep:AddSlider("dep_slider", { Text = "power", Min = 0, Max = 100, Default = 25 })
toggleDep:AddToggle("dep_extra", { Text = "extra toggle", Default = false })
toggleDep:AddInput("dep_input", { Text = "extra input", Default = "", Placeholder = "only visible when enabled" })
toggleDep:SetupDependencies({ { Toggles.enable_dep, true } })

deps:AddLabel("dropdown dependency")
local depMode = deps:AddDropdown("dep_mode", {
    Text = "mode",
    Values = { "simple", "advanced", "expert" },
    Default = "simple",
})

local modeDep = deps:AddDependencyBox()
modeDep:AddLabel("only shows when mode is advanced")
modeDep:AddSlider("advanced_slider", { Text = "advanced value", Min = 0, Max = 10, Default = 5 })
modeDep:SetupDependencies({ { Options.dep_mode, "advanced" } })

deps:AddLabel("combined dependency")
local master = deps:AddToggle("master_toggle", { Text = "master", Default = false })
local method = deps:AddDropdown("combo_method", {
    Text = "method",
    Values = { "alpha", "beta", "gamma" },
    Default = "alpha",
})

local comboDep = deps:AddDependencyBox()
comboDep:AddLabel("needs master on + method beta")
comboDep:AddToggle("combo_toggle", { Text = "combo toggle", Default = false })
comboDep:AddKeyPicker("combo_key", { Text = "combo key", Default = "", Mode = "Hold" })
comboDep:SetupDependencies({
    { toggles.master_toggle, true },
    { options.combo_method, "beta" },
})

Library:BuildSettingsTab(Tabs.Settings)

Library:CreateWatermark()
Library:CreateKeybindList()
Library:SetMenuKeybind(Enum.KeyCode.RightShift)
Library:LoadAutoload()

