# Changelog

## v1.0
- Now allow type String and GString when type is 'string' in schema validation. This allows to use double-quoted strings for the value key, e.g. when something like $baseDir requires path expansion to work.
- Moved the container definition from the nextflow.config to the modules itself in the toy example in this repo. This has the advantage that one now can use a per-module container/environment rather than a single monolithic one and it removes the need to hardcode the container/environment into both the schema file and the nextflow.config 
- cleanup in validation code and nicer error and summary logs
- added a first draft of an Action that tries to validate that an intentionally failed validation (during testing) is actually a successful test because it captured a wrong schema/param
- fixed bugs towards the summary message after successful validation
- fixed some edge cases towards mandatory/empty schema params

## v0.9
- initial version under development
