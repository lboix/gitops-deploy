# gitops-deploy

## Why ?
During my learning of GitOps philosophy, I found out that many of existing tools and articles do assume that you are already taking care of the last step in your CI pipeline to commit / push the right modification in the right file of the Git repo that describes your Kubernetes cluster for example. 
And this push will trigger the actual deployment.

It took me some time to achieve this and I was thinking : it's probably sure that some people will face this exact situation in the future during their researches. So I am sharing this simple script here if that can help you to gain some time with that!

It's really possible (I hope not ^^) that I "reinventend the wheel" here so if you know an existing similar repo or way to achieve the exact same purpose, please let me know. I precise that the goal is to avoid the using of an external CLI (like Flux one for example), only git command line, to follow the GitOps philosophy and have a CI pipeline completely independent of the GitOps agent pulling the changes.

## Assumptions of the current script
- the .yaml file you want to modify does only describe 1 Deployment having 1 container template
- Deployment name is the same as the Docker image name (like this : repo/**deployment-name**:tag)

## Description of environment variables used by the current script
- CLUSTER_GIT_CLONE_URL : the cluster Git repo URL to git clone (through SSH)
- YAML_FILE_PATH : the path to the .yaml file containing the Deployment to update
- NAMESPACE : the namespace belonging to your Deployment
- DOCKER_REPO : the name of the registry repo of your image to deploy (*repo*/deployment-name:tag)
- DOCKER_IMAGE : the name of your image to deploy (repo/*deployment-name*:tag)
- DOCKER_TAG : the tag of your image to deploy (repo/deployment-name:*tag*)

## How to build your first gitops-deploy image ?
- simply git clone this repo, if you host it somewhere : make sure this Git repo will be PRIVATE (regarding the SSH key)
- handle the TODO in [Dockerfile](Dockerfile)
- generate a new SSH key and follow the TODO in [id_rsa](id_rsa) and [id_rsa.pub](id_rsa.pub)
- add this SSH key to the Git user you put in [Dockerfile](Dockerfile)
- read [main.sh](main.sh) and adapt it according your needs (do not hesitate to ask questions here!)

- use the [Dockerfile](Dockerfile) to build and push your gitops-deploy image (you can use the [.gitlab-ci.yml](.gitlab-ci.yml) template if host your repo in Gitlab) : make sure your image access will be PRIVATE (regarding the SSH key)

## How to use it ?
- at the end of your CI pipeline, you can use docker CLI directly (if your job has access to it of course) like this :
```
docker run -e CLUSTER_GIT_CLONE_URL=your-url -e YAML_FILE_PATH=your-path ... THE_DOCKER_IMAGE_YOU_BUILT_ABOVE "./main.sh"
```
- if your project is hosted in Gitlab, you can use the equivalent snippet
```
deploy:
  stage: deploy
  image: THE_DOCKER_IMAGE_YOU_BUILT_ABOVE
  dependencies: []
  when: manual
  variables:
    CLUSTER_GIT_CLONE_URL: 'your-url'
    YAML_FILE_PATH: 'your-path'
    ...
  script:
    - /main.sh
```

## Improvement ideas
- Think about the best way to use a SSH key through a Dockerfile
- Add snippets and templates for other tools
- Add a retry scheme in the script : if your CI pipeline is launching parrallel deployment jobs using this image, then some ones can fail with message `cannot lock ref 'refs/heads/master'`
