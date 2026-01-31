# Nomad Quarkus Reference Arch

Este proyecto tiene por objetivo mostrar cómo se puede tener una arquitectura escalable en HashiCorp Nomad + Consul, y con balanceador Fabio.

La aplicación está hecha en Quarkus y se conectará a una base de datos MariaDB

Tanto MariaDB como la aplicación Quarkus se ejecutarán en una imagen Docker.

Aquí se indicarán los pasos a seguir.

## Construcción de la aplicación

Existe el archivo [Dockerfile.jvm](nomad-quarkus/src/main/docker/Dockerfile.jvm) para poder construir la imagen. Antes de crear la imagen, debemos construir la aplicación. Debemos hacerlo dentro de la carpeta del proyecto maven:

```bash
cd nomad-quarkus
```

Luego:

```bash
./mvnw clean package -DskipTests
```

Con esto creará el archivo UberJar.

```bash
docker build -f src/main/docker/Dockerfile.jvm -t quarkus/nomad-quarkus-jvm:0.0.1 .
```

Construimos la imagen, y tendrá por nombre `quarkus/nomad-quarkus-jvm:0.0.1` OJO. No usar `latest` como tag, porque Nomad no reconoce la reconoce.

## Configurando el entorno

Existe el archivo [setup.sh](setup.sh) que tiene todos los pasos para instalar tanto el JDK, Consul y Nomad, en caso no existan.

## Ejecución de los entorno

Necesitamos tres terminales en ejecución, al que llamaremos: "consul", "nomad" y "deploy"

En el primer terminal, ejecutaremos el comando:

```bash
consul agent -dev -client 0.0.0.0
```

En el segundo terminal, ejecutaremos el comando:

```bash
sudo nomad agent -dev -bind=0.0.0.0 -network-interface=eth0 -log-level=DEBUG
```

Y en el tercer terminal, nos ubicaremos en este mismo directorio, donde se encuentra el archivo [stack.nomad](stack.nomad), y ejecutaremos el comando:

```bash
nomad job run stack.nomad
```

## Verificando estados

Para obtener el estado del despliegue, debemos ejecutar los siguientes comandos

```bash
nomad status revuelta-stack
```

Esto nos mostrará el estado del despliegue. En la parte inferior se verán los ID de los allocations creados. Por ejemplo:

```
Allocations
ID        Node ID   Task Group    Version  Desired  Status   Created     Modified
ca6e2bd4  95dbb39f  aplicacion    0        run      running  27m13s ago  26m50s ago
e4f4429b  95dbb39f  loadbalancer  0        run      running  27m13s ago  27m2s ago

```

Si queremos ver el detalle de `loadbalancer`, porque queremos ver el IP que le fue asignado, usamos el ID de su allocation:

```bash
nomad status e4f4429b
```

Parte del resultado es como este:

```
Allocation Addresses:
Label  Dynamic  Address
*lb    yes      172.25.212.178:9999
*ui    yes      172.25.212.178:9998
```

Para ver la aplicación funcionando, tomamos el IP de la etiqueta `lb` , por ejemplo:

```bash
http 172.25.212.178:9999/api
```
Este debería ser el resultado:

![](https://imgur.com/jtlavCd)

## Pruebas de Stress

Usaremos k6, para ello instalaremos la aplicación

```bash
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

El script con la prueba de stress es [stress-load.js](stress-load.js).

En la línea 15 se deberá colocar el IP que se obtuvo del allocation del LB que se mencionó en la sección anterior.

Luego, ejecutar el siguiente comando:

```bash
k6 run stress-load.js
```


## Detener el despliegue

Para detener y borrar el despliegue, ejecutamos el comando

```bash
nomad  job stop --purge revuelta-stack
```