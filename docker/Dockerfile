FROM alpine:latest

ADD google.crt /usr/local/share/ca-certificates/
ADD github.crt /usr/local/share/ca-certificates/
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.18/main ca-certificates
RUN update-ca-certificates
RUN apk update && apk add git gcc python3-dev linux-headers libffi-dev libc-dev musl-dev python3 py3-pip python3-dev

ENV PYTHONUNBUFFERED=1
ENV TZ=Europe/Minsk
RUN ln -sf python3 /usr/bin/python
RUN python3 -m venv /root/python/.venv
ENV PATH="/root/python/.venv/bin:$PATH"
RUN mkdir -p /home/AI/comp
WORKDIR /home/AI/comp
RUN pip install --upgrade pip setuptools wheel cython
RUN git clone https://github.com/pypa/setuptools.git /home/AI/comp && cd /home/AI/comp && python3 -m pip install -e /home/AI/comp
RUN pip3 install psutil

COPY requirements.txt /home/AI/comp
COPY Ussage.py /home/AI/comp

RUN pip3 install -r /home/AI/comp/requirements.txt

ENV PATH=/root/.local:$PATH

CMD [ "python3", "-u", "/home/AI/comp/Ussage.py" ]

EXPOSE 5555