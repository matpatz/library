local services = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/vars.lua"
))()

local function Notify(title, text, duration)
    services["startergui"]:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 5
    })
end

-- Method name mappings per library
local Mappings = {
    Rayfield = {
        CreateWindow   = "CreateWindow",
        CreateTab      = "CreateTab",
        CreateSection  = "CreateSection",
        CreateDivider  = "CreateDivider",
        CreateButton   = "CreateButton",
        CreateToggle   = "CreateToggle",
        CreateSlider   = "CreateSlider",
        CreateInput    = "CreateInput",
        CreateDropdown = "CreateDropdown",
        CreateKeybind  = "CreateKeybind",
        CreateLabel    = "CreateLabel",
        CreateParagraph = "CreateParagraph",
        CreateColorPicker = "CreateColorPicker",
        Notify         = "Notify",
        Destroy        = "Destroy",
    },
    Kavo = {
        CreateWindow   = "CreateLib",
        CreateTab      = "NewTab",
        CreateSection  = "NewSection",
        CreateButton   = "NewButton",
        CreateToggle   = "NewToggle",
        CreateSlider   = "NewSlider",
        CreateInput    = "NewTextBox",
        CreateDropdown = "NewDropdown",
        CreateKeybind  = "NewKeybind",
        CreateLabel    = "NewLabel",
        Notify         = "Notify",
        Destroy        = "Destroy",
    },
}

-- How to build the args for each method, per library
local Builders = {
    Rayfield = {
        CreateWindow = function(name, title, subtitle, config)
            return {
                Name = name,
                LoadingTitle = title,
                LoadingSubtitle = subtitle,
                ConfigurationSaving = config and config.ConfigurationSaving or { Enabled = false },
                Theme = config and config.Theme or "Default",
                Icon = config and config.Icon or 0,
                ToggleUIKeybind = config and config.ToggleUIKeybind or "K",
            }
        end,
        CreateTab = function(name, icon)
            return name, icon
        end,
        CreateSection = function(name)
            return name
        end,
        CreateButton = function(name, desc, callback)
            return { Name = name, Info = desc, Callback = callback }
        end,
        CreateToggle = function(name, default, flag, callback)
            return { Name = name, CurrentValue = default, Flag = flag, Callback = callback }
        end,
        CreateSlider = function(name, min, max, increment, default, suffix, flag, callback)
            return { Name = name, Range = {min, max}, Increment = increment, Suffix = suffix, CurrentValue = default, Flag = flag, Callback = callback }
        end,
        CreateInput = function(name, placeholder, default, flag, removeAfter, callback)
            return { Name = name, PlaceholderText = placeholder, CurrentValue = default, Flag = flag, RemoveTextAfterFocusLost = removeAfter, Callback = callback }
        end,
        CreateDropdown = function(name, options, default, multi, flag, callback)
            return { Name = name, Options = options, CurrentOption = default, MultipleOptions = multi, Flag = flag, Callback = callback }
        end,
        CreateKeybind = function(name, default, hold, flag, callback)
            return { Name = name, CurrentKeybind = default, HoldToInteract = hold, Flag = flag, Callback = callback }
        end,
        CreateLabel = function(text, icon, color, ignoreTheme)
            return text, icon, color, ignoreTheme
        end,
        CreateParagraph = function(title, content)
            return { Title = title, Content = content }
        end,
        CreateColorPicker = function(name, default, flag, callback)
            return { Name = name, Color = default, Flag = flag, Callback = callback }
        end,
        Notify = function(title, content, duration, image)
            return { Title = title, Content = content, Duration = duration, Image = image }
        end,
    },
    Kavo = {
        CreateWindow = function(name, title, subtitle, config)
            return name, config and config.Theme or "Dark Blue"
        end,
        CreateTab = function(name, icon)
            return name, icon
        end,
        CreateSection = function(name)
            return name
        end,
        CreateButton = function(name, desc, callback)
            return name, callback
        end,
        CreateToggle = function(name, default, flag, callback)
            return name, flag, default, callback
        end,
        CreateSlider = function(name, min, max, increment, default, suffix, flag, callback)
            return name, min, max, increment, default, flag, callback
        end,
        CreateInput = function(name, placeholder, default, flag, removeAfter, callback)
            return name, flag, callback
        end,
        CreateDropdown = function(name, options, default, multi, flag, callback)
            return name, options, flag, callback
        end,
        CreateKeybind = function(name, default, hold, flag, callback)
            return name, default, flag, callback
        end,
        CreateLabel = function(text)
            return text
        end,
        Notify = function(title, content, duration, image)
            return title, content, duration
        end,
    },
}

local Library = {
    Flags = {},
    Tabs = {},
}

local SelectedLibraryName = nil
local SelectedLibrary = nil
local ActiveWindow = nil

