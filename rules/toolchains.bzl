load("@com_github_tmc_rules_homebrew//rules:providers.bzl", "BrewSDK")
BREW_TOOLCHAIN = "@com_github_tmc_rules_homebrew//:toolchain_type"

def _homebrew_toolchain_info(ctx):
    return [
        platform_common.ToolchainInfo(
            compiler = ctx.attr.compiler,
            #cflags = ctx.attr.cflags,
            # TODO(tmc): do we need any other fields here?
            plt = ctx.attr.plt,
        ),
    ]

homebrew_toolchain_info = rule(
    _homebrew_toolchain_info,
    attrs = {
        "compiler": attr.label(
            executable = True,
            default = "//:homebrew_compiler",
            cfg = "host",
        ),
        "plt": attr.string(),
    },
)

def homebrew_register_toolchains():
    native.register_toolchains(
        "@com_github_tmc_rules_homebrew//rules:homebrew",
        "@com_github_tmc_rules_homebrew//rules:linuxbrew",
    )

