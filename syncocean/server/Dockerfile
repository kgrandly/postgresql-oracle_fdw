# For more information, please refer to https://aka.ms/vscode-docker-python
FROM python:latest

# Install Bjoern requirements
RUN apt update && \
    apt install --no-install-recommends -y gcc libev-dev && \
    rm -rf /var/lib/apt/lists/*

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

WORKDIR /usr/src/app

# Install pip requirements
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Creates a non-root user with an explicit UID and adds permission to access the /usr/src/app folder
# For more info, please refer to https://aka.ms/vscode-docker-python-configure-containers
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /usr/src/app
USER appuser

EXPOSE 8080

CMD [ "python", "main.py" ]
