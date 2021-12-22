# containerlog

Build a container image via `docker build -t username/reponame:tag .` given that the Dockerfile is in the current directory. Then, given the repository was created at DockerHub, push it to the Hub via `docker push username/reponame:tag`.
## v1.0
- first version with only samtools in micromamba image for the sake of the example workflow in this repository