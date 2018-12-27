load(":toolchains.bzl", "BREW_TOOLCHAIN", "homebrew_toolchain_info")

homebrew_toolchain_info(
    name = "homebrew_toolchain_info/homebrew",
    compiler = "@com_github_tmc_rules_homebrew//:homebrew_compiler",
    plt = "homebrew",
    visibility = ["//visibility:public"],
)

homebrew_toolchain_info(
    name = "homebrew_toolchain_info/linuxbrew",
    compiler = "@com_github_tmc_rules_homebrew//:linuxbrew_compiler",
    plt = "linuxbrew",
)

toolchain(
    name = "homebrew",
    exec_compatible_with = [
        "@bazel_tools//platforms:osx",
    ],
    target_compatible_with = [
        "@bazel_tools//platforms:osx",
    ],
    toolchain = ":homebrew_toolchain_info/homebrew",
    toolchain_type = BREW_TOOLCHAIN,
)

toolchain(
    name = "linuxbrew",
    exec_compatible_with = [
        "@bazel_tools//platforms:linux",
    ],
    target_compatible_with = [
        "@bazel_tools//platforms:linux",
    ],
    toolchain = ":homebrew_toolchain_info/linuxbrew",
    toolchain_type = BREW_TOOLCHAIN,
)
