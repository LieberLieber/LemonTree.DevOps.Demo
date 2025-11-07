# Showcasing a DevOps approach with LieberLieber LemonTree and Sparx Systems Enterprise Architect

## Introduction
Welcome to the **LemonTree DevOps Demo** — a hands-on showcase of how you can bring modern DevOps workflows to model-based systems engineering (MBSE) using LemonTree and Sparx Systems Enterprise Architect, all orchestrated through GitHub Actions.

In complex engineering landscapes, particularly when you’re working with SysML and rich structural models, you need more than manual processes—you need automation, traceability, integrations, and reliable continuous workflows. This demo illustrates how LemonTree together with LemonTree Automation can bridge that gap by connecting your model repository in GitHub with your mbse models in Enterprise Architect.

**What you’ll see here:**

- Every change committed to your model repository triggers automated checks of your EA model, ensuring its integrity, version coherence, and compliance with modeling rules.
    
- Pull-requests are handled with model-aware actions: for example, you can trigger a rebase or merge of model versions simply by commenting (e.g., `/rebase/`) on a PR.
    
- Automation ensures that your MBSE artifacts evolve — and that your team can apply standard DevOps best practices (branching, merging, CI/CD) to architectural models just as you do to software.
    
- You benefit from full traceability between model changes, version control, and engineering outcomes — helping you maintain consistency, enable collaboration, and reduce manual error in system-model lifecycles.
    

In short: this repository demonstrates how to **bring DevOps to MBSE** by integrating GitHub, Enterprise Architect models, and LemonTree’s automation capabilities — turning what used to be a manual, fragmented workflow into a continuous, model-aware pipeline.

Whether you’re a systems engineer, enterprise architect, or DevOps practitioner exploring how to include models in your engineering lifecycle — this demo is a launchpad to explore, adapt, and scale model-based DevOps in your organization.
## Prerequisites

If you fork this Repo and want to run the LemonTree.Automation examples you need to set an "LTALICENSE" Secret for Actions containing a valid License to be obtained from LieberLieber.
## Actions

### Review Model Check

#### Trigger
Is run on every commit to the repo and evaluates the Sparx Systems Enterprise Architect Model. 
#### Action Runs
https://github.com/LieberLieber/LemonTree.DevOps.Demo/actions/workflows/ReviewModelCheck.yml

### Review Consistency Check with LemonTree.Automation
#### Trigger
Is run on every commit to the repo and evaluates the Sparx Systems Enterprise Architect Model. 
#### Action Runs
https://github.com/LieberLieber/LemonTree.DevOps.Demo/actions/workflows/ReviewConsistencyCheck.yml

### Rebase with PR comment using LemonTree.Automation
#### Trigger
Is run on every time you create a "/rebase/" comment in a PR
#### Action Runs
https://github.com/LieberLieber/LemonTree.DevOps.Demo/actions/workflows/RebasePRByComments.yml
#### Notes
On run the version from the "main" branch is executed and never the version from a feature branch.

## Repo Notes

There is an [orphan branch "svg"](https://github.com/LieberLieber/LemonTree.DevOps.Demo/tree/svg) that is used to store SVG files created by GitHub Actions.