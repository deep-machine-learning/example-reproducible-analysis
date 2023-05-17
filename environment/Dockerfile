FROM python:3.10-slim

ENV PYTHONUNBUFFERED=TRUE

# install gcc
RUN apt-get update \
    && apt-get install -y gcc git curl unzip \
    && apt-get clean

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
	./aws/install

# install python dependencies
COPY requirements.txt .
RUN pip install --no-cache -r requirements.txt
