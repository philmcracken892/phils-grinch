
local RSGCore = exports['rsg-core']:GetCoreObject()
local grinchPed = nil
local grinchBlip = nil
local grinchDead = false


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if grinchPed and DoesEntityExist(grinchPed) then
            DeletePed(grinchPed)
        end
        if grinchBlip and DoesBlipExist(grinchBlip) then
            RemoveBlip(grinchBlip)
        end
    end
end)


RegisterNetEvent('grinch:notify', function(data)
    lib.notify({
        title = data.title,
        description = data.description,
        type = data.type,
        duration = data.duration or 5000,
        position = 'top'
    })
end)


local function EnsureGrinchVisible(ped)
    if not DoesEntityExist(ped) then return end
    Citizen.InvokeNative(0x704C908E9C405136, ped) 
    SetEntityVisible(ped, true)
    SetEntityAlpha(ped, 255, false)
end


local function GetFleeCoords(pedCoords, playerCoords, fleeDistance)
    local heading = GetHeadingFromVector_2d(pedCoords.x - playerCoords.x, pedCoords.y - playerCoords.y)
    local rad = math.rad(heading)
    
    local fleeX = pedCoords.x + (math.sin(rad) * fleeDistance)
    local fleeY = pedCoords.y + (math.cos(rad) * fleeDistance)
    
    local _, fleeZ = GetGroundZFor_3dCoord(fleeX, fleeY, pedCoords.z + 100.0, true)
    
    return vector3(fleeX, fleeY, fleeZ or pedCoords.z)
end


