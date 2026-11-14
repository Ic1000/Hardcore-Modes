local Players = game:GetService("Players")

---====== Load spawner ======---

local spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Entity%20Spawner/V2/Source.lua"))()

--- Modifier Support 
local speed = getgenv().FasterTrouble and 50 or 25

---====== Create entity ======---

local entity = spawner.Create({
    Entity = {
        Name = "Silence",
        Asset = "rbxassetid://11535812658",
        HeightOffset = 0
    },
    Lights = {
        Flicker = {
            Enabled = false,
            Duration = 1
        },
        Shatter = true,
        Repair = false
    },
    Earthquake = {
        Enabled = false
    },
    CameraShake = {
        Enabled = false,
        Range = 200,
        Values = {1.5, 20, 0.1, 1} -- Magnitude, Roughness, FadeIn, FadeOut
    },
    Movement = {
        Speed = speed,
        Delay = 0,
        Reversed = false
    },
    Rebounding = {
        Enabled = false,
        Type = "Ambush", -- "Blitz"
        Min = 1,
        Max = 1,
        Delay = 2
    },
    Damage = {
        Enabled = true,
        Range = 40,
        Amount = 125
    },
    Crucifixion = {
        Enabled = true,
        Range = 40,
        Resist = false,
        Break = true
    },
    Death = {
        Type = "Guiding", -- "Curious"
        Hints = {"You died to silence...", "Hes Really Quiet So Be Careful To His Sound!", "Hes Also Slow, So Hide Until You Dont Hear Him Anymore", "Im Sure Youll Make it!"},
        Cause = "Silence"
    }
})

---====== Debug entity ======---
entity:SetCallback("OnDespawned", function()

    
    -- KIỂM TRA ĐÃ LẤY THÀNH TỰU CHƯA (Tránh hiện lại nhiều lần)
    local player = Players.LocalPlayer
    if player and not player:FindFirstChild("SilenceAchievementUnlocked") then
        
        -- Tạo cờ đánh dấu đã nhận thành tựu thành công
        local flag = Instance.new("BoolValue")
        flag.Name = "SilenceAchievementUnlocked"
        flag.Value = true
        flag.Parent = player

        -- Gọi module trao thành tựu an toàn
        pcall(function()
            local achievementGiver = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Custom%20Achievements/Source.lua"))()

            achievementGiver({
                Title = "I Cant Hear You",
                Desc = "Soundproof!",
                Reason = "Survive Silence",
                Image = "rbxassetid://0"
            })
        end)
    end
end)

---====== Run entity ======---

entity:Run()
