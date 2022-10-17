FROM alpine:latest

RUN apk add git openssh-client yq bash curl

# TODO : put the email and name of the Git user that have access to your cluster repo, through the SSH key below
RUN git config --global user.email "your-git-username@email.com"
RUN git config --global user.name "your-git-username"

RUN mkdir /root/.ssh
COPY id_rsa* /root/.ssh/
RUN chmod 400 /root/.ssh/id_rsa*
# assuming the Git repo is on gitlab.com, so adapt accordingly
RUN echo -e "Host gitlab.com\n\tStrictHostKeyChecking no" > /root/.ssh/config

COPY main.sh /

RUN chmod +x /main.sh
