load("@bazel_tools//tools/build_defs/repo:utils.bzl", "patch", "workspace_and_buildfile")

BUILD_FILE_CONTENT = '''
filegroup(
    name = "brew",
    srcs = ["bin/brew"],
    visibility = ["//visibility:public"],
)

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
'''

def _homebrew_archive_impl(ctx):
    """Implementation of the homebrew_archive rule."""
    if ctx.attr.build_file and ctx.attr.build_file_content:
        fail("Only one of build_file and build_file_content can be provided.")
    url = "https://github.com/Homebrew/brew/archive/%s.tar.gz" % ctx.attr.brew_tag

    all_brew_urls = []
    if ctx.attr.brew_urls:
        all_brew_urls = ctx.attr.brew_urls
    all_brew_urls = [url] + all_brew_urls

    ctx.download_and_extract(
        all_brew_urls,
        "",
        ctx.attr.brew_sha256,
        "",
        "brew-%s" % ctx.attr.brew_tag,
    )

    homebrew_core_url = "https://codeload.github.com/Homebrew/homebrew-core/zip/%s" % ctx.attr.homebrew_core_commit

    all_homebrew_core_urls = []
    if ctx.attr.homebrew_core_urls:
        all_homebrew_core_urls = ctx.attr.homebrew_core_urls
    all_homebrew_core_urls = [homebrew_core_url] + all_homebrew_core_urls

    ctx.download_and_extract(
        all_homebrew_core_urls,
        "Library/Taps/homebrew/homebrew-core",
        ctx.attr.homebrew_core_sha256,
        "zip",
        "homebrew-core-%s" % ctx.attr.homebrew_core_commit,
    )
    patch(ctx)
    workspace_and_buildfile(ctx)
    ctx.execute(["mkdir cache"])

    # TODO(tmc): move this to use update_attrs(ctx.attr, _homebrew_archive_attrs.keys(), {"brew_sha256": brew_download_info.sha256, "homebrew_core_sha256": homebrew_core_download_info.sha256})

_homebrew_archive_attrs = {
    "brew_tag": attr.string(default = "1.8.5"),
    "brew_sha256": attr.string(default = "3f2c429cc6416ee9c45500d8f5d3e1c8e9876422a2906888e31303213c167a11"),
    "homebrew_core_commit": attr.string(default = "e963aa704fe743f54d34bff943aaed7a0175f668"),
    "homebrew_core_sha256": attr.string(default = "3f2c429cc6416ee9c45500d8f5d3e1c8e9876422a2906888e31303213c167a11"),
    "brew_urls": attr.string_list(),
    "homebrew_core_urls": attr.string_list(),
    "build_file": attr.label(allow_single_file = True),
    "build_file_content": attr.string(default = BUILD_FILE_CONTENT),
    "patches": attr.label_list(default = []),
    "patch_tool": attr.string(default = "patch"),
    "patch_args": attr.string_list(default = ["-p0"]),
    "patch_cmds": attr.string_list(default = []),
    "workspace_file": attr.label(allow_single_file = True),
    "workspace_file_content": attr.string(),
}

homebrew_archive = repository_rule(
    implementation = _homebrew_archive_impl,
    attrs = _homebrew_archive_attrs,
)
