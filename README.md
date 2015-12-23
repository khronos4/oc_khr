# oc_khr


### OPPM Configuration

in /etc/oppm.cfg

    {
      path="/usr",
      repos={
        ["OpenPrograms/samis-Programs"]={
        ["nidus"] = {
        ["files"] = {
            ["master/oc_khr/core.lua] = "/lib/khrd",
            ["master/oc_khr/khrd.lua"] = "/bin",
            ["master/oc_khr/khrd.cfg"] = "/etc"
        },
        ["repo"] = "tree/master/oc_khr",
        ["dependencies"] = {},
        ["name"] = "khrd - custom services",
        ["description"] = "Custom service",
        ["authors"] = "khronos666"
        },
        }
      }
    }