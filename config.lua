-- Reyof · github.com/4lac
-- [Reyof] reyof-inspector | الإعدادات
Config = {}

-- من يقدر يفتح الفحص داخل اللعبة (صلاحيات ACE). الكونسول دايم مسموح.
Config.AdminAces = { 'command', 'group.admin', 'group.god', 'qbcore.admin', 'qbcore.god', 'admin' }

-- أيدي ديسكورد لهم صلاحية كاملة (اختياري). حط أيديك بين ''
Config.AdminDiscord = {
    -- '000000000000000000',
}

Config.Command = 'inspector'   -- الأمر داخل اللعبة: /inspector  (وبرضو /inspect)
Config.AutoRunSeconds = 20     -- يطبع تقرير مختصر في الكونسول بعد كم ثانية من التشغيل (0 = لا)

-- الأساسيات اللي يتوقعها أغلب السيرفرات (يحذّر لو مفقودة)
Config.Expect = {
    cores        = { 'qb-core', 'qbx_core', 'es_extended', 'mt_core', 'ND_Core', 'ox_core', 'vrp' },
    inventories  = { 'ox_inventory', 'qb-inventory', 'ps-inventory', 'qs-inventory', 'lj-inventory', 'mt_inventory', 'codem-inventory' },
    targets      = { 'ox_target', 'qb-target', 'qtarget', 'bt-target' },
    libs         = { 'ox_lib' },
    sql          = { 'oxmysql', 'mysql-async', 'ghmattimysql' },
}

-- نصوص تدل على استدعاء إطار معين داخل ملفات السكربت (لكشف التعارض)
-- المفتاح = اسم الإطار | القيمة = نصوص لو وُجدت في سكربت معناه يعتمد عليه
Config.FrameworkHints = {
    ['qb-core']    = { "exports['qb-core']", 'QBCore.Functions', 'qb-core:GetCoreObject', "TriggerEvent('QBCore" },
    ['es_extended']= { "exports['es_extended']", 'ESX.GetPlayerFromId', 'esx:getSharedObject', 'getSharedObject' },
    ['qbx_core']   = { "exports['qbx_core']", 'exports.qbx_core' },
    ['mt_core']    = { "exports['mt_core']", 'exports.mt_core' },
}
