--[[
    UI Library Wrapper
    -------------------
    Lets a script target one consistent API (CreateWindow, CreateTab,
    CreateButton, ...) while the actual backend (Rayfield, Kavo, etc.)
    is swapped underneath. Supports per-method name aliasing so a
    script can call e.g. `tabs.main:MakeButton(...)` instead of
    `tabs.main:CreateButton(...)`, without losing the original name.

    Usage:

        local Library = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/matpatz/library/refs/heads/main/main.luau"
        ))()

        local Rayfield = Library:CreateLibrary("Rayfield", {
            CreateButton = "MakeButton", -- adds MakeButton as an alias of CreateButton
        })

        local Window = Rayfield:CreateWindow({
            Name = "Important Question",
            LoadingTitle = "fah you",
            LoadingSubtitle = "subtitle",
        })

        local tabs = {
            main = Window:CreateTab("Main", 4483362458),
        }

        tabs.main:CreateLabel("Why is Lebron james the goat")

        tabs.main:MakeButton({
            Name = "He just is",
            Callback = function() end,
        })

        Library:SetLibrary("Kavo")
]]

local Services = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/vars.lua"
))()

local States = {
    SelectedLibrary = nil,     -- the raw backend object/table (e.g. Rayfield's module)
    SelectedLibraryName = nil, -- "Rayfield" / "Kavo" / ...
}

local Values = {
    Flags = {},
}

local Helpers = {}
local Mappings = {}
local Builders = {}
local Aliases = {}

local Library = {
    Services = Services,
    Values = Values,
}

--------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------

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

-- Resolves an alias (e.g. "MakeButton") back to its canonical method
-- name (e.g. "CreateButton"). Returns the input unchanged if it's not
-- an alias, since canonical names always remain valid.
function Helpers.ResolveAlias(LibraryName, MethodName)
    local LibraryAliases = Aliases[LibraryName]

    if LibraryAliases and LibraryAliases[MethodName] then
        return LibraryAliases[MethodName]
    end

    return MethodName
end

-- Builds the backend-specific arguments for a canonical method and
-- invokes it on the given raw backend object.
--
-- Builders can return either:
--   (a) a single config table (e.g. Rayfield's CreateButton), or
--   (b) multiple positional values (e.g. Kavo's CreateButton).
-- Both shapes are supported: positional returns are packed and
-- splatted as separate arguments to the backend method.
function Helpers.Call(Object, Method, ...)
    local LibraryName = States.SelectedLibraryName
    local CanonicalMethod = Helpers.ResolveAlias(LibraryName, Method)

    local MethodName = Mappings[LibraryName][CanonicalMethod]
    local Builder = Builders[LibraryName][CanonicalMethod]

    if not MethodName or not Builder then
        Helpers.Notify(
            "Error",
            ("Method '%s' is not supported by %s"):format(
                CanonicalMethod,
                LibraryName
            ),
            5
        )
        return nil
    end

    local PackedArguments = table.pack(Builder(...))

    -- Single config-table return: pass it through as-is.
    if PackedArguments.n == 1 and type(PackedArguments[1]) == "table" then
        return Object[MethodName](Object, PackedArguments[1])
    end

    -- Multiple positional return values: splat them all.
    return Object[MethodName](Object, table.unpack(PackedArguments, 1, PackedArguments.n))
end

-- Wraps a raw backend object (a window, tab, or section returned by
-- the backend library) in a proxy whose __index dispatches method
-- calls through Helpers.Call, resolving aliases first. This is what
-- lets `tabs.main:CreateLabel(...)` and `tabs.main:MakeButton(...)`
-- both work on the same object.
function Helpers.Wrap(RawObject)
    if RawObject == nil then
        return nil
    end

    local Proxy = { __raw = RawObject }

    setmetatable(Proxy, {
        __index = function(_, Key)
            -- Allow direct passthrough access to non-wrapped fields
            -- on the raw object (e.g. RawObject.SomeProperty).
            if RawObject[Key] ~= nil and type(RawObject[Key]) ~= "function" then
                return RawObject[Key]
            end

            return function(_, ...)
                local Result = Helpers.Call(RawObject, Key, ...)

                -- If the backend returned a child UI element (a new
                -- tab, section, etc.) wrap it too so chained calls
                -- keep working the same way.
                if type(Result) == "table" then
                    return Helpers.Wrap(Result)
                end

                return Result
            end
        end,
    })

    return Proxy
end

--------------------------------------------------------------------------
-- Mappings: canonical method name -> backend's real method name
--------------------------------------------------------------------------

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

--------------------------------------------------------------------------
-- Builders: canonical method args -> backend-specific call shape
--------------------------------------------------------------------------

Builders = {
    Rayfield = {
        -- Accepts a single config table, matching Rayfield's real API
        -- and the wrapper's intended usage:
        --   Rayfield:CreateWindow({ Name = ..., LoadingTitle = ..., ... })
        CreateWindow = function(Config)
            Config = Config or {}

            return {
                Name = Config.Name,
                LoadingTitle = Config.LoadingTitle,
                LoadingSubtitle = Config.LoadingSubtitle,

                ConfigurationSaving = Config.ConfigurationSaving
                    or { Enabled = false },

                Theme = Config.Theme or "Default",
                Icon = Config.Icon or 0,
                ToggleUIKeybind = Config.ToggleUIKeybind or "K",
            }
        end,

        CreateTab = function(Name, Icon)
            return Name, Icon
        end,

        CreateSection = function(Name)
            return Name
        end,

        CreateDivider = function()
            return nil
        end,

        CreateButton = function(Config)
            Config = Config or {}

            return {
                Name = Config.Name,
                Info = Config.Description,
                Callback = Config.Callback,
            }
        end,

        CreateToggle = function(Config)
            Config = Config or {}

            return {
                Name = Config.Name,
                CurrentValue = Config.Default,
                Flag = Config.Flag,
                Callback = Config.Callback,
            }
        end,

        CreateSlider = function(Config)
            Config = Config or {}

            return {
                Name = Config.Name,
                Range = { Config.Min, Config.Max },
                Increment = Config.Increment,
                CurrentValue = Config.Default,
                Suffix = Config.Suffix,
                Flag = Config.Flag,
                Callback = Config.Callback,
            }
        end,

        CreateInput = function(Config)
            Config = Config or {}

            return {
                Name = Config.Name,
                PlaceholderText = Config.Placeholder,
                CurrentValue = Config.Default,
                Flag = Config.Flag,
                RemoveTextAfterFocusLost = Config.RemoveAfter,
                Callback = Config.Callback,
            }
        end,

        CreateDropdown = function(Config)
            Config = Config or {}

            return {
                Name = Config.Name,
                Options = Config.Options,
                CurrentOption = Config.Default,
                MultipleOptions = Config.Multi,
                Flag = Config.Flag,
                Callback = Config.Callback,
            }
        end,

        CreateKeybind = function(Config)
            Config = Config or {}

            return {
                Name = Config.Name,
                CurrentKeybind = Config.Default,
                HoldToInteract = Config.Hold,
                Flag = Config.Flag,
                Callback = Config.Callback,
            }
        end,

        CreateLabel = function(Text, Icon, Color, IgnoreTheme)
            return Text, Icon, Color, IgnoreTheme
        end,

        CreateParagraph = function(Config)
            Config = Config or {}

            return {
                Title = Config.Title,
                Content = Config.Content,
            }
        end,

        CreateColorPicker = function(Config)
            Config = Config or {}

            return {
                Name = Config.Name,
                Color = Config.Default,
                Flag = Config.Flag,
                Callback = Config.Callback,
            }
        end,

        Notify = function(Config)
            Config = Config or {}

            return {
                Title = Config.Title,
                Content = Config.Content,
                Duration = Config.Duration,
                Image = Config.Image,
            }
        end,

        Destroy = function()
            return nil
        end,
    },

    Kavo = {
        CreateWindow = function(Config)
            Config = Config or {}

            return Config.Name, Config.Theme or "Dark Blue"
        end,

        CreateTab = function(Name, Icon)
            return Name, Icon
        end,

        CreateSection = function(Name)
            return Name
        end,

        CreateButton = function(Config)
            Config = Config or {}

            return Config.Name, Config.Callback
        end,

        CreateToggle = function(Config)
            Config = Config or {}

            return Config.Name, Config.Flag, Config.Default, Config.Callback
        end,

        CreateSlider = function(Config)
            Config = Config or {}

            return Config.Name,
                Config.Min,
                Config.Max,
                Config.Increment,
                Config.Default,
                Config.Flag,
                Config.Callback
        end,

        CreateInput = function(Config)
            Config = Config or {}

            return Config.Name, Config.Flag, Config.Callback
        end,

        CreateDropdown = function(Config)
            Config = Config or {}

            return Config.Name, Config.Options, Config.Flag, Config.Callback
        end,

        CreateKeybind = function(Config)
            Config = Config or {}

            return Config.Name, Config.Default, Config.Flag, Config.Callback
        end,

        CreateLabel = function(Text)
            return Text
        end,

        Notify = function(Config)
            Config = Config or {}

            return Config.Title, Config.Content, Config.Duration
        end,

        Destroy = function()
            return nil
        end,
    },
}

--------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------

-- Selects a backend library and optionally registers method aliases.
--
-- AliasConfig maps NewName -> CanonicalName, e.g.
--   { CreateButton = "MakeButton" }
-- registers "MakeButton" as an additional way to call "CreateButton".
-- The canonical name keeps working too.
function Library:CreateLibrary(Selected, AliasConfig)
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

    Aliases[Selected] = Aliases[Selected] or {}

    if AliasConfig then
        for CanonicalName, AliasName in pairs(AliasConfig) do
            if Mappings[Selected][CanonicalName] then
                Aliases[Selected][AliasName] = CanonicalName
            else
                Helpers.Notify(
                    "Error",
                    ("Cannot alias unknown method '%s'"):format(
                        CanonicalName
                    ),
                    5
                )
            end
        end
    end

    return self
end

-- Swaps the active backend library while keeping previously registered
-- alias configs for that library name intact. Note: this only affects
-- objects created *after* the switch — windows/tabs already built are
-- bound to the previous backend.
function Library:SetLibrary(Selected)
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

    Aliases[Selected] = Aliases[Selected] or {}

    return self
end

function Library:CreateWindow(Config)
    if not Helpers.LibraryLoaded(
        "Attempt to create Window without Library"
    ) then
        return
    end

    local RawWindow = Helpers.Call(
        States.SelectedLibrary,
        "CreateWindow",
        Config
    )

    return Helpers.Wrap(RawWindow)
end

function Library:Notify(Config)
    if not Helpers.LibraryLoaded(
        "Attempt to notify without Library"
    ) then
        return
    end

    return Helpers.Call(
        States.SelectedLibrary,
        "Notify",
        Config
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

    table.clear(Values.Flags)
end

return Library