RegisterNetEvent('grinch:spawn', function(location)
    
    if grinchPed and DoesEntityExist(grinchPed) then
        DeletePed(grinchPed)
    end
    if grinchBlip and DoesBlipExist(grinchBlip) then
        RemoveBlip(grinchBlip)
    end
    
    grinchDead = false
    
   
    local model = GetHashKey("re_darkalleystabbing_males_01")
    RequestModel(model)
    while not HasModelLoaded(model) do 
        Wait(100) 
    end
    
    
    
   
    grinchPed = CreatePed(model, location.coords.x, location.coords.y, location.coords.z, location.coords.w, true, true)
    
   
    local timeout = 0
    while not DoesEntityExist(grinchPed) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not DoesEntityExist(grinchPed) then
        
        return
    end
    
    
    Citizen.InvokeNative(0x283978A15512B2FE, grinchPed, true) 
    Wait(200) 
    Citizen.InvokeNative(0x704C908E9C405136, grinchPed) 
    Citizen.InvokeNative(0xCC8CA3E88256E58F, grinchPed, false, true, true, true, false) -- SetPedToLoadCover
    SetEntityVisible(grinchPed, true)
    SetEntityAlpha(grinchPed, 255, false)
    
   
    SetEntityAsMissionEntity(grinchPed, true, true)
    SetEntityCanBeDamaged(grinchPed, true)
    SetPedCanRagdoll(grinchPed, true)
    SetBlockingOfNonTemporaryEvents(grinchPed, false)
    SetEntityInvincible(grinchPed, false)
    
    
    
   
    SetPedRelationshipGroupHash(grinchPed, GetHashKey("PLAYER_DISLIKE"))
    SetPedCombatAttributes(grinchPed, 1, true)
    SetPedCombatAttributes(grinchPed, 46, false)
    SetPedCombatAttributes(grinchPed, 5, true)
    SetPedCombatAbility(grinchPed, 0)
    SetPedFleeAttributes(grinchPed, 0, false)
    SetPedFleeAttributes(grinchPed, 512, false)
    
   
    SetPedMoveRateOverride(grinchPed, 1.8)
    
    
    TaskWanderStandard(grinchPed, 10.0, 10)
    
   
    Wait(500)
    
    
    if DoesEntityExist(grinchPed) then
        grinchBlip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, 0x318C617C, grinchPed)
        SetBlipSprite(grinchBlip, joaat("blip_ambient_gang_leader"), true)
        BlipAddModifier(grinchBlip, joaat('BLIP_MODIFIER_MP_COLOR_8')) 
        Citizen.InvokeNative(0x9CB1A1623062F402, grinchBlip, "The Grinch")
        
        
    end
    
    
    lib.notify({
        title = '📍 GRINCH LOCATED',
        description = 'The Grinch is running around near **' .. location.area .. '**!\nHe will try to escape!',
        type = 'error',
        duration = 10000,
        position = 'top'
    })
    
   
    CreateThread(function()
        while grinchPed and DoesEntityExist(grinchPed) and not grinchDead do
            Wait(2000) 
            EnsureGrinchVisible(grinchPed)
        end
    end)
    
    
    CreateThread(function()
        local lastTaunt = 0
        local lastFleeUpdate = 0
        local fleeRange = 60.0
        local isCurrentlyFleeing = false
        
        while grinchPed and DoesEntityExist(grinchPed) and not grinchDead do
            Wait(500)
            
            if not IsPedDeadOrDying(grinchPed, true) then
                local grinchCoords = GetEntityCoords(grinchPed)
                local nearestPlayer = nil
                local nearestDistance = fleeRange
                
                
                local players = GetActivePlayers()
                for _, playerId in ipairs(players) do
                    local playerPed = GetPlayerPed(playerId)
                    local playerCoords = GetEntityCoords(playerPed)
                    local distance = #(grinchCoords - playerCoords)
                    
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestPlayer = playerPed
                    end
                end
                
                
                if nearestPlayer then
                    local playerCoords = GetEntityCoords(nearestPlayer)
                    
                    if not isCurrentlyFleeing then
                        
                        isCurrentlyFleeing = true
                    end
                    
                    
                    if GetGameTimer() - lastFleeUpdate > 2000 then
                        local fleePoint = GetFleeCoords(grinchCoords, playerCoords, 80.0)
                        
                        ClearPedTasks(grinchPed)
                        TaskGoStraightToCoord(grinchPed, fleePoint.x, fleePoint.y, fleePoint.z, 3.0, -1, 0.0, 0.0)
                        
                       
                        Citizen.InvokeNative(0x0DF7692B1D9E7BA7, grinchPed, 3, 1)
                        
                       
                        Wait(100)
                        EnsureGrinchVisible(grinchPed)
                        
                        lastFleeUpdate = GetGameTimer()
                    end
                    
                    
                    if GetGameTimer() - lastTaunt > 8000 then
                        PlayPedAmbientSpeechNative(grinchPed, "GET_LOST", "SPEECH_PARAMS_FORCE_SHOUTED")
                        lastTaunt = GetGameTimer()
                    end
                else
                    
                    if isCurrentlyFleeing then
                        
                        isCurrentlyFleeing = false
                        ClearPedTasks(grinchPed)
                        TaskWanderStandard(grinchPed, 10.0, 10)
                        
                       
                        Wait(100)
                        EnsureGrinchVisible(grinchPed)
                    end
                end
            end
        end
    end)
    
   
    CreateThread(function()
        while grinchPed and DoesEntityExist(grinchPed) and not grinchDead do
            Wait(500)
            
            local health = GetEntityHealth(grinchPed)
            
            if health <= 0 or IsPedDeadOrDying(grinchPed, true) then
                grinchDead = true
                
                
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local grinchCoords = GetEntityCoords(grinchPed)
                local distance = #(playerCoords - grinchCoords)
                
                
                
                if distance < 150.0 then
                   
                    TriggerServerEvent('grinch:killed')
                    
                    lib.notify({
                        title = '🎯 KILL CONFIRMED',
                        description = 'You shot the Grinch! Collecting bounty...',
                        type = 'success',
                        duration = 5000,
                        position = 'top'
                    })
                else
                    
                end
                break
            end
        end
    end)
    
    SetModelAsNoLongerNeeded(model)
end)


RegisterNetEvent('grinch:despawn', function()
    if grinchPed and DoesEntityExist(grinchPed) then
        DeletePed(grinchPed)
        grinchPed = nil
    end
    
    if grinchBlip and DoesBlipExist(grinchBlip) then
        RemoveBlip(grinchBlip)
        grinchBlip = nil
    end
    
    grinchDead = false
    
end)