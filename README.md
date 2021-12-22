# nf-blank

![CI](https://github.com/ATpoint/nf_blank/actions/workflows/CI.yml/badge.svg)
[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A521.10.6-23aa62.svg?labelColor=000000)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

A minimal template for Nextflow DSL2 pipelines that is able to perform full params validation using only native Groovy/Nextflow without any external dependencies.
The params validation builds on a custom definition file `schema.nf`. Rather than using a schema that is not or poorly human readable such as JSONs we use simple Groovy maps to define params. Each map must consist of four keys:

1) **`value`**:     the default value of the param
2) **`type`**:      the expected type of `value`, one of `integer`, `float`, `string` or `logical`
3) **`allowed`**:   allowed choices for `value`
4) **`mandatory`**: a logical, whether this param must be set (`true`, so cannot be empty) or is optional

This followes Groovy rules, so integers and floats must not be quoted. Strings must be quoted. In case of multiple entries (for `allowed` we use lists).
For parsing purposes the params **must not** be prefixed `params.` as we do for regular Nextflow params but **must** be prefixed as `schema.`. 

## Examples

**Example for an integer/float**: The default is 1, allowed choices are `1,2,3` and it is a mandatory param:
```groovy
schema.threads = [value:1, type:'integer', mandatory:true, allowed:[1,2,3]]`
```

**Example for a string**: The default is `atacseq` and choices are `atacseq` and `chipseq`:
```groovy
schema.assay = [value:'atacseq', type:'string', mandatory:true, allowed:['atacseq', 'chipseq']]`
```

**Example for a logical**: The default is `true` and choices are abviously `true/false` but in case of a logical type must not be specified in `allowed`:
```groovy
schema.do_alignment = [value:true, type:'logical', mandatory:true, allowed:'']`
```

Note that `allowed` must contain an empty string if left blank, otherwise it would lead to a parsing error.

You can simply explore the behaviour of the validation by running the example workflow via:

```bash
nextflow run main.nf
```

...and then either parsing invalid parameters via the command line or changing values/types/allowed keys in the `schema.nf`.

**This repository is under development and comes without any warranty!**

## Validation workflow

The validation involves the following steps:

- validate that `schema.nf` is present in the `$baseDir` which is assumed to be the directory with `main.nf``
- validate that `value` has the correct `type`
- validate that all entries of `allowed` have the correct `type`
- validate that `mandatory` params are set
- validate that all params that are passed to Nextflow (be it command line, config files or from inside scripts) are defined in `schema.nf``

The validation will run and print one error message per failed validation to `stdout`, and then eventually `exit 1`, not starting the main workflows.

The validation is fully compatible with "standard" Nextflow params, so the user can use config files, define params in scripts, via `-params-file` or the command line, given that the param has been defined in `schema.nf`. If not the validation will capture this and throw an error. The standard Nextflow rules apply in terms of [params priority](https://www.nextflow.io/docs/latest/config.html#configuration-file) with those defined in `schema.nf` being of lowest priority. That means that any "standard" param, e.g. from command line will be used if set, but undergo the same validation as "schema" params.

The entire validation exclusively uses native Nextflow/Groovy syntax and comes without any external dependencies and without the need for any external GUIs as would be necessary (or recommended) when using schema formats that are poorly human readable such as JSON. The actual validation code is in `functions/validate_schema_params.nf` and is evaluated in the `main.nf` on top of the script.

In case of a passed/successful validation a summary of all params is printed to `stdout`. Here we use the example data in `test/` to run the minimal example (sam2bam) workflow with defaults defined in `schema.nf`:
<br>
![example_passed](https://i.ibb.co/ZSLd9hp/example-passed.png)
<br>

In case of a failed validation all conflicts will be printed to `stdout`. Here we intentionally give a float to `--threads` (expecting an integer), an integer to `--publishdir`(expecting a string) and we pass a param not defined in `schema.nf`:

![example_failed](https://i.ibb.co/hLv2DpH/example-failed.png)
