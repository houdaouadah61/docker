# Examen 

## 1 Build

```bash
docker build -t examen .
```

## 2 Run (mêmes identifiants partout)

```bash
docker run --rm -it -p 80:80 \
  -e BASIC_USER=houdadh -e BASIC_PASS=Helloearth1234 \
  -e MYSQL_DATABASE=wordpress -e MYSQL_USER=houdadh -e MYSQL_PASSWORD=Helloearth1234 \
  -e AUTO_INDEX=off \
  examen
```

## 3 URLs à tester

* [http://localhost/wordpress/](http://localhost/wordpress/) (WordPress)
* [http://localhost/phpmyadmin/](http://localhost/phpmyadmin/) (phpMyAdmin)


## 4 Identifiants

### Popup navigateur (Basic Auth)

* User: houdadh
* Pass: Helloearth1234

### phpMyAdmin (MySQL)

* User: houdadh
* Pass: Helloearth1234

## 5 Autoindex (ENV)

### OFF

```
