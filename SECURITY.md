#Git Repository Policy – Project Name

## 1. Main Branches:

- `main`: primary, stable, production-ready branch.

- `test`: integration branch, used for testing and validation before merging into main.

## 2. Contribution Rules:

All contributions must go through a personal or feature branch.

Personal/feature branches must be merged into `test` via pull request.

Developers are not allowed to push directly to `main`.

## 3. Pull Requests:

Pull requests to `main` must be approved by the repository owner.

Pull requests to `test` can be reviewed by other team members if needed.

## 4. Branch Protection:

`main` is protected to prevent direct pushes by anyone except the owner.

`test` is protected to ensure all contributions go through pull requests before integration into main.

## 5. Recommendations:

Ensure code passes all automated tests before submitting a PR.

Write clear and detailed commit messages.
