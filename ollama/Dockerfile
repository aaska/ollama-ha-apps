ARG BUILD_FROM
FROM $BUILD_FROM

# Install jq, curl, zstd, and tar to parse options.json and unpack Ollama updates
RUN apt-get update && apt-get install -y jq curl zstd tar && rm -rf /var/lib/apt/lists/*

COPY run.sh /
RUN chmod a+x /run.sh
ENTRYPOINT [ "/run.sh" ]
