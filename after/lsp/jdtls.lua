local java17 = "/Users/bytedance/Library/Java/JavaVirtualMachines/azul-17.0.19/Contents/Home"
local java21 = "/Users/bytedance/Library/Java/JavaVirtualMachines/azul-21.0.2/Contents/Home"

return {
  cmd_env = {
    JAVA_HOME = java21,
  },
  settings = {
    java = {
      import = {
        gradle = {
          java = {
            home = java17,
          },
        },
      },
      configuration = {
        runtimes = {
          {
            name = "JavaSE-17",
            path = java17,
            default = true,
          },
        },
      },
    },
  },
}
