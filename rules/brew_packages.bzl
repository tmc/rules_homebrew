"""An implementation of brew package support for bazel."""

def _formula_version(ctx, formula):
    r = ctx.execute(["./brew-wrapper", "ls", "--versions", formula])
    if ctx.attr.verbose:
        print("[rules_homebrew]", r.return_code, r.stdout, r.stderr)
    return r.stdout.strip().split(" ")[-1]

def _formula_binaries(ctx, formula):
    r = ctx.execute(["./brew-wrapper", "list", formula])
    if ctx.attr.verbose:
        print("[rules_homebrew]", r.return_code, r.stdout, r.stderr)
    binaries = [x.split("/")[-1] for x in r.stdout.splitlines() if "/bin/" in x]
    unique = {}
    for b in binaries:
        unique[b] = True
    return unique.keys()

def _formula_is_installed(ctx, formula):
    r = ctx.execute(["./brew-wrapper", "ls", "--versions", formula])
    if ctx.attr.verbose:
        print("[rules_homebrew]", r.return_code, r.stdout, r.stderr)
    return r.return_code == 0

def _filter_installed_packages(ctx, formulas):
    return [f for f in formulas if not _formula_is_installed(ctx, f)]

def _brew_packages_impl(repository_ctx):
    """Core implementation of brew_packages."""

    # necessary for bazel label addressing.
    repository_ctx.file("BUILD", "")

    repository_ctx.file("brew-wrapper", """#!/bin/bash
set -euo pipefail
# wait up to 20s for homebrew binary to be present
(for i in $(seq 20); do (
    test -f ../homebrew/bin/brew && break
    echo 'waiting for @homebrew'
    sleep 1
    ); done
test -f ../homebrew/bin/brew || exit 1
)

(for i in $(seq 20); do (
    test -d ../homebrew_core/.github && break
    echo 'waiting for @homebrew-core'
    sleep 1
    ); done
test -d ../homebrew_core/.github || exit 1
)
#until test -f ../homebrew/bin/brew; do echo 'waiting for @homebrew'; sleep 1; done
#until test -d ../homebrew_core/.github; do echo 'waiting for @homebrew_core'; sleep 1; done
test -d ../homebrew/Library/Taps/homebrew || mkdir -p ../homebrew/Library/Taps/homebrew
# Insert homebrew-core tap
test -L ../homebrew/Library/Taps/homebrew/homebrew-core || (
    cd ../homebrew/Library/Taps/homebrew/
    ln -s ../../../../homebrew_core homebrew-core
)
export HOMEBREW_NO_AUTO_UPDATE=1
../homebrew/bin/brew $*
""")

    to_install = _filter_installed_packages(repository_ctx, repository_ctx.attr.formulas)
    extra_args = []
    if repository_ctx.attr.verbose:
        extra_args += ["--verbose"]
    if len(to_install) > 0:
        cmd = [
            "./brew-wrapper",
            "install",
            # TODO(tmc): "--ignore-dependencies", # force our hand
        ] + to_install
        result = repository_ctx.execute(cmd, quiet = False)
        if repository_ctx.attr.verbose:
            print("[rules_homebrew]", result.return_code, result.stdout, result.stderr)
        if result.return_code != 0:
            fail("[brew_packges] " + result.stderr)

    for formula in repository_ctx.attr.formulas:
        sh_binary_template = '''
brew_binary(
    name = "{name}",
    path = "{formula}/{version}/bin/{name}",
    deps = ["@homebrew//:binaries","@homebrew_core//:allfiles","@homebrew//:allfiles", "@homebrew//:cellar"],
    data = ["@homebrew//:binaries","@homebrew_core//:allfiles","@homebrew//:allfiles", "@homebrew//:cellar"],
    visibility = ["//visibility:public"],
)
'''
        formula_version = _formula_version(repository_ctx, formula)
        binaries = "\n".join([sh_binary_template.format(
            name = binary,
            formula = formula,
            version = formula_version,
        ) for binary in _formula_binaries(repository_ctx, formula)])
        build_file_content = '''
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
        "verbose": attr.bool(),
    },
)
