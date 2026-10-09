-- Reyof · github.com/4lac
-- [Reyof] حقوق + قفل: لو انحذف اسم Reyof من ملفات الكود أو fxmanifest، تحذير + إيقاف.
local _a = ('Re')..('yof')
local _b = ('git')..('hub.com/')..('4lac')
local _guard = { 'server.lua', 'client.lua', 'html/app.js', 'html/index.html' }

local function _ok(t) return t ~= nil and t:find(_a,1,true) and t:find(_b,1,true) end

CreateThread(function()
    local res = GetCurrentResourceName()
    Wait(500)
    print(('^5[%s]^7 made by ^3%s^7 | ^4%s^7'):format(res, _a, _b))
    local bad
    if not _ok(LoadResourceFile(res,'fxmanifest.lua')) then bad='fxmanifest.lua' end
    if not bad then for _,f in ipairs(_guard) do if not _ok(LoadResourceFile(res,f)) then bad=f break end end end
    if not bad then return end
    CreateThread(function()
        while true do
            print('^1=====================================================^0')
            print(('^1[%s] COPYRIGHT TAMPERED^7 (%s) — by ^3%s^7 ^4%s^7'):format(res,bad,_a,_b))
            print('^1 حذف أو تعديل الحقوق ممنوع. السكربت متوقف.^0')
            print('^1=====================================================^0')
            Wait(5000)
        end
    end)
    Wait(3000)
    StopResource(res)
end)
