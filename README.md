# Tubo

**Tubo** is a small utility to generate compressed dumps from MySQL databases, upload them to a
[transfer.sh](https://transfer.sh) service and provide you with a link you can use to download and/or
share with your team.

If you're using **Tubo** alone, you'll see little advantages in its use, as it may look as a simple
script -- that's because its greater power comes when it is used in combination with
[`cmd_as_service`](https://github.com/chrodriguez/cmd_as_service).

The main idea of its combined usage is something like this:

* You send a request to start the `cmd_as_service` running **Tubo**, providing the database name as the only argument
  for the command:

  ```console
  $ curl -d 'args=my_database' https://tubo-cmd-as-service.example.org
  ```

* You confirm the action on the email you get when triggering a new command.
* **Tubo** is run.
* You get an email stating the result of the requested command, which will contain in its `stdout` the URL for the dump
  that has just been created and uploaded to the remote transfer.sh service.

## Configuration

Any configuration values that define how to access the remote database and the remote should be passed in via
environment variables. The only value that's expected to be passed in as an argument to the script is the name of the
database to be dumped.

Available environment variables are:

| Variable       | Required? | Default value | Description                                        |
| -------------- | --------- | ------------- | -------------------------------------------------- |
| `TRANSFER_URL` | Yes       |               | URL for the remote transfer.sh service             |
| `TUBO_USER`    | No        | `root`        | User to access the MySQL database                  |
| `TUBO_PASS`    | No        |               | Password to access the MySQL database              |
| `TUBO_HOST`    | No        | `localhost`   | Remote hostname to connect to the MySQL database   |
| `EXPIRE_IN`    | No        | `1`           | Number of days the dump files will be downloadable |

## Standalone (script) usage

You may use **Tubo** directly as a script, in which case you need to provide the environment variables described in the
previous section, like this:

```console
$ TRANSFER_URL=https://transfer.sh TUBO_USER=client TUBO_HOST=mysql.example.org EXPIRE_IN=3 ./bin/tubo my_database
https://transfer.sh/fGjdsn/my_database-2017-12-15.sql.gz
```

This will create a compressed dump of the database named `my_database` from the MySQL instance running on
`mysql.example.org` using `client` as the user to connect to the database, with no password. The download link will be
available for 3 days on the remote transfer.sh service running on https://transfer.sh.

> The first line in the previous snippet is the way you execute the script, and the second one is its output: a link to
  the downloadable dump file.

Please note that in order to run **Tubo** as a standalone script, you'll need `curl`, `gzip` and `mysqldump` installed
on the system.

## Usage with Docker

For convenience, you may want to execute **Tubo** using Docker, in which case the example shown in the previous section
would be like this:

```console
$ docker run --rm \
             -e TRANSFER_URL=https://transfer.sh \
             -e TUBO_USER=client \
             -e TUBO_HOST=mysql.example.org \
             -e EXPIRE_IN=3 \
             ncuesta/tubo \
             my_database
https://transfer.sh/fGjdsn/my_database-2017-12-15.sql.gz
```

> The first line in the previous snippet is the way you run the docker container, and the second one is its output: a
  link to the downloadable dump file.

## Usage with `cmd_as_service`

Another way of running **Tubo** is to have it triggered on demand by `cmd_as_service`. To do so, you'll need to use a
different Docker image and pass in any environment variables required by `cmd_as_service`.

> Please refer to [the documentation for `cmd_as_service`](https://github.com/chrodriguez/cmd_as_service) in order to
  have an up-to-date detail of which values you need to provide for it.

An example of how to run **Tubo** + `cmd_as_service` using the provided Docker image follows:

```console
$ docker run --rm \
             # values for Tubo
             -e TRANSFER_URL=https://transfer.sh \
             -e TUBO_USER=client \
             -e TUBO_HOST=mysql.example.org \
             -e EXPIRE_IN=3 \
             # values for cmd_as_service
             -e MAIL_TO=user@gmail.com \
             -e MAIL_FROM=user@gmail.com \
             -e MAIL_HOST=smtp.gmail.com \
             -e MAIL_PORT=587 \
             -e MAIL_USER=user@gmail.com \
             -e MAIL_PASS=**** \
             -e MAIL_AUTH=plain \
             -e MAIL_STARTTLS=true \
             # the port to publish cmd_as_service at
             -p 9292:9292 \
             ncuesta/tubo:cmd
```

Once you have that image running, you can `curl` requests into it to get your dumps:

```console
$ curl -d 'args=my_database' localhost:9292
```

After that, the usual workflow from `cmd_as_service` applies. Once you've confirmed the command to be run and it
finishes, you'll get an email with the download link for the generated dump attached as `stdout.txt`. If anything should
go wrong, you'll get the output for `stderr` attached to the email as `stderr.txt`.
