#!/usr/bin/env python3
# Copyright (C) 2012-2013, The CyanogenMod Project
# Copyright (C) 2012-2015, SlimRoms Project
# Licensed under the Apache License, Version 2.0

import base64
import json
import netrc
import os
import sys
from xml.etree import ElementTree
from urllib import request, error, parse

DEBUG = False
default_manifest = ".repo/manifest.xml"
custom_local_manifest = ".repo/local_manifests/roomservice.xml"
custom_default_revision = "arrow-13.1"
custom_dependencies = "arrow.dependencies"
org_manifest = "ArrowOS-Devices"
org_display = "ArrowOS-Devices"
arrow_manifest = ".repo/manifests/arrow.xml"
hals_manifest = ".repo/manifests/hals.xml"

github_auth = None
local_manifests = ".repo/local_manifests"
os.makedirs(local_manifests, exist_ok=True)


def debug(*args, **kwargs):
    if DEBUG:
        print(*args, **kwargs)


def add_auth(g_req):
    global github_auth
    if github_auth is None:
        try:
            auth = netrc.netrc().authenticators("api.github.com")
        except (netrc.NetrcParseError, IOError):
            auth = None
        if auth:
            github_auth = base64.b64encode(f"{auth[0]}:{auth[2]}".encode()).decode()
        else:
            github_auth = ""
    if github_auth:
        g_req.add_header("Authorization", f"Basic {github_auth}")


def exists_in_tree(lm, repository):
    for child in list(lm):
        try:
            if child.attrib["path"].endswith(repository):
                return child
        except Exception:
            pass
    return None


