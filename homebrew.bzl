"""An implementation of brew package support for bazel."""

load("@bazel_tools//tools/build_defs/repo:git.bzl", "new_git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")


def _formula_is_installed(ctx, formula):
    r = ctx.execute(['./brew-wrapper','ls','--versions',formula])
    if ctx.attr.verbose:
        print('[rules_homebrew]', r.return_code, r.stdout, r.stderr)
    return r.return_code == 0

def _filter_installed_packages(ctx, formulas):
    return [f for f in formulas if not _formula_is_installed(ctx, f)]

def _impl(repository_ctx):
    """Core implementation of brew_packages."""

    # necessary for bazel label addressing.
    repository_ctx.file("brew-wrapper", '''#!/bin/bash
set -euo pipefail
until test -f ../brew/bin/brew; do echo 'waiting for @brew'; sleep 1; done
until test -d ../homebrew_core/.github; do echo 'waiting for @homebrew_core'; sleep 1; done
test -d  ../brew/Library/Taps/homebrew || mkdir -p ../brew/Library/Taps/homebrew
# Insert homebrew-core tap
test -d ../brew/Library/Taps/homebrew/homebrew-core || (
    cd ../brew/Library/Taps/homebrew/
    ln -s ../../../../homebrew_core/ homebrew-core
)
export HOMEBREW_NO_AUTO_UPDATE=1
../brew/bin/brew $*
''')

    #repository_ctx.symlink("../homebrew_core", "../brew/Library/Taps/homebrew/homebrew-core")
    build_file_content = ""
    for formula in repository_ctx.attr.formulas:
        repository_ctx.symlink("../brew/bin/%s" % formula, "%s.sh" % formula)
        build_file_content += '''
sh_binary(
    name = "%s",
    srcs = ["%s.sh"],
    visibility = ["//visibility:public"],
    deps = [ "@brew//:binaries" ],
)
''' % (formula, formula)
    repository_ctx.file("BUILD", build_file_content)

    to_install = _filter_installed_packages(repository_ctx, repository_ctx.attr.formulas)
    extra_args = []
    if repository_ctx.attr.verbose:
        extra_args += "--verbose"
    if len(to_install) > 0:
        result = repository_ctx.execute([
            "./brew-wrapper",
            "install"
            ] + to_install, quiet=False)
        if repository_ctx.attr.verbose:
            print('[rules_homebrew]', result.return_code, result.stdout, result.stderr)
        if result.return_code != 0:
            fail("[brew_packges] " + result.stderr)

def repositories(brew_tag="1.8.5", brew_sha256="3f2c429cc6416ee9c45500d8f5d3e1c8e9876422a2906888e31303213c167a11",
                 homebrew_core_commit="e963aa704fe743f54d34bff943aaed7a0175f668", homebrew_core_sha256="3f2c429cc6416ee9c45500d8f5d3e1c8e9876422a2906888e31303213c167a11"):
    http_archive(
        name = "brew",
        urls = [
            "https://github.com/Homebrew/brew/archive/%s.tar.gz" % brew_tag,
        ],
        sha256 = "b1c22277192fc1cb834f07466d19f678a628b890f6a1efc64e368b8cc7218ba6",
        strip_prefix = "brew-%s" % brew_tag,
        build_file_content = """
sh_library(
    name = "binaries",
    srcs = glob(["bin/*"]),
    deps = [ "@homebrew_core//:allfiles" ],
    visibility = ["//visibility:public"],
)
""",
    )

    http_archive(
        name = "homebrew_core",
        urls = [
            "https://codeload.github.com/Homebrew/homebrew-core/zip/%s" % homebrew_core_commit
        ],
        strip_prefix = "homebrew-core-%s" % homebrew_core_commit,
        type = "zip",
        sha256 = "3f2c429cc6416ee9c45500d8f5d3e1c8e9876422a2906888e31303213c167a11",
        build_file_content = """
sh_library(
    name = "allfiles",
    srcs = glob(["*", "**/*"]),
    visibility = ["//visibility:public"],
)
""",
    )

brew_packages = repository_rule(
    implementation = _impl,
    attrs={
        "formulas": attr.string_list(mandatory=True),
        "verbose": attr.bool(),
    },
)
