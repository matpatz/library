local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/matpatz/library/refs/heads/main/main.luau"))()

local Rayfield = Library:CreateLibrary("Rayfield", {
    CreateWindow = CreateWindow, -- Say Kavo ui uses  MakeWindow, but you want to use Rayfield's CreateWindow instead. This allows you to call CreateWindow rather than MakeWindow when creating a window.
    CreateButton = MakeButton, -- Allows the user to call MakeButton rather than CreateButton when creating a button.
})
-- CreateButton is the global funciton for creating a ui library, find it here: https://github.com/matpatz/library/tree/main

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
    Callback = function()
    end,
})

Library:SetLibrary("Kavo") -- The config remains the same, but a new Kavo ui has taken the place of Rayfield. This could be useful if you want to use a different ui library for your script, or user config.
