FROM ollama/ollama:latest

# Install jq and curl to parse options.json and check API
RUN apt-get update && apt-get install -y jq curl && rm -rf /var/lib/apt/lists/*

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
