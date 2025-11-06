# Showcasing a DevOps approach with LieberLieber LemonTree and Sparx Systems Enterprise Architect

## Introduction

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