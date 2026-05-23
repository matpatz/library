local Services = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/vars.lua"
))()

local States = {
    SelectedLibrary = nil,
    SelectedLibraryName = nil,
    ActiveWindow = nil,
}

local Values = {
    Flags = {},
    Tabs = {},
}

local Helpers = {}
local Mappings = {}
local Builders = {}

local Library = {
    Services = Services,
    Values = Values,
}

function Helpers.Notify(Title, Text, Duration)
    Services.StarterGui:SetCore("SendNotification", {
        Title = Title,
        Text = Text,
        Duration = Duration or 5,
    })
end

function Helpers.LibraryLoaded(Message)
    if States.SelectedLibrary then
        return true
    end

    Helpers.Notify("Error", Message, 5)

    return false
end

function Helpers.Call(Object, Method, ...)
    local MethodName = Mappings[States.SelectedLibraryName][Method]
    local Builder = Builders[States.SelectedLibraryName][Method]

    local Arguments = Builder(...)

    if type(Arguments) == "table" and not Arguments[1] then
        return Object[MethodName](Object, Arguments)
    end

    return Object[MethodName](Object, Arguments)
end

Mappings = {
    Rayfield = {
        CreateWindow = "CreateWindow",
        CreateTab = "CreateTab",
        CreateSection = "CreateSection",
        CreateDivider = "CreateDivider",
        CreateButton = "CreateButton",
        CreateToggle = "CreateToggle",
        CreateSlider = "CreateSlider",
        CreateInput = "CreateInput",
        CreateDropdown = "CreateDropdown",
        CreateKeybind = "CreateKeybind",
        CreateLabel = "CreateLabel",
        CreateParagraph = "CreateParagraph",
        CreateColorPicker = "CreateColorPicker",
        Notify = "Notify",
        Destroy = "Destroy",
    },

    Kavo = {
        CreateWindow = "CreateLib",
        CreateTab = "NewTab",
        CreateSection = "NewSection",
        CreateButton = "NewButton",
        CreateToggle = "NewToggle",
        CreateSlider = "NewSlider",
        CreateInput = "NewTextBox",
        CreateDropdown = "NewDropdown",
        CreateKeybind = "NewKeybind",
        CreateLabel = "NewLabel",
        Notify = "Notify",
        Destroy = "Destroy",
    },
}

Builders = {
    Rayfield = {
        CreateWindow = function(Name, Title, Subtitle, Config)
            return {
                Name = Name,
                LoadingTitle = Title,
                LoadingSubtitle = Subtitle,

                ConfigurationSaving = Config
                    and Config.ConfigurationSaving
                    or { Enabled = false },

                Theme = Config
                    and Config.Theme
                    or "Default",

                Icon = Config
                    and Config.Icon
                    or 0,

                ToggleUIKeybind = Config
                    and Config.ToggleUIKeybind
                    or "K",
            }
        end,

        CreateTab = function(Name, Icon)
            return Name, Icon
        end,

        CreateSection = function(Name)
            return Name
        end,

        CreateButton = function(Name, Description, Callback)
            return {
                Name = Name,
                Info = Description,
                Callback = Callback,
            }
        end,

        CreateToggle = function(Name, Default, Flag, Callback)
            return {
                Name = Name,
                CurrentValue = Default,
                Flag = Flag,
                Callback = Callback,
            }
        end,

        CreateSlider = function(
            Name,
            Min,
            Max,
            Increment,
            Default,
            Suffix,
            Flag,
            Callback
        )
            return {
                Name = Name,
                Range = { Min, Max },
                Increment = Increment,
                CurrentValue = Default,
                Suffix = Suffix,
                Flag = Flag,
                Callback = Callback,
            }
        end,

        CreateInput = function(
            Name,
            Placeholder,
            Default,
            Flag,
            RemoveAfter,
            Callback
        )
            return {
                Name = Name,
                PlaceholderText = Placeholder,
                CurrentValue = Default,
                Flag = Flag,
                RemoveTextAfterFocusLost = RemoveAfter,
                Callback = Callback,
            }
        end,

        CreateDropdown = function(
            Name,
            Options,
            Default,
            Multi,
            Flag,
            Callback
        )
            return {
                Name = Name,
                Options = Options,
                CurrentOption = Default,
                MultipleOptions = Multi,
                Flag = Flag,
                Callback = Callback,
            }
        end,

        CreateKeybind = function(
            Name,
            Default,
            Hold,
            Flag,
            Callback
        )
            return {
                Name = Name,
                CurrentKeybind = Default,
                HoldToInteract = Hold,
                Flag = Flag,
                Callback = Callback,
            }
        end,

        CreateLabel = function(Text, Icon, Color, IgnoreTheme)
            return Text, Icon, Color, IgnoreTheme
        end,

        CreateParagraph = function(Title, Content)
            return {
                Title = Title,
                Content = Content,
            }
        end,

        CreateColorPicker = function(Name, Default, Flag, Callback)
            return {
                Name = Name,
                Color = Default,
                Flag = Flag,
                Callback = Callback,
            }
        end,

        Notify = function(Title, Content, Duration, Image)
            return {
                Title = Title,
                Content = Content,
                Duration = Duration,
                Image = Image,
            }
        end,
    },

    Kavo = {
        CreateWindow = function(Name, _, _, Config)
            return Name,
                Config
                and Config.Theme
                or "Dark Blue"
        end,

        CreateTab = function(Name, Icon)
            return Name, Icon
        end,

        CreateSection = function(Name)
            return Name
        end,

        CreateButton = function(Name, _, Callback)
            return Name, Callback
        end,

        CreateToggle = function(Name, Default, Flag, Callback)
            return Name, Flag, Default, Callback
        end,

        CreateSlider = function(
            Name,
            Min,
            Max,
            Increment,
            Default,
            _,
            Flag,
            Callback
        )
            return Name,
                Min,
                Max,
                Increment,
                Default,
                Flag,
                Callback
        end,

        CreateInput = function(Name, _, _, Flag, _, Callback)
            return Name, Flag, Callback
        end,

        CreateDropdown = function(Name, Options, _, _, Flag, Callback)
            return Name, Options, Flag, Callback
        end,

        CreateKeybind = function(Name, Default, _, Flag, Callback)
            return Name, Default, Flag, Callback
        end,

        CreateLabel = function(Text)
            return Text
        end,

        Notify = function(Title, Content, Duration)
            return Title, Content, Duration
        end,
    },
}

