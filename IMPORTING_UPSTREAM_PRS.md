# Importing Pull Requests from Upstream Repository

This guide explains how to import (apply) pull requests (PRs) from the main/original repository ("upstream") into your own forked repository.

## Step-by-Step Instructions

### 1. Add the Upstream Remote
If you haven't already, add the main/original repo as a remote:

```bash
git remote add upstream https://github.com/ORIGINAL_OWNER/REPO_NAME.git
git fetch upstream
```

### 2. Identify the PRs You Want
- Go to the main repo's GitHub page.
- For each PR you want, note the PR number.

### 3. Fetch the PR Branch or Commits
- On GitHub, open the PR and look for the branch name and the commit hashes.
- You can fetch a PR directly:
  ```bash
  git fetch upstream pull/PR_NUMBER/head:pr-PR_NUMBER
  ```
  This creates a local branch called `pr-PR_NUMBER` with the PR's changes.

### 4. Apply the PR to Your Fork
You have two main options:

#### A. Merge the PR branch:
```bash
git checkout main  # or your target branch
git merge pr-PR_NUMBER
```

#### B. Cherry-pick specific commits (if you only want some commits):
```bash
git checkout main  # or your target branch
git cherry-pick COMMIT_HASH
```
Repeat for each commit you want.

### 5. Push to Your Fork
```bash
git push origin main  # or your target branch
```

---

## Summary Table

| Step                | Command/Action                                                                 |
|---------------------|-------------------------------------------------------------------------------|
| Add upstream remote | `git remote add upstream <main repo url>`                                      |
| Fetch PR branch     | `git fetch upstream pull/PR_NUMBER/head:pr-PR_NUMBER`                          |
| Merge PR            | `git checkout main`<br>`git merge pr-PR_NUMBER`                                |
| Cherry-pick commit  | `git cherry-pick COMMIT_HASH`                                                  |
| Push to fork        | `git push origin main`                                                         |

---

## Tips
- If you want to keep the PR's history, use merge. If you want a clean history, use cherry-pick.
- Resolve any merge conflicts as they arise.
- After merging/cherry-picking, you can delete the temporary `pr-PR_NUMBER` branch.

---

If you know the PR numbers you want to import, you can substitute them directly into the commands above for a streamlined workflow. 