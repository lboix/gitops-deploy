FROM alpine:latest

RUN apk add --no-cache git openssh yq bash curl

# TODO : put the email and name of the Git user that have access to your cluster repo, through the SSH key below
RUN git config --global user.email "your-git-username@email.com"
RUN git config --global user.name "your-git-username"

COPY ssh/prepare_ssh.sh /
RUN chmod +x /prepare_ssh.sh

COPY main.sh /
RUN chmod +x /main.sh
