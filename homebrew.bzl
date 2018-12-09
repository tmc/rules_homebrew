"""An implementation of brew package support for bazel."""

load("@bazel_tools//tools/build_defs/repo:git.bzl", "new_git_repository")

def _formula_is_installed(ctx, formula):
    r = ctx.execute(['brew-wrapper','ls','--versions',formula])
    if ctx.attr.verbose:
        print('[rules_homebrew]', r.return_code, r.stderr, r.stderr)
    return r.return_code == 0

def _filter_installed_packages(ctx, formulas):
    return [f for f in formulas if not _formula_is_installed(ctx, f)]

def _impl(repository_ctx):
    """Core implementation of brew_packages."""

    # necessary for bazel label addressing.
    build_file_content = ""
    repository_ctx.file("brew-wrapper", '''#!/bin/bash
set -euo pipefail
until test -f ../brew/bin/brew; do echo 'waiting for @brew'; sleep 1; done
../brew/bin/brew $*
''')
    for formula in repository_ctx.attr.formulas:
        repository_ctx.symlink("../brew/bin/%s" % formula, "%s.sh" % formula)
        build_file_content += '''
sh_binary(
    name = "%s",
    srcs = ["%s.sh"],
    visibility = ["//visibility:public"],
    deps = [ "@brew//:allfiles" ],
)
''' % (formula, formula)
    repository_ctx.file("BUILD", build_file_content)
    to_install = _filter_installed_packages(repository_ctx, repository_ctx.attr.formulas)
    if len(to_install) > 0:
        result = repository_ctx.execute([
            "./brew-wrapper",
            "install"
            ] + to_install, quiet=False)
        if repository_ctx.attr.verbose:
            print('[rules_homebrew]', result.return_code, result.stderr, result.stderr)

def repositories(branch="master"):
    new_git_repository(
        name = "brew",
        remote = "https://github.com/Homebrew/brew.git",
        branch = branch,
        build_file_content = """
sh_library(
    name = "allfiles",
    srcs = glob(["*", "**/*"]),
    visibility = ["//visibility:public"],
)""",
    )

brew_packages = repository_rule(
    implementation = _impl,
    attrs={
        "formulas": attr.string_list(mandatory=True),
        "verbose": attr.bool(),
    },
)