function Library:CreateLibrary(Selected: string, Config: table)
    if not Mappings[Selected] then
        Notify("Error", "Selected Library is not available", 5)
        return nil
    end

    SelectedLibraryName = Selected
    SelectedLibrary = services[Selected:lower()] or _G[Selected]

    -- Apply Config remaps over the default mappings
    if Config then
        for YourName, LibraryName in pairs(Config) do
            Mappings[Selected][YourName] = LibraryName
        end
    end

    return self
end

local function LibraryLoaded(Message)
    if not SelectedLibrary then
        Notify("Error", Message, 5)
        return false
    end
    return true
end

local function Call(Object, Method, ...)
    local MethodName = Mappings[SelectedLibraryName][Method]
    local Builder = Builders[SelectedLibraryName][Method]
    local Args = Builder(...)
    if type(Args) == "table" and not Args[1] then
        -- single table arg (Rayfield style)
        return Object[MethodName](Object, Args)
    end
    return Object[MethodName](Object, Args)
end

function Library:CreateWindow(Name, Title, Subtitle, Config)
    if not LibraryLoaded("Attempt to create Window without Library") then return end
    ActiveWindow = Call(SelectedLibrary, "CreateWindow", Name, Title, Subtitle, Config)
    return ActiveWindow
end

function Library:CreateTab(Name, Icon)
    if not LibraryLoaded("Attempt to create Tab without Library") then return end
    local Tab = Call(ActiveWindow, "CreateTab", Name, Icon)
    self.Tabs[Name] = Tab
    return Tab
end

function Library:CreateSection(Tab, Name)
    if not LibraryLoaded("Attempt to create Section without Library") then return end
    return Call(Tab, "CreateSection", Name)
end

function Library:CreateDivider(Tab)
    if not LibraryLoaded("Attempt to create Divider without Library") then return end
    return Call(Tab, "CreateDivider")
end

function Library:CreateButton(Tab, Name, Desc, Callback)
    if not LibraryLoaded("Attempt to create Button without Library") then return end
    return Call(Tab, "CreateButton", Name, Desc, Callback)
end

function Library:CreateToggle(Tab, Name, Default, Flag, Callback)
    if not LibraryLoaded("Attempt to create Toggle without Library") then return end
    self.Flags[Flag] = Default
    return Call(Tab, "CreateToggle", Name, Default, Flag, Callback)
end

function Library:CreateSlider(Tab, Name, Min, Max, Increment, Default, Suffix, Flag, Callback)
    if not LibraryLoaded("Attempt to create Slider without Library") then return end
    self.Flags[Flag] = Default
    return Call(Tab, "CreateSlider", Name, Min, Max, Increment, Default, Suffix, Flag, Callback)
end

function Library:CreateInput(Tab, Name, Placeholder, Default, Flag, RemoveAfter, Callback)
    if not LibraryLoaded("Attempt to create Input without Library") then return end
    self.Flags[Flag] = Default
    return Call(Tab, "CreateInput", Name, Placeholder, Default, Flag, RemoveAfter, Callback)
end

function Library:CreateDropdown(Tab, Name, Options, Default, Multi, Flag, Callback)
    if not LibraryLoaded("Attempt to create Dropdown without Library") then return end
    self.Flags[Flag] = Default
    return Call(Tab, "CreateDropdown", Name, Options, Default, Multi, Flag, Callback)
end

function Library:CreateKeybind(Tab, Name, Default, Hold, Flag, Callback)
    if not LibraryLoaded("Attempt to create Keybind without Library") then return end
    return Call(Tab, "CreateKeybind", Name, Default, Hold, Flag, Callback)
end

function Library:CreateLabel(Tab, Text, Icon, Color, IgnoreTheme)
    if not LibraryLoaded("Attempt to create Label without Library") then return end
    return Call(Tab, "CreateLabel", Text, Icon, Color, IgnoreTheme)
end

function Library:CreateParagraph(Tab, Title, Content)
    if not LibraryLoaded("Attempt to create Paragraph without Library") then return end
    return Call(Tab, "CreateParagraph", Title, Content)
end

function Library:CreateColorPicker(Tab, Name, Default, Flag, Callback)
    if not LibraryLoaded("Attempt to create ColorPicker without Library") then return end
    self.Flags[Flag] = Default
    return Call(Tab, "CreateColorPicker", Name, Default, Flag, Callback)
end

function Library:Notify(Title, Content, Duration, Image)
    if not LibraryLoaded("Attempt to Notify without Library") then return end
    return Call(SelectedLibrary, "Notify", Title, Content, Duration, Image)
end

function Library:Destroy()
    if not LibraryLoaded("Attempt to Destroy without Library") then return end
    Call(SelectedLibrary, "Destroy")
    SelectedLibrary = nil
    SelectedLibraryName = nil
    ActiveWindow = nil
    self.Flags = {}
    self.Tabs = {}
end

return Library
