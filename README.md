# oc_khr


### OPPM Configuration

in /etc/oppm.cfg

    {
      path = "/usr",
      repos = {
        ["khronos666/oc_khr"]={
          oc_khr = {
            files = {
                ["master/khrd.lua"] = "/bin",
                ["master/khrd.cfg"] = "/etc",
                ["master/core.lua"] = "/lib/khrd",
                ["master/drawing.lua"] = "/lib/khrd",
                ["master/util.lua"] = "/lib/khrd",
                ["master/modules/mod_coil_charger.lua"] = "/lib/khrd/modules",
            },
            repo = "tree/master",
            dependencies = {},
            name = "khrd - custom services",
            description = "Custom service",
            authors = "khronos666",
            hidden = true
          }
        }
      }
    }