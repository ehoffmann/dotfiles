#!/usr/bin/env python3
"""Exercise MR with real Git histories and a fake, offline glab API.

Run: python3 vim/tests/run_gitmr.py
Requires classic Vim with +job; no GitLab credentials or plugins needed.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def git(repo, *args, check=True):
    result = subprocess.run(
        ["git", "-C", str(repo), *args], text=True, capture_output=True,
        env={**os.environ, "GIT_CONFIG_GLOBAL": os.devnull,
             "GIT_CONFIG_NOSYSTEM": "1"},
    )
    if check and result.returncode:
        raise RuntimeError(result.stderr)
    return result


def commit(repo, path, text):
    (repo / path).write_text(text)
    git(repo, "add", path)
    git(repo, "commit", "-qm", path)
    return git(repo, "rev-parse", "HEAD").stdout.strip()


def clone(root, name, repo, branch, depth=None):
    path = root / name
    args = ["clone", "--quiet", "--single-branch", "--branch", branch]
    if depth:
        args += ["--depth", str(depth)]
    git(root, *args, repo.as_uri(), str(path))
    return path


def fixtures(root):
    repo = root / "repo with spaces"
    repo.mkdir()
    git(repo, "init", "-q", "-b", "main")
    git(repo, "config", "user.name", "MR test")
    git(repo, "config", "user.email", "mr@example.test")
    base = commit(repo, "service.rb", "base\n")

    git(repo, "checkout", "-qb", "source")
    commit(repo, "service.rb", "source\n")
    original = commit(repo, "spec.rb", "MR spec\n")
    git(repo, "checkout", "-q", "main")
    target = commit(repo, "service.rb", "target\n")
    commit(repo, "unrelated.rb", "target change\n")
    target = git(repo, "rev-parse", "HEAD").stdout.strip()
    result = git(repo, "merge", "--no-ff", "source", "-m", "MR merge", check=False)
    assert result.returncode == 1, "The fixture must include a merge conflict"
    merge = commit(repo, "service.rb", "resolved MR\n")
    git(repo, "branch", "-D", "source")
    git(repo, "branch", "merge-tip", merge)
    commit(repo, "later.rb", "later unrelated change\n")

    git(repo, "checkout", "-qb", "squash-source", base)
    commit(repo, "squash_one.rb", "first\n")
    squash_original = commit(repo, "squash_two.rb", "second\n")
    git(repo, "checkout", "-qb", "squash-target", base)
    squash_base = commit(repo, "unrelated_squash.rb", "target change\n")
    git(repo, "merge", "--squash", "squash-source")
    git(repo, "commit", "-qm", "MR squash")
    squash = git(repo, "rev-parse", "HEAD").stdout.strip()
    git(repo, "branch", "-D", "squash-source")
    commit(repo, "later_squash.rb", "later change\n")
    git(repo, "checkout", "-qb", "squash-merge-target", squash_base)
    git(repo, "merge", "--no-ff", squash, "-m", "Merge squashed MR")
    squash_merge = git(repo, "rev-parse", "HEAD").stdout.strip()

    git(repo, "checkout", "-qb", "ff-source", base)
    commit(repo, "ff_one.rb", "first\n")
    ff = commit(repo, "ff_two.rb", "second\n")
    git(repo, "checkout", "-qb", "ff-target", base)
    git(repo, "merge", "--ff-only", "ff-source")
    git(repo, "branch", "-D", "ff-source")
    ff_later = commit(repo, "later_ff.rb", "later change\n")

    # Simulate server-side cleanup after squash, including expired MR refs.
    # These operations affect only this temporary fixture repository.
    git(repo, "reflog", "expire", "--expire=now", "--all")
    git(repo, "gc", "--prune=now", "--quiet")
    assert git(repo, "cat-file", "-e", squash_original, check=False).returncode

    def mr(iid, head, merge_sha=None, squash_sha=None, state="merged", branch="main"):
        return {
            "iid": iid, "state": state, "title": f"MR {iid}",
            "author": {"username": "alice"},
            "updated_at": "2026-10-01T12:00:00Z",
            "merged_at": f"2026-09-{iid:02d}T12:00:00Z" if state == "merged" else None,
            "web_url": f"https://gitlab.example.test/group/repo/-/merge_requests/{iid}",
            "target_branch": branch, "source_branch": "deleted-source",
            "target_project_id": 1, "source_project_id": 1,
            "merge_commit_sha": merge_sha, "squash_commit_sha": squash_sha,
            "diff_refs": {"base_sha": base, "start_sha": base, "head_sha": head},
        }

    mrs = {
        "merge": mr(1, original, merge),
        "squash": mr(2, squash_original, squash_sha=squash, branch="squash-target"),
        "squash_merge": mr(3, squash_original, squash_merge, squash),
        "ff": mr(4, ff, branch="ff-target"),
        "opened": mr(5, original, state="opened"),
    }
    squash_clone = clone(root, "squash clone", repo, "squash-target")
    shallow = clone(root, "shallow clone", repo, "merge-tip", depth=1)
    fetch_clone = clone(root, "fetch clone", repo, "ff-target")
    assert git(squash_clone, "cat-file", "-e", squash_original, check=False).returncode
    assert git(shallow, "cat-file", "-e", target, check=False).returncode
    assert git(fetch_clone, "cat-file", "-e", merge, check=False).returncode
    git(fetch_clone, "config", "user.name", "MR test")
    git(fetch_clone, "config", "user.email", "mr@example.test")
    (fetch_clone / "ff_one.rb").write_text("staged change\n")
    git(fetch_clone, "add", "ff_one.rb")
    (fetch_clone / "ff_one.rb").write_text("unstaged change\n")

    data = {
        "repo": str(repo), "squash_repo": str(squash_clone), "shallow_repo": str(shallow),
        "fetch_repo": str(fetch_clone), "base": base, "target": target,
        "merge": merge, "original": original, "squash_base": squash_base,
        "squash": squash, "squash_merge": squash_merge, "ff_later": ff_later,
        "mrs": mrs,
        "project": {"id": 1, "path_with_namespace": "group/repo",
                    "ssh_url_to_repo": repo.as_uri(), "http_url_to_repo": repo.as_uri()},
    }
    (root / "fixtures.json").write_text(json.dumps(data))
    return data


FAKE_GLAB = '''#!/usr/bin/env python3
import json, os, pathlib, sys, time
from urllib.parse import parse_qs, urlparse
root = pathlib.Path(os.environ["GITMR_TEST_ROOT"])
data = json.loads((root / "fixtures.json").read_text())
assert sys.argv[1] == "api", sys.argv
endpoint = sys.argv[2]
with (root / "api.log").open("a") as log:
    log.write(endpoint + "\\n")
if (root / "slow").exists():
    time.sleep(2)
if (root / "auth_error").exists():
    print('{"message":"401 Unauthorized"}')
    print("glab: 401 Unauthorized", file=sys.stderr)
    sys.exit(1)
path = urlparse(endpoint).path
query = parse_qs(urlparse(endpoint).query)
if path == "projects/:fullpath":
    print(json.dumps(data["project"]))
elif path == "projects/1/merge_requests":
    if query.get("order_by") == ["merged_at"] and (root / "old_server").exists():
        print('{"error":"order_by does not have a valid value"}')
        print("glab: HTTP 400", file=sys.stderr)
        sys.exit(1)
    rows = list(data["mrs"].values())
    state = query["state"][0]
    rows = [mr for mr in rows if mr["state"] == state]
    if "reviewer_username" in query:
        assert query["reviewer_username"] == [":username"]
        rows = [data["mrs"]["opened"]]
    if (root / "old_server").exists():
        # More than one API page, with the newest merge deliberately last.
        rows = [dict(data["mrs"]["merge"], iid=n,
                     merged_at="2020-01-01T00:00:00Z") for n in range(1, 101)]
        rows += [dict(data["mrs"]["ff"], iid=101,
                      merged_at="2026-10-01T00:00:00Z")]
    elif query["order_by"] == ["merged_at"]:
        rows.sort(key=lambda mr: mr["merged_at"], reverse=True)
    page = int(query["page"][0])
    print(json.dumps(rows[(page-1)*100:page*100]))
else:
    iid = int(path.rsplit("/", 1)[-1])
    print(json.dumps(next(mr for mr in data["mrs"].values() if mr["iid"] == iid)))
'''


def main():
    vim = shutil.which(os.environ.get("GITMR_VIM", "vim"))
    with tempfile.TemporaryDirectory(prefix="gitmr-tests-") as directory:
        root = Path(directory)
        fixtures(root)
        print("Git fixtures verified: conflict merge, squash, squash+merge, multi-commit FF, "
              "deleted branches, unavailable original history, shallow and dirty clones.")
        if not vim:
            print("SKIP Vim tests: classic Vim is not installed.")
            return 77
        bin_dir = root / "bin"
        bin_dir.mkdir()
        (bin_dir / "glab").write_text(FAKE_GLAB)
        (bin_dir / "glab").chmod(0o755)
        env = {**os.environ, "GITMR_TEST_ROOT": str(root),
               "PATH": str(bin_dir) + os.pathsep + os.environ["PATH"],
               "GIT_CONFIG_GLOBAL": os.devnull, "GIT_CONFIG_NOSYSTEM": "1"}
        script = Path(__file__).with_name("gitmr.vim")
        result = subprocess.run([vim, "-Nu", "NONE", "-i", "NONE", "-n", "-es",
                                 "-V1" + str(root / "vim.log"), "-S", str(script)],
                                env=env, text=True, capture_output=True, timeout=30)
        if result.returncode:
            print(result.stdout + result.stderr)
            print((root / "vim.log").read_text())
            return 1
        print("Vim tests passed: immutable endpoints, async selector, targeted fetch, "
              "unchanged index/worktree/HEAD, reviewers, refresh, pagination, errors and cancellation.")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
