# oc_khr


### OPPM Configuration

in /etc/oppm.cfg

    {
      path = "/usr",
      repos = {
        ["khronos666/oc_khr"]={
          oc_khr = {
            files = {
                ["master/core.lua"] = "/lib/khrd",
                ["master/drawing.lua"] = "/lib/khrd",
                ["master/util.lua"] = "/lib/khrd",
                ["master/khrd.lua"] = "/bin",
                ["master/khrd.cfg"] = "/etc"
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