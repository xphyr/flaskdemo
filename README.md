# flaskdemo

This is a pseudo-fork of the code from here [Simple Python Flask Program with MongoDB](https://www.codeproject.com/Articles/1255416/Simple-Python-Flask-Program-with-MongoDB).  I needed a simple to understand flask application that uses MongoDB for creating a Jenkins/OpenShift pipeline demo. The original code can be found here: https://github.com/sarathlalsaseendran/FlaskWithMongoDB and is licensed under the [CPOL](https://www.codeproject.com/info/cpol10.aspx)

## Setup

The following assumes the use of Python3.  

```
git clone
cd flaskdemo
python -m venv venv
. venv/bin/activate
pip install -r requirements.txt
docker run -d -p 27017:27017 -v ~/data:/data/db --name mongodb mongo
python app.py
```

## Dockerfile

The Dockerfile builds on the UBI8 base images from Red Hat.
