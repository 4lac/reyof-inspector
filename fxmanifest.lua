-- Reyof · github.com/4lac
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'reyof-inspector'
author 'Reyof (github.com/4lac)'
description 'فحص شامل لأي سيرفر FiveM — الكور، الاعتماديات، التعارضات، الداتابيس — بصفحة ملونة'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/credit.js',
}

shared_script 'config.lua'

client_script 'client.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

-- Reyof · github.com/4lac
server_script 'credits.lua'
