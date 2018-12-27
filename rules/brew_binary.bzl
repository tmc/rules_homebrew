load("@com_github_tmc_rules_homebrew//rules:toolchains.bzl", "BREW_TOOLCHAIN")

def _brew_binary_impl(ctx):
    binary = ctx.actions.declare_file(ctx.attr.name)
    ctx.actions.write(binary, ctx.expand_location("""#!/bin/bash
tar xf external/{repository_name}/{formula}/pkg.tar
exec ./bin/{name} $*
""".format(
        name = ctx.attr.name,
        formula = ctx.attr.formula,
        repository_name = ctx.attr.repository_name,
    )), is_executable = True)
    deps_files = [depset(x.files, order = "postorder") for x in ctx.attr.deps]
    all_files = depset([binary], order = "postorder", transitive = deps_files)
    return DefaultInfo(
        executable = binary,
        runfiles = ctx.runfiles(transitive_files = all_files),
    )

brew_binary = rule(
    implementation = _brew_binary_impl,
    attrs = {
        "formula": attr.string(mandatory = True),
        "repository_name": attr.string(mandatory = True),
        "deps": attr.label_list(allow_files = True),
        "data": attr.label_list(allow_files = True),
    },
    executable = True,
    toolchains = [BREW_TOOLCHAIN],
)
