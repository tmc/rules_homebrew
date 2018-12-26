def _brew_pkg_impl(repository_ctx):
    repository_ctx.file("BUILD", '''
sh_library(
    name = "pkg",
    srcs = glob(["*", "**/*"]),
    visibility = ["//visibility:public"],
)
''')

# internal
brew_pkg = repository_rule(
    implementation = _brew_pkg_impl,
    attrs = {
        "formula": attr.string(mandatory = True),
        "brew_packages_bzl": attr.string(),
        "verbose": attr.bool(),
    },
)
