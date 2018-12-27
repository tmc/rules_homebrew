"""An implementation of brew package support for bazel."""

def _formula_version(ctx, formula):
    r = ctx.execute(["./brew-wrapper.sh", "ls", "--versions", formula])
    if ctx.attr.verbose:
        print("[rules_homebrew]", r.return_code, r.stdout, r.stderr)
    return r.stdout.strip().split(" ")[-1]

def _formula_binaries(ctx, formula):
    r = ctx.execute(["./brew-wrapper.sh", "list", formula])
    if ctx.attr.verbose:
        print("[rules_homebrew]", r.return_code, r.stdout, r.stderr)
    binaries = [x.split("/")[-1] for x in r.stdout.splitlines() if "/bin/" in x]
    unique = {}
    for b in binaries:
        unique[b] = True
    return unique.keys()

def _formula_is_installed(ctx, formula):
    r = ctx.execute(["./brew-wrapper.sh", "ls", "--versions", formula])
    if ctx.attr.verbose:
        print("[rules_homebrew]", r.return_code, r.stdout, r.stderr)
    return r.return_code == 0

def _filter_installed_packages(ctx, formulas):
    return [f for f in formulas if not _formula_is_installed(ctx, f)]

def _brew_packages_impl(repository_ctx):
    """Core implementation of brew_packages."""

    # necessary for bazel label addressing.
    repository_ctx.template("brew-wrapper.sh", repository_ctx.attr.brew_wrappper_template)
    #repository_ctx.template("BUILD", repository_ctx.attr.build_template, executable = False)

    to_install = _filter_installed_packages(repository_ctx, repository_ctx.attr.formulas)
    extra_args = []
    if repository_ctx.attr.verbose:
        extra_args += ["--verbose"]

    # TODO(tmc): need to collect binaries
    if len(to_install) > 0:
        cmd = [
            "./brew-wrapper.sh",
            "install",
            # TODO(tmc): "--ignore-dependencies", # force our hand
        ] + to_install
        result = repository_ctx.execute(cmd, quiet = False)
        if repository_ctx.attr.verbose:
            print("[rules_homebrew]", result.return_code, result.stdout, result.stderr)
        if result.return_code != 0:
            fail("[brew_packges] " + result.stderr)

    for formula in repository_ctx.attr.formulas:
        build_file_content = '''
load("@com_github_tmc_rules_homebrew//rules:brew_package.bzl", "brew_package")

brew_package(
    name = "pkg",
    package = "{formula}",
    visibility = ["//visibility:public"],
)
'''.format(formula = formula)
        repository_ctx.file("%s/BUILD" % formula, build_file_content)

        sh_binary_template = '''
brew_binary(
    name = "{name}",
    formula = "{formula}",
    repository_name = "{repository_name}",
    deps = [':pkg'],
    visibility = ["//visibility:public"],
)
'''

        #data = ["@homebrew//:brew", "@homebrew//:library", "@homebrew//:cellar"],
        formula_version = _formula_version(repository_ctx, formula)
        binaries = "\n".join([sh_binary_template.format(
            repository_name = repository_ctx.attr.name,
            name = binary,
            formula = formula,
            version = formula_version,
        ) for binary in _formula_binaries(repository_ctx, formula)])
        build_file_content += '''
load("@com_github_tmc_rules_homebrew//rules:brew_binary.bzl", "brew_binary")

{binaries}

#filegroup(
#    name = "allfiles",
#    srcs = ["$(location @homebrew//:cellar)/{formula}/{version}/**"],
#    data = ["@homebrew//:cellar"],
#    visibility = ["//visibility:public"],
#)
'''.format(formula = formula, version = _formula_version(repository_ctx, formula), binaries = binaries)
        repository_ctx.file("%s/BUILD" % formula, build_file_content)

brew_packages = repository_rule(
    implementation = _brew_packages_impl,
    attrs = {
        "formulas": attr.string_list(mandatory = True),
        "brew_wrappper_template": attr.label(default = "//scripts:brew-wrapper.sh"),
        "build_template": attr.label(default = "//scripts:BUILD.brew_packages"),
        "verbose": attr.bool(),
    },
)
