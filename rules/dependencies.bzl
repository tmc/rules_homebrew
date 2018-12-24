load("@bazel_tools//tools/build_defs/repo:git.bzl", "new_git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def homebrew_rules_dependencies(
        brew_tag = "1.8.5",
        brew_sha256 = "3f2c429cc6416ee9c45500d8f5d3e1c8e9876422a2906888e31303213c167a11",
        homebrew_core_commit = "e963aa704fe743f54d34bff943aaed7a0175f668",
        homebrew_core_sha256 = "3f2c429cc6416ee9c45500d8f5d3e1c8e9876422a2906888e31303213c167a11"):
    http_archive(
        name = "homebrew",
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

filegroup(
    name = "allfiles",
    srcs = glob(
        ["*", "**/*"],
        exclude = [
            "**/* *",
            "**/*:*",
        ]
        ),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "cellar",
    srcs = ["Cellar"],
    visibility = ["//visibility:public"],
)
""",
    )

    http_archive(
        name = "homebrew_core",
        urls = [
            "https://codeload.github.com/Homebrew/homebrew-core/zip/%s" % homebrew_core_commit,
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
