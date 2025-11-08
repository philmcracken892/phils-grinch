

local RSGCore = exports['rsg-core']:GetCoreObject()

local grinchActive = false
local grinchLocation = nil
local grinchReward = 0
local currentHunters = {}


local grinchSpots = {
    {coords = vector4(-302.41, 790.43, 118.0, 98.79), area = "Valentine"},
    {coords = vector4(2700.19, -1408.83, 46.62, 89.1), area = "St Denis"},
    {coords = vector4(-5510.92, -2936.99, -1.94, 213.54), area = "Tumbleweed"},
    {coords = vector4(1346.98, -1312.09, 76.53, 340.0), area = "Rhodes"},
    {coords = vector4(-844.04, -1253.15, 43.32, 98.8), area = "Blackwater"}
}


RegisterCommand('startgrinch', function(source, args)
    if source == 0 or RSGCore.Functions.HasPermission(source, 'admin') then
        StartGrinchEvent()
    end
end)

function StartGrinchEvent()
    if grinchActive then return end
    
    grinchActive = true
    grinchLocation = grinchSpots[math.random(#grinchSpots)]
    grinchReward = math.random(500, 2000)
    currentHunters = {}
    
    
    TriggerClientEvent('grinch:notify', -1, {
        title = '🎄 GRINCH ALERT!',
        description = 'The Grinch has been spotted stealing present and is near **' .. grinchLocation.area .. '**!\n💰 Bounty: $' .. grinchReward,
        type = 'error',
        duration = 10000
    })
    
    
    TriggerClientEvent('grinch:spawn', -1, grinchLocation)
    
    
    SetTimeout(900000, function()
        if grinchActive then
            EndGrinchEvent(false)
        end
    end)
end


RegisterNetEvent('grinch:killed', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not grinchActive then 
        
        return 
    end
    
    if currentHunters[src] then 
        
        return 
    end
    
    currentHunters[src] = true
    
   
    local rewardAmount = math.random(200, 500)
    Player.Functions.AddMoney('cash', rewardAmount)
    
   
    local items = {'apple', 'bread', 'coffee'}
    local randomItem = items[math.random(#items)]
    local itemAmount = math.random(1, 5)
    Player.Functions.AddItem(randomItem, itemAmount)
    
   
    
    
    TriggerClientEvent('grinch:notify', src, {
        title = '🎁 GRINCH CAPTURED!',
        description = 'You caught the Grinch!\n💰 Reward: $' .. rewardAmount .. '\n📦 ' .. itemAmount .. 'x ' .. randomItem,
        type = 'success',
        duration = 8000
    })
    
    
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    TriggerClientEvent('grinch:notify', -1, {
        title = '🎄 GRINCH CAUGHT!',
        description = '**' .. playerName .. '** caught the Grinch!',
        type = 'success',
        duration = 8000
    })
    
    
    EndGrinchEvent(true)
end)

function EndGrinchEvent(caught)
    grinchActive = false
    TriggerClientEvent('grinch:despawn', -1)
    
    if not caught then
        TriggerClientEvent('grinch:notify', -1, {
            title = '🎄 GRINCH ESCAPED',
            description = 'The Grinch got away! Better luck next time...',
            type = 'warning',
            duration = 8000
        })
    end
    
    
    SetTimeout(math.random(1800000, 3600000), function()
        StartGrinchEvent()
    end)
end