function Library:CreateLibrary(Selected, Config)
    if not Mappings[Selected] then
        Helpers.Notify(
            "Error",
            "Selected Library is not available",
            5
        )

        return nil
    end

    States.SelectedLibraryName = Selected
    States.SelectedLibrary = Services[Selected:lower()]
        or _G[Selected]

    if Config then
        for YourName, LibraryName in pairs(Config) do
            Mappings[Selected][YourName] = LibraryName
        end
    end

    return self
end

function Library:CreateWindow(Name, Title, Subtitle, Config)
    if not Helpers.LibraryLoaded(
        "Attempt to create Window without Library"
    ) then
        return
    end

    States.ActiveWindow = Helpers.Call(
        States.SelectedLibrary,
        "CreateWindow",
        Name,
        Title,
        Subtitle,
        Config
    )

    return States.ActiveWindow
end

function Library:CreateTab(Name, Icon)
    if not Helpers.LibraryLoaded(
        "Attempt to create Tab without Library"
    ) then
        return
    end

    local Tab = Helpers.Call(
        States.ActiveWindow,
        "CreateTab",
        Name,
        Icon
    )

    Values.Tabs[Name] = Tab

    return Tab
end

function Library:CreateSection(Tab, Name)
    if not Helpers.LibraryLoaded(
        "Attempt to create Section without Library"
    ) then
        return
    end

    return Helpers.Call(Tab, "CreateSection", Name)
end

function Library:CreateDivider(Tab)
    if not Helpers.LibraryLoaded(
        "Attempt to create Divider without Library"
    ) then
        return
    end

    return Helpers.Call(Tab, "CreateDivider")
end

function Library:CreateButton(Tab, Name, Description, Callback)
    if not Helpers.LibraryLoaded(
        "Attempt to create Button without Library"
    ) then
        return
    end

    return Helpers.Call(
        Tab,
        "CreateButton",
        Name,
        Description,
        Callback
    )
end

function Library:CreateToggle(Tab, Name, Default, Flag, Callback)
    if not Helpers.LibraryLoaded(
        "Attempt to create Toggle without Library"
    ) then
        return
    end

    Values.Flags[Flag] = Default

    return Helpers.Call(
        Tab,
        "CreateToggle",
        Name,
        Default,
        Flag,
        Callback
    )
end

function Library:CreateSlider(
    Tab,
    Name,
    Min,
    Max,
    Increment,
    Default,
    Suffix,
    Flag,
    Callback
)
    if not Helpers.LibraryLoaded(
        "Attempt to create Slider without Library"
    ) then
        return
    end

    Values.Flags[Flag] = Default

    return Helpers.Call(
        Tab,
        "CreateSlider",
        Name,
        Min,
        Max,
        Increment,
        Default,
        Suffix,
        Flag,
        Callback
    )
end

function Library:Notify(Title, Content, Duration, Image)
    if not Helpers.LibraryLoaded(
        "Attempt to notify without Library"
    ) then
        return
    end

    return Helpers.Call(
        States.SelectedLibrary,
        "Notify",
        Title,
        Content,
        Duration,
        Image
    )
end

function Library:Destroy()
    if not Helpers.LibraryLoaded(
        "Attempt to destroy without Library"
    ) then
        return
    end

    Helpers.Call(
        States.SelectedLibrary,
        "Destroy"
    )

    States.SelectedLibrary = nil
    States.SelectedLibraryName = nil
    States.ActiveWindow = nil

    table.clear(Values.Flags)
    table.clear(Values.Tabs)
end

return Library
