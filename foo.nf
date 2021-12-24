#! /usr/bin/env nextflow

def b = "4.GB"
def pattern = '/^4.*[K,M,G][B]$/'
println b ==~ pattern