FROM python:3.9-slim-bullseye

RUN pip3 install Flask

COPY . .

ENTRYPOINT [ "python", "-m" ]
CMD [ "flask",  "--app=server", "--debug", "run",  "--host=0.0.0.0", "--cert=server.crt", "--key=server.key"]
