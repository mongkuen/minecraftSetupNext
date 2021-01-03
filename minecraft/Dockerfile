FROM ubuntu:18.04

ARG bedrockVersion=1.16.201.02
ENV bedrockVersion=${bedrockVersion}

RUN apt-get update
RUN apt-get install -y \
    curl \
    unzip

RUN mkdir bedrock-server
RUN curl --fail https://minecraft.azureedge.net/bin-linux/bedrock-server-${bedrockVersion}.zip --output bedrock-server.zip
RUN unzip bedrock-server.zip -d bedrock-server

WORKDIR /bedrock-server

ADD config/ config/

RUN rm server.properties && \
    rm permissions.json && \
    rm whitelist.json && \
    ln -s config/server.properties server.properties && \
    ln -s config/permissions.json permissions.json && \
    ln -s config/whitelist.json whitelist.json

CMD LD_LIBRARY_PATH=. ./bedrock_server
