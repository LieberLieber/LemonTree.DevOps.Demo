
---

## 🔄 Rebase Instructions

If you need to rebase this PR against the target branch, you can trigger the automated rebase workflow by commenting:

```
/rebase/
```

The rebase workflow will automatically:
- Rebase your PR branch against the target branch
- Resolve model conflicts using LemonTree.Automation
- Push the rebased changes

**Note:** Only authorized contributors can trigger this workflow.

---

## 🔄 Update Polarion Requirements Instructions

If you need to update this PR's model with the latest Polarion items, you can trigger the automated Polarion update workflow by commenting:

```
/update polarion/
```

The Polarion update workflow will automatically:
- Import the latest Polarion items into the model
- Compare the updated model against the current branch
- Run model validation checks on the updated model
- Push the updated model to the branch (if checks pass)
- Create a detailed comparison report with SVG diagrams showing all changes

You can also use alternative trigger phrases like:
- `polarion update`
- `update requirements from polarion`
- Any comment containing both `update` and `polarion`

**Note:** Only authorized contributors can trigger this workflow. The model will only be updated if all validation checks pass.
