# blog.albinenglund.com

### Install

Docker is required. To build the image, run the following:

```
docker compose build
```

### Update dependencies

To update dependencies, edit the `Gemfile` and rebuild the image:

```
docker compose build
```

### Run development server

To run the development server, run the following:

```
docker compose up
```

The site is served at `http://localhost:4000`.
