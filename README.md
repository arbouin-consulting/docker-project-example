# Project docker example

For development multi application, we will set up an architecture to use DNS instead of  `localhost:port`.

We will use `Traefik` as a reverse proxy.

The proposed architecture will be as follows:
```
|- docker-compose.yml -> Traefik config instance
|- app1/
|   |- docker-compose.yml  -> list of instances project
|   |- .docker             -> configuration of containers
|   |- Dockerfile           -> configuration build of project
|- app2/
...
```

## Requirements
* Taskfile
* docker
* docker-compose

## Usage
To know the list of all the commands available in the Taskfile (eq Makefile in YAML):
```
task
```
For run all projects:
```
task run:all
```
Clean and down all projects:
```
task down:all
```