def indent(elem, level=0):
    i = "\n" + "  " * level
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for child in elem:
            indent(child, level + 1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i


def load_manifest(manifest):
    try:
        return ElementTree.parse(manifest).getroot()
    except (IOError, ElementTree.ParseError):
        return ElementTree.Element("manifest")


def get_default(manifest=None):
    m = manifest or load_manifest(default_manifest)
    return m.findall("default")[0]


def get_remote(manifest=None, remote_name=None):
    m = manifest or load_manifest(default_manifest)
    if not remote_name:
        remote_name = get_default(manifest=m).get("remote")
    for remote in m.findall("remote"):
        if remote_name == remote.get("name"):
            return remote
    return None


def get_revision(manifest=None, p="build"):
    m = manifest or load_manifest(default_manifest)
    project = next((proj for proj in m.findall("project") if proj.get("path").strip("/") == p), None)
    if project is None:
        return custom_default_revision
    revision = project.get("revision")
    if revision:
        return revision.replace("refs/heads/", "").replace("refs/tags/", "")
    remote = get_remote(manifest=m, remote_name=project.get("remote"))
    revision = remote.get("revision") if remote is not None else None
    return revision.replace("refs/heads/", "").replace("refs/tags/", "") if revision else custom_default_revision


def get_from_manifest(device_name):
    for man in (custom_local_manifest, default_manifest):
        man = load_manifest(man)
        for local_path in man.findall("project"):
            lp = local_path.get("path").strip("/")
            if lp.startswith("device/") and lp.endswith("/" + device_name):
                return lp
    return None


def is_in_manifest(project_path):
    for man in (custom_local_manifest, default_manifest):
        man = load_manifest(man)
        for local_path in man.findall("project"):
            if local_path.get("path") == project_path:
                return True
    return False


def add_to_manifest(repos, fallback_branch=None):
    lm = load_manifest(custom_local_manifest)
    mlm = load_manifest(default_manifest)
    arrowm = load_manifest(arrow_manifest)
    halm = load_manifest(hals_manifest)

    for repo in repos:
        repo_name = repo["repository"]
        repo_target = repo["target_path"]
        repo_branch = repo.get("branch", custom_default_revision)
        repo_remote = repo.get("remote", org_manifest)

        if is_in_manifest(repo_target):
            print(f"already exists: {repo_target}")
            continue

        if repo_remote is None:
            repo_remote = "github"
        if "/" not in repo_name and repo_remote != org_manifest:
            repo_name = os.path.join(org_display, repo_name)

        existing_m_project = (
            exists_in_tree(mlm, repo_target)
            or exists_in_tree(arrowm, repo_target)
            or exists_in_tree(halm, repo_target)
        )

        if existing_m_project and existing_m_project.attrib["path"] == repo["target_path"]:
            print(f"{repo_name} already exists in main manifest, replacing with new dep")
            lm.append(ElementTree.Element("remove-project", attrib={
                "name": existing_m_project.attrib["name"]
            }))

        print(f"Adding dependency: {repo_name} -> {repo_target}")
        project = ElementTree.Element("project", attrib={
            "path": repo_target,
            "remote": repo_remote,
            "name": repo_name,
            "revision": repo_branch if repo_branch else fallback_branch or custom_default_revision
        })

        lm.append(project)

    indent(lm)
    raw_xml = "\n".join(['<?xml version="1.0" encoding="UTF-8"?>', ElementTree.tostring(lm, encoding="unicode")])
    with open(custom_local_manifest, "w") as f:
        f.write(raw_xml)


_fetch_dep_cache = []


def fetch_dependencies(repo_path, fallback_branch=None):
    global _fetch_dep_cache
    if repo_path in _fetch_dep_cache:
        return
    _fetch_dep_cache.append(repo_path)

    print("Looking for dependencies")

    dep_p = os.path.join(repo_path, custom_dependencies)
    if os.path.exists(dep_p):
        with open(dep_p) as dep_f:
            dependencies = json.load(dep_f)
    else:
        dependencies = []
        debug("Dependencies file not found, bailing out.")

    fetch_list = []
    syncable_repos = []

    for dependency in dependencies:
        if not is_in_manifest(dependency["target_path"]):
            if not dependency.get("branch"):
                dependency["branch"] = get_revision() or custom_default_revision
            fetch_list.append(dependency)
            syncable_repos.append(dependency["target_path"])

    if fetch_list:
        print("Adding dependencies to manifest")
        add_to_manifest(fetch_list, fallback_branch)

    if syncable_repos:
        print("Syncing dependencies")
        os.system("repo sync --force-sync --no-tags --current-branch --no-clone-bundle " + " ".join(syncable_repos))

    for deprepo in syncable_repos:
        fetch_dependencies(deprepo)


def has_branch(branches, revision):
    return revision in (branch["name"] for branch in branches)


def detect_revision(repo):
    print("Checking branch info")
    githubreq = request.Request(repo["branches_url"].replace("{/branch}", ""))
    add_auth(githubreq)
    result = json.loads(request.urlopen(githubreq).read().decode())

    calc_revision = get_revision()
    print(f"Calculated revision: {calc_revision}")

    if has_branch(result, calc_revision):
        return calc_revision

    fallbacks = os.getenv("ROOMSERVICE_BRANCHES", "").split()
    for fallback in fallbacks:
        if has_branch(result, fallback):
            print(f"Using fallback branch: {fallback}")
            return fallback

    if has_branch(result, custom_default_revision):
        print(f"Falling back to custom revision: {custom_default_revision}")
        return custom_default_revision

    print("Branches found:")
    for branch in result:
        print(branch["name"])
    print("Use the ROOMSERVICE_BRANCHES environment variable to specify fallback branches.")
    sys.exit(1)


def main():
    global DEBUG
    try:
        depsonly = bool(sys.argv[2] in ["true", "1"])
    except IndexError:
        depsonly = False

    if os.getenv("ROOMSERVICE_DEBUG"):
        DEBUG = True

    product = sys.argv[1]
    device = product.split("_", 1)[1] if "_" in product else product

    repo_path = get_from_manifest(device)
    if not repo_path:
        print(f"Device {device} not found in manifests.")
        print("Skipping GitHub lookup. Attempting to fetch dependencies if available...")
        for vendor in os.listdir("device"):
            path = os.path.join("device", vendor, device)
            if os.path.isdir(path) and os.path.exists(os.path.join(path, custom_dependencies)):
                repo_path = path
                break

    if repo_path:
        fetch_dependencies(repo_path)
        print("Dependency fetching done.")
    else:
        print(f"No device tree or dependencies found for {device}.")
    sys.exit(0)


if __name__ == "__main__":
    main()