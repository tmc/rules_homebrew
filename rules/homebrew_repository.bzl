load("@bazel_tools//tools/build_defs/repo:utils.bzl", "patch")

BUILD_FILE_CONTENT = '''
#filegroup(
#    name = "brew",
#    srcs = ["bin/brew"],
#    visibility = ["//visibility:public"],
#)

#filegroup(
#    name = "allbinaries",
#    srcs = glob(["bin/*"], exclude=["bin/brew"]),
#    visibility = ["//visibility:public"],
#)

filegroup(
    name = "library",
    srcs = glob(["Library/**"]),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "cellar",
    srcs = ["Cellar"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "allfiles",
    srcs = glob(
        ["*", "**/*"],
        exclude=["**/*:*", "**/* *"],
    ),
    visibility = ["//visibility:public"],
)

'''

sh_binary_template = '''
sh_binary(
    name = "{name}",
    srcs = ["bin/{name}"],
    visibility = ["//visibility:public"],
)
'''

def generate_build_file(ctx):
    binaries = ''
    for binary in _installed_binaries(ctx):
        binaries += sh_binary_template.format(
            name = binary,
        )

    return BUILD_FILE_CONTENT + binaries


def _homebrew_repository_impl(ctx):
    """Implementation of the homebrew_repository rule."""

    # network access
    tag = ctx.attr.homebrew_tag
    url = "https://github.com/Homebrew/brew/archive/%s.tar.gz" % ctx.attr.homebrew_tag
    url_sha = ctx.attr.homebrew_sha256

    all_brew_urls = []
    if ctx.attr.brew_urls:
        all_brew_urls = ctx.attr.brew_urls
    all_brew_urls = [url] + all_brew_urls

    ctx.download_and_extract(
        all_brew_urls,
        "",
        url_sha,
        "",
        "brew-%s" % tag,
    )

    homebrew_core_commit = ctx.attr.homebrew_core_commit
    homebrew_core_url = "https://codeload.github.com/Homebrew/homebrew-core/zip/%s" % ctx.attr.homebrew_core_commit
    homebrew_core_sha = ctx.attr.homebrew_core_sha256

    all_homebrew_core_urls = []
    if ctx.attr.homebrew_core_urls:
        all_homebrew_core_urls = ctx.attr.homebrew_core_urls
    all_homebrew_core_urls = [homebrew_core_url] + all_homebrew_core_urls

    ctx.download_and_extract(
        all_homebrew_core_urls,
        "Library/Taps/homebrew/homebrew-core",
        homebrew_core_sha,
        "zip",
        "homebrew-core-%s" % homebrew_core_commit,
    )
    patch(ctx)

    ctx.execute(["mkdir","cache"])

    ctx.template("brew-wrapper.sh", ctx.attr.brew_wrappper_template)

    extra_args = []
    if ctx.attr.verbose:
        extra_args += ["--verbose"]

    cmd = [
        "./brew-wrapper.sh",
        "install",
        #"--no-sandbox",
        # TODO(tmc): "--ignore-dependencies", # force our hand
    ] + ctx.attr.packages
    result = ctx.execute(cmd, quiet = ctx.attr.verbose == False)
    if ctx.attr.verbose:
        print("[rules_homebrew]", result.return_code, result.stdout, result.stderr)
    if result.return_code != 0:
        fail("[brew_packges] " + result.stderr)

    build_file_content = generate_build_file(ctx)
    ctx.file("BUILD", build_file_content)
    ctx.file("WORKSPACE", "workspace(name = \"{name}\")\n".format(name = ctx.name))

    # TODO(tmc): move this to use update_attrs(ctx.attr, _homebrew_repository_attrs.keys(), {"brew_sha256": brew_download_info.sha256, "homebrew_core_sha256": homebrew_core_download_info.sha256})

def _formula_version(ctx, formula):
    r = ctx.execute(["./brew-wrapper.sh", "ls", "--versions", formula])
    if ctx.attr.verbose:
        print("[rules_homebrew]", r.return_code, r.stdout, r.stderr)
    return r.stdout.strip().split(" ")[-1]

def _installed_binaries(ctx):
    r = ctx.execute(["ls", "bin"])
    return [x for x in r.stdout.splitlines() if x != "brew"]

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
_homebrew_repository_attrs = {
    "homebrew_tag": attr.string(default = "2.1.4"),
    "homebrew_sha256": attr.string(default = "72f7da99b2cb2dff162454808f7dfdc40ba090c4dadf2d342be71a0c5ad87f0b"),
    "homebrew_core_commit": attr.string(default = "b42af313cb081d5745d2c65bfc0d2b3dec756bea"),
    "homebrew_core_sha256": attr.string(default = "a7422b52c61462d1c7f5f70d591df36de1f3283f78282104d811234d93725bee"),
    "brew_urls": attr.string_list(),
    "homebrew_core_urls": attr.string_list(),
    "patches": attr.label_list(default = []),
    "patch_tool": attr.string(default = "patch"),
    "patch_args": attr.string_list(default = ["-p0"]),
    "patch_cmds": attr.string_list(default = []),
    "workspace_file": attr.label(allow_single_file = True),
    "workspace_file_content": attr.string(),

    "packages": attr.string_list(mandatory = True),
    "brew_wrappper_template": attr.label(default = "//scripts:brew-wrapper.sh"),
    "verbose": attr.bool(),
}


homebrew_repository = repository_rule(
    implementation = _homebrew_repository_impl,
    attrs = _homebrew_repository_attrs,
)

