FROM registry.access.redhat.com/ubi8/python-36

COPY . /app
WORKDIR /app
RUN pip3 install -r requirements.txt

# set default flask app and environment
ENV FLASK_APP flaskr
ENV FLASK_ENV development

# This is primarily a reminder that we need access to port 5000
EXPOSE 5000

# Change this to UID that matches your username on the host
# Note: RUN commands before this line will execute as root in the container
# RUN commands after will execute under this non-privileged UID
USER 1000

# Default cmd when container is started
# Create the database if it doesn't exist, then run the app
# Use --host to make Flask listen on all networks inside the container
# CMD python3 app.py
ENTRYPOINT ["gunicorn", "--config", "gunicorn_config.py", "app:app"]
EXPOSE 5000