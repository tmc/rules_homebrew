load("@io_bazel_skydoc//stardoc:stardoc.bzl", "stardoc")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(default_visibility = ["//visibility:public"])

load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")

bzl_library(
    name = "srcs",
    srcs = [
    "//rules:homebrew_repository.bzl",
    "//rules:brew_package.bzl"
    ],
)

bzl_library(
    name = "skylib_paths",
    srcs = ["@bazel_skylib//lib:paths.bzl"],
)

bzl_library(
    name = "repo_utils",
    #srcs = ["@bazel_tools//tools/build_defs/repo:utils.bzl"],
    srcs = ["@bazel_tools//tools:srcs"],
)

stardoc(
    name = "docs",
    out = "docs.md",
    input = "//rules:docs.bzl",
    deps = [
        ":repo_utils",
        ":srcs",
    ],
)
