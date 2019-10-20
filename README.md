# Marley's Boon

A reliable way to combat starvation.

## Installation

### The Docker Way

Prerequisites: docker-compose v. 1.13.0 or newer.

Create the `.env` file based on the provided example:

```
cp .env.sample .env
```

Replace the dummy values in `.env` file with real ones.

Run app:

```
docker-compose up app
```

Run tests:

```
docker-compose up tests
```

### The Native Way

Prerequisites: ruby v. 2.6.5.

Export the necessary variables in your shell (or in your shell RC file, e.g. `.zshrc`/`.bashrc`), replacing `<VALUE>` with the real values:

```
export MB_CONTENTFUL_ACCESS_TOKEN=<VALUE>
export MB_CONTENTFUL_ENVIRONMENT_ID=<VALUE>
export MB_CONTENTFUL_SPACE_ID=<VALUE>
```

Run app:

```
./bin/start
```

Run tests:

```
./bin/tests
```

## Usage

One the app starts, visit http://localhost:3000/ in your browser.
