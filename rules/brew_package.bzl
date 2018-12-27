load("@com_github_tmc_rules_homebrew//rules:toolchains.bzl", "BREW_TOOLCHAIN")

def _brew_package_impl(ctx):
    #package = ctx.actions.declare_file(ctx.attr.name)
    tc = ctx.toolchains[BREW_TOOLCHAIN]
    tarball_filename = "%s.tar" % ctx.attr.name
    print("toolchain:", tc)
    output = ctx.outputs.out
    #tarball = ctx.actions.declare_file(output)
    #deps_files = depset(ctx.attr._brew_library.files)
    #all_files = depset([tarball], order = "postorder", transitive = deps_files)

    cmd_raw = "pwd; $(location %s) %s %s %s" % (
        tc.compiler.label,
        ctx.executable._brew_binary.path,
        ctx.attr.package,
        output.path,
    )
    inputs, cmd, input_manifests = ctx.resolve_command(
        command = cmd_raw,
        expand_locations = True,
        tools = [tc.compiler],
    )
    print(inputs, cmd, input_manifests)

    #cmd = 'tree'
    #ctx.actions.run(
    #    executable = tc.compiler.files.to_list()[0].path,
    #    outputs = [output],
    #    tools = tc.compiler.files,
    #    arguments = ["$(location @homebrew//:brew)", ctx.attr.package ],
    #)
    print(ctx.executable)
    ctx.actions.run_shell(
        #inputs = ctx.attr._brew_library.files,
        inputs = [],
        outputs = [output],
        progress_message = "Building %s" % ctx.attr.name,
        command = cmd,
        #tools = [tc.compiler.files.to_list()[0]],
        #tools = tc.compiler.files + depset(ctx.attr._brew_binary),
        tools = [tc.compiler.files.to_list()[1], ctx.executable._brew_binary],
        # TODO(tmc): use toolchain compiler
        # command = "{brew_cmd} install {name}; date > {output}".format(
        #     brew_cmd = tc.compiler,
        #     name = ctx.attr.name,
        #     output = output.path,
        # )
    )
    return DefaultInfo(
    )
    # ctx.actions.write(package, ctx.expand_location("""#!/bin/bash

# exec $(location @homebrew//:cellar)/{path} $*
# """.format(path = ctx.attr.path, name = ctx.attr.name)), is_executable = True)
# deps_files = [depset(x.files, order = "postorder") for x in ctx.attr.deps]
# all_files = depset([package], order = "postorder", transitive = deps_files)
# return DefaultInfo(
#     runfiles = ctx.runfiles(transitive_files = all_files),
# )

brew_package = rule(
    implementation = _brew_package_impl,
    attrs = {
        "package": attr.string(mandatory = True),
        "srcs": attr.label_list(allow_files = True),
        #"data": attr.label_list(allow_files = True),
        "_brew_library": attr.label(default = "@homebrew//:library"),
        "_brew_binary": attr.label(
            default = "@homebrew//:brew",
            executable = True,
            cfg = "host",
        ),
    },
    outputs = {"out": "%{name}.tar"},
    toolchains = [BREW_TOOLCHAIN],
)
