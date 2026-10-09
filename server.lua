-- Reyof · github.com/4lac
-- [Reyof] reyof-inspector | الفحص الشامل (سيرفر)
-- يفحص أي سيرفر FiveM: الكور، الأساسيات، الاعتماديات، التعارضات، المانفست، الداتابيس.

local INForm = ('Re')..('yof')   -- يُستخدم بالقفل بالأسفل

------------------------------------------------------------
-- أدوات مساعدة
------------------------------------------------------------
local function state(r) return GetResourceState(r) end
local function started(r) return state(r) == 'started' end

-- كل الموارد في السيرفر
local function allResources()
    local list = {}
    for i = 0, GetNumResources() - 1 do
        local r = GetResourceByFindIndex(i)
        if r then list[#list + 1] = r end
    end
    table.sort(list)
    return list
end

-- أول واحد شغّال من قائمة
local function firstStarted(list)
    for _, r in ipairs(list) do if started(r) then return r end end
end

-- كل الشغّالين من قائمة
local function allStarted(list)
    local out = {}
    for _, r in ipairs(list) do if started(r) then out[#out + 1] = r end end
    return out
end

-- قراءة قيمة meta (مثل fx_version أو dependency)
local function meta(res, key, i)
    return GetResourceMetadata(res, key, i or 0)
end
local function metaAll(res, key)
    local out, n = {}, GetNumResourceMetadata(res, key) or 0
    for i = 0, n - 1 do out[#out + 1] = GetResourceMetadata(res, key, i) end
    return out
end

-- ملفات السكربت المذكورة في المانفست (عشان نقراها ونكشف الإطار)
local function scriptFiles(res)
    local files = {}
    for _, key in ipairs({ 'client_script', 'client_scripts', 'server_script', 'server_scripts', 'shared_script', 'shared_scripts' }) do
        for _, f in ipairs(metaAll(res, key)) do
            if f:sub(1, 1) ~= '@' and f:find('%.lua$') and not f:find('%*') then files[#files + 1] = f end
        end
    end
    return files
end

------------------------------------------------------------
-- بناء التقرير
------------------------------------------------------------
local function newReport()
    local R = { items = {}, ok = 0, warn = 0, fail = 0 }
    function R:add(level, section, msg, fix)
        if level == 'ok' then self.ok = self.ok + 1
        elseif level == 'warn' then self.warn = self.warn + 1
        else self.fail = self.fail + 1 end
        self.items[#self.items + 1] = { level = level, section = section, msg = msg, fix = fix }
    end
    return R
end

------------------------------------------------------------
-- الفحوصات
------------------------------------------------------------
local function inspect()
    local R = newReport()
    local res = allResources()

    ------------------------------------------------------------
    -- 1) الكور (وتعارضه)
    ------------------------------------------------------------
    local cores = allStarted(Config.Expect.cores)
    if #cores == 0 then
        R:add('fail', 'Core', 'ما فيه أي كور شغّال', 'شغّل الكور حقك (qb-core / es_extended / qbx_core ...)')
    elseif #cores == 1 then
        R:add('ok', 'Core', 'الكور: ' .. cores[1])
    else
        R:add('fail', 'Core', 'أكثر من كور شغّال: ' .. table.concat(cores, ', '), 'خلّ كور واحد بس شغّال، الباقي احذفه أو أوقفه')
    end
    local coreNow = cores[1]

    ------------------------------------------------------------
    -- 2) الأساسيات
    ------------------------------------------------------------
    local function expectOne(label, list, how)
        local found = allStarted(list)
        if #found == 0 then
            R:add(how or 'warn', 'Essentials', label .. ': ما فيه شي شغّال', 'ensure ' .. list[1] .. ' (أو البديل اللي تستخدمه)')
        elseif #found == 1 then
            R:add('ok', 'Essentials', label .. ': ' .. found[1])
        else
            R:add('warn', 'Essentials', label .. ': أكثر من واحد شغّال (' .. table.concat(found, ', ') .. ')', 'الأفضل تخلي واحد بس')
        end
    end
    expectOne('المكتبة (ox_lib)', Config.Expect.libs, 'warn')
    expectOne('الداتابيس (oxmysql)', Config.Expect.sql, 'fail')
    expectOne('التارقت', Config.Expect.targets, 'warn')
    expectOne('الإنفنتوري', Config.Expect.inventories, 'warn')

    ------------------------------------------------------------
    -- 3) حالة الموارد (missing / error / stopped) + مانفست قديم + مجلد جوّه مجلد
    ------------------------------------------------------------
    local errored, oldManifest = 0, 0
    for _, r in ipairs(res) do
        local st = state(r)
        if st == 'missing' then
            R:add('fail', 'Resources', r .. ' مذكور بس غير موجود (missing)', 'اسم المجلد غلط أو fxmanifest مو في جذره')
        elseif st ~= 'started' and st ~= 'stopped' and st ~= 'stopping' and st ~= 'starting' then
            -- حالات مثل error / uninitialized
            R:add('fail', 'Resources', r .. ' حالته: ' .. st, 'شوف الكونسول: فيه خطأ أحمر عند تشغيله')
            errored = errored + 1
        end
        -- مانفست قديم
        local fx = meta(r, 'fx_version')
        local hasOld = LoadResourceFile(r, '__resource.lua')
        if hasOld and not LoadResourceFile(r, 'fxmanifest.lua') then
            R:add('warn', 'Manifest', r .. ' يستخدم __resource.lua القديم', 'حدّثه لـ fxmanifest.lua')
            oldManifest = oldManifest + 1
        elseif fx and (fx == 'adamant' or fx == 'bodacious') then
            R:add('warn', 'Manifest', r .. " fx_version قديم ('" .. fx .. "')", "استخدم fx_version 'cerulean'")
            oldManifest = oldManifest + 1
        end
    end
    if errored == 0 then R:add('ok', 'Resources', 'ما فيه مورد حالته error') end
    if oldManifest == 0 then R:add('ok', 'Manifest', 'كل المانفستات حديثة') end

    ------------------------------------------------------------
    -- 4) الاعتماديات (dependencies) الناقصة
    ------------------------------------------------------------
    local depMiss = 0
    for _, r in ipairs(res) do
        if started(r) then
            for _, dep in ipairs(metaAll(r, 'dependency')) do
                if dep:sub(1, 1) ~= '/' and not started(dep) then
                    R:add('fail', 'Dependencies', r .. ' يحتاج "' .. dep .. '" وهو مو شغّال', 'ensure ' .. dep .. ' قبل ' .. r)
                    depMiss = depMiss + 1
                end
            end
        end
    end
    if depMiss == 0 then R:add('ok', 'Dependencies', 'كل الاعتماديات المعلنة موجودة') end

    ------------------------------------------------------------
    -- 5) تعارض الإطار: سكربت يستدعي كور مختلف عن الكور الشغّال
    ------------------------------------------------------------
    local conflicts, scanned = 0, 0
    for _, r in ipairs(res) do
        if started(r) and r ~= GetCurrentResourceName() then
            local uses = {}
            local files = scriptFiles(r)
            for i = 1, math.min(#files, 12) do           -- حد أقصى 12 ملف للمورد
                local txt = LoadResourceFile(r, files[i])
                if txt then
                    for fw, hints in pairs(Config.FrameworkHints) do
                        if not uses[fw] then
                            for _, h in ipairs(hints) do
                                if txt:find(h, 1, true) then uses[fw] = true break end
                            end
                        end
                    end
                end
            end
            scanned = scanned + 1
            -- لو يستدعي إطار غير الكور الشغّال، وما يستدعي الكور الشغّال
            if coreNow then
                for fw in pairs(uses) do
                    if fw ~= coreNow and not uses[coreNow] and not started(fw) then
                        R:add('warn', 'Framework', r .. ' يعتمد على "' .. fw .. '" والسيرفر على "' .. coreNow .. '"',
                            'هذا السكربت لإطار مختلف — تحتاج نسخة تدعم ' .. coreNow .. ' أو جسر (bridge)')
                        conflicts = conflicts + 1
                    end
                end
            end
        end
    end
    if conflicts == 0 then R:add('ok', 'Framework', ('فحصت %d مورد — ما فيه تعارض إطار واضح'):format(scanned)) end

    ------------------------------------------------------------
    -- 6) الداتابيس
    ------------------------------------------------------------
    if firstStarted(Config.Expect.sql) then
        local s, err = pcall(function() return MySQL.query.await('SELECT 1 AS ok') end)
        if s then R:add('ok', 'Database', 'الاتصال بقاعدة البيانات شغّال')
        else R:add('fail', 'Database', 'فشل الاتصال بقاعدة البيانات', tostring(err):sub(1, 160)) end
    else
        R:add('warn', 'Database', 'ما فيه سكربت SQL شغّال — ما قدرت أفحص الاتصال')
    end

    ------------------------------------------------------------
    -- 7) ملخص عام
    ------------------------------------------------------------
    R:add('ok', 'Summary', ('إجمالي الموارد في السيرفر: %d'):format(#res))
    R:add('ok', 'ملاحظة', 'هذي الأداة تمسك مشاكل التركيب والاعتماديات والتعارضات اللي الكونسول ما يوضحها. أخطاء الكود اللي تطلع حمراء في الكونسول راجعها هناك.')

    return R
end

------------------------------------------------------------
-- طباعة في الكونسول
------------------------------------------------------------
local COL = { ok = '^2', warn = '^3', fail = '^1' }
local TAG = { ok = '[OK]  ', warn = '[WARN]', fail = '[FAIL]' }
local function printReport(R)
    print('^5======== REYOF INSPECTOR ========^0')
    for _, it in ipairs(R.items) do
        print(('%s  %s^0 [%s] %s'):format(COL[it.level], TAG[it.level], it.section, it.msg))
        if it.fix and it.level ~= 'ok' then print('^0            -> ' .. it.fix) end
    end
    print(('^5== النتيجة: ^2%d سليم^5 | ^3%d تحذير^5 | ^1%d خطأ^5 =='):format(R.ok, R.warn, R.fail))
    print('^5   by Reyof · github.com/4lac^0')
end

------------------------------------------------------------
-- صلاحيات
------------------------------------------------------------
local function isDiscordAdmin(src)
    local list = Config.AdminDiscord or {}
    if #list == 0 then return false end
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, 8) == 'discord:' then
            for _, a in ipairs(list) do if tostring(a) == id:sub(9) then return true end end
        end
    end
    return false
end
local function isAdmin(src)
    if src == 0 then return true end
    if isDiscordAdmin(src) then return true end
    for _, ace in ipairs(Config.AdminAces or {}) do
        if IsPlayerAceAllowed(src, ace) then return true end
    end
    return false
end

------------------------------------------------------------
-- الأمر + الكولباك للصفحة
------------------------------------------------------------
lib_run = inspect   -- داخلي

RegisterNetEvent('reyof-inspector:server:run', function()
    local src = source
    if not isAdmin(src) then return end
    local R = inspect()
    TriggerClientEvent('reyof-inspector:client:show', src, R.items, { ok = R.ok, warn = R.warn, fail = R.fail })
end)

local function runCmd(src)
    if not isAdmin(src) then
        if src ~= 0 then TriggerClientEvent('chat:addMessage', src, { args = { 'Inspector', 'ما عندك صلاحية' } }) end
        return
    end
    local R = inspect()
    if src == 0 then
        printReport(R)
    else
        TriggerClientEvent('reyof-inspector:client:show', src, R.items, { ok = R.ok, warn = R.warn, fail = R.fail })
    end
end

RegisterCommand(Config.Command or 'inspector', function(src) runCmd(src) end, false)
RegisterCommand('inspect', function(src) runCmd(src) end, false)

-- طباعة مختصرة تلقائية في الكونسول عند الإقلاع
CreateThread(function()
    local wait = tonumber(Config.AutoRunSeconds) or 0
    if wait <= 0 then return end
    Wait(wait * 1000)
    printReport(inspect())
end)
