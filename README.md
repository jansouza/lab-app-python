# lab-app
Basic Python Flask app in Docker which prints the hostname and IP of the container

Build Status
----------


Copy libs - offline
----------
cd libs/
pip3.8  download -r ../requirements.txt


Build application
----------
Build the Docker image manually by cloning the Git repo.
  ```
  $ git clone <git_url>
  $ docker build -t lab-app .
  ```

Run the container
----------
Create a container from the image.

  ```
  $ docker run --name lab-app -d -p 8080:8080 lab-app
  ```

Run Development
----------
  ```
  export FLASK_ENV=development
  python app/app.py
  ```
  Now visit http://localhost:8080


Test
----------
```
flake8 .
pytest
```

Docker test
```
docker build -t lab-app --target test .
docker run -it --rm --name lab-app-test lab-app
```