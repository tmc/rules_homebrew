def _brew_binary_impl(ctx):
    binary = ctx.actions.declare_file(ctx.attr.name)
    ctx.actions.write(binary, ctx.expand_location("""#!/bin/bash
exec $(location @homebrew//:cellar)/{path} $*
""".format(path = ctx.attr.path, name = ctx.attr.name)), is_executable = True)
    deps_files = [depset(x.files, order = "postorder") for x in ctx.attr.deps]
    all_files = depset([binary], order = "postorder", transitive = deps_files)
    return DefaultInfo(
        executable = binary,
        runfiles = ctx.runfiles(transitive_files = all_files),
    )

brew_binary = rule(
    implementation = _brew_binary_impl,
    attrs = {
        "path": attr.string(mandatory = True),
        "deps": attr.label_list(allow_files = True),
        "data": attr.label_list(allow_files = True),
    },
    executable = True,
)
