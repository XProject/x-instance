fx_version  "cerulean"
use_experimental_fxv2_oal   "yes"
lua54       "yes"
game        "gta5"

name        "x-instance"
version     "0.0.0"
description "Project-X Instance"

shared_scripts {
    "shared/*.lua",
}

server_scripts {
    "server/*.lua"
}

client_scripts {
    "client/*.lua",
}