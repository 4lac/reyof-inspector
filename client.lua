-- Reyof · github.com/4lac
-- [Reyof] reyof-inspector | كلاينت: يفتح/يقفل الصفحة الملونة

local open = false

RegisterNetEvent('reyof-inspector:client:show', function(items, counts)
    open = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'show', items = items, counts = counts })
end)

RegisterNUICallback('close', function(_, cb)
    open = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('rerun', function(_, cb)
    TriggerServerEvent('reyof-inspector:server:run')
    cb('ok')
end)

-- ESC يقفل الصفحة
CreateThread(function()
    while true do
        if open then
            if IsControlJustReleased(0, 322) then   -- ESC
                open = false
                SetNuiFocus(false, false)
                SendNUIMessage({ action = 'hide' })
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)
