# SUPG - Semtech UDP Packet Generator

**SUPG (Semtech UDP Packet Generator)** es un simulador ligero de **gateways y dispositivos LoRaWAN** utilizado para generar tráfico de prueba mediante el protocolo **Semtech UDP**.

Este repositorio contiene el proyecto SUPG y las adaptaciones realizadas para utilizarlo como simulador dentro de la plataforma **FOTON-IA**.

El objetivo principal dentro de FOTON-IA es permitir pruebas de comunicación con **ChirpStack** sin depender inicialmente de gateways y dispositivos LoRaWAN físicos.

---

## 1. ¿Qué es SUPG?

SUPG permite simular una infraestructura básica de dispositivos y gateways LoRaWAN.

El simulador puede generar:

* Gateways LoRaWAN.
* Dispositivos LoRaWAN.
* Mensajes uplink.
* Procesamiento de downlinks.
* Frame counters.
* Parámetros de transmisión LoRaWAN.
* Tráfico mediante **Semtech UDP**.

SUPG funciona como una fuente controlada de tráfico para realizar pruebas sobre una infraestructura LoRaWAN.

> **Importante:** SUPG es un simulador. No reemplaza ChirpStack, ChirpStack Gateway Bridge ni el broker MQTT.

---

# 2. Uso de SUPG en FOTON-IA

Dentro de **FOTON-IA**, SUPG se utiliza para generar tráfico LoRaWAN simulado y comprobar el funcionamiento de la infraestructura de comunicación.

El flujo utilizado actualmente es:

```text
┌──────────────┐
│     SUPG     │
│  Simulador   │
└──────┬───────┘
       │
       │ Semtech UDP
       │ UDP :1700
       ▼
┌──────────────────────────┐
│ ChirpStack Gateway       │
│ Bridge                    │
└───────────┬──────────────┘
            │
            │ MQTT
            ▼
┌──────────────────────────┐
│        Mosquitto         │
│       MQTT Broker        │
└───────────┬──────────────┘
            │
            ▼
┌──────────────────────────┐
│       ChirpStack         │
│     Network Server       │
└──────────────────────────┘
```

De esta forma, SUPG permite probar la infraestructura de FOTON-IA sin utilizar hardware LoRaWAN físico.

---

# 3. Flujo de datos

Cuando se ejecuta una simulación, el flujo principal es:

```text
SUPG
 │
 │ Semtech UDP :1700
 ▼
ChirpStack Gateway Bridge
 │
 │ MQTT
 ▼
Mosquitto
 │
 ▼
ChirpStack
```

El proceso general es:

1. SUPG genera un paquete LoRaWAN.
2. El paquete se envía mediante Semtech UDP.
3. ChirpStack Gateway Bridge recibe el paquete.
4. Gateway Bridge publica la información mediante MQTT.
5. Mosquitto distribuye el mensaje.
6. ChirpStack procesa el uplink.
7. ChirpStack puede generar un downlink.
8. Gateway Bridge transmite el downlink hacia SUPG.
9. SUPG procesa la respuesta.

---

# 4. Arquitectura Docker utilizada

En el entorno de FOTON-IA, SUPG se ejecuta como un **contenedor Docker independiente** del stack principal de ChirpStack.

SUPG y Gateway Bridge se comunican mediante la red Docker:

```text
chirpstack-lscr_default
```

El destino configurado para SUPG es:

```text
chirpstack-gateway-bridge
```

y el puerto utilizado es:

```text
UDP 1700
```

Por lo tanto, SUPG no necesita utilizar directamente la dirección IP interna del contenedor Gateway Bridge.

La comunicación dentro de Docker es:

```text
┌───────────────────────┐
│     Contenedor SUPG   │
│                       │
│  chirpstack-gateway-  │
│  bridge:1700          │
└───────────┬───────────┘
            │
            │ Docker Network
            │
            ▼
┌───────────────────────┐
│ ChirpStack Gateway    │
│ Bridge                │
│ UDP :1700             │
└───────────────────────┘
```

> **Importante:** la red `chirpstack-lscr_default` pertenece al proyecto de infraestructura `chirpstack-LSCR`. Por esta razón, para realizar la prueba completa contra ChirpStack, el stack de ChirpStack debe estar levantado y conectado a esta red.

---

# 5. Requisitos

## 5.1. Para compilación tradicional

Se requiere:

* Linux.
* Git.
* Git Submodules.
* CMake 3.12 o superior.
* Compilador C++ compatible con **C++14**.

## 5.2. Para utilizar Docker

Se requiere:

* Linux.
* Docker.
* Docker Compose.

Para realizar la integración completa con FOTON-IA también se requiere el stack `chirpstack-LSCR` ejecutándose.

---

# 6. Estructura del proyecto

La estructura principal del proyecto es:

```text
supg/
├── apps/
│   ├── supg.cpp
│   └── supg.toml
│
├── include/
│   └── supg/
│
├── src/
│
├── modules/
│   ├── tinytoml/
│   ├── date/
│   ├── spdlog/
│   ├── cryptopp/
│   ├── cryptopp-cmake/
│   ├── json11/
│   └── argagg/
│
├── scripts/
│   ├── build.sh
│   └── pre-build.sh
│
├── CMakeLists.txt
│
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .gitignore
│
└── supg.docker.toml
```

El directorio `build/` puede utilizarse para archivos generados durante el desarrollo, pero está incluido en `.gitignore` y no debe formar parte del repositorio.

---

# 7. Dependencias mediante Git Submodules

SUPG utiliza varias bibliotecas externas mediante **Git Submodules**.

Entre ellas:

* TinyToml
* date
* spdlog
* Crypto++
* Crypto++ CMake
* json11
* argagg

Por esta razón, cuando se clone el repositorio desde cero se recomienda utilizar:

```bash
git clone --recurse-submodules <URL_DEL_REPOSITORIO>
```

Si el repositorio ya fue clonado sin inicializar los submódulos:

```bash
git submodule update --init --recursive
```

---

# 8. Compilación tradicional

SUPG utiliza **CMake** para realizar la compilación.

Antes de compilar es necesario ejecutar:

```bash
bash scripts/pre-build.sh
```

Este script prepara Crypto++ copiando los archivos CMake necesarios desde:

```text
modules/cryptopp-cmake/
```

hacia:

```text
modules/cryptopp/
```

Después se ejecuta:

```bash
bash scripts/build.sh
```

El script crea el directorio `bin/`, ejecuta CMake y compila el proyecto.

El ejecutable generado es:

```text
bin/supg
```

Durante la configuración de CMake, el archivo:

```text
apps/supg.toml
```

también se copia automáticamente al directorio de compilación como:

```text
bin/supg.toml
```

---

# 9. Ejecución tradicional

Para ejecutar SUPG utilizando un archivo de configuración:

```bash
./bin/supg --config ./bin/supg.toml
```

También se puede especificar otro archivo de configuración:

```bash
./bin/supg --config ./bin/mi-configuracion.toml
```

---

# 10. Configuración

SUPG utiliza archivos de configuración en formato **TOML**.

Una configuración de ejemplo:

```toml
[general]
log_level = 4

[network_server]
host = "localhost"
port = 1700

[simulator]
duration = 60

[simulator.device]
first_eui = "0000000000000000"
first_address = "00000000"
first_network_session_key = "00000000000000000000000000000000"
first_application_session_key = "00000000000000000000000000000000"
count = 1
uplink_interval = 10
f_port = 10
payload = "test_packet_1234"
frequency = 868100000
bandwidth = 125
spreading_factor = 12
f_cnt = 0

[simulator.gateway]
first_id = "0000000000000000"
min_count = 1
max_count = 1
```

## Parámetros principales

| Parámetro                 | Descripción                                  |
| ------------------------- | -------------------------------------------- |
| `general.log_level`       | Nivel de detalle de los logs.                |
| `network_server.host`     | Host o dirección IP del destino UDP.         |
| `network_server.port`     | Puerto UDP del destino.                      |
| `simulator.duration`      | Duración de la simulación en segundos.       |
| `device.first_eui`        | EUI del primer dispositivo simulado.         |
| `device.first_address`    | Dirección del primer dispositivo.            |
| `device.count`            | Número de dispositivos simulados.            |
| `device.uplink_interval`  | Intervalo entre uplinks en segundos.         |
| `device.f_port`           | Puerto LoRaWAN utilizado por el dispositivo. |
| `device.payload`          | Información enviada en el uplink.            |
| `device.frequency`        | Frecuencia de transmisión en Hz.             |
| `device.bandwidth`        | Ancho de banda utilizado.                    |
| `device.spreading_factor` | Spreading Factor utilizado.                  |
| `device.f_cnt`            | Frame Counter inicial.                       |
| `gateway.first_id`        | ID del primer gateway simulado.              |
| `gateway.min_count`       | Número mínimo de gateways utilizados.        |
| `gateway.max_count`       | Número máximo de gateways utilizados.        |

---

# 11. Configuración para Docker

Para ejecutar SUPG dentro de Docker se utiliza:

```text
supg.docker.toml
```

La diferencia principal respecto a la configuración local es el destino del Gateway Bridge:

```toml
[network_server]
host = "chirpstack-gateway-bridge"
port = 1700
```

El nombre:

```text
chirpstack-gateway-bridge
```

es resuelto mediante el DNS interno de Docker dentro de la red:

```text
chirpstack-lscr_default
```

La configuración utilizada en las pruebas de FOTON-IA es:

```text
Duración:          60 segundos
Dispositivos:      1
Uplink interval:   10 segundos
FPort:              10
Frecuencia:        915.2 MHz
Bandwidth:         125 kHz
Spreading Factor:  7
```

---

# 12. Ejecutar SUPG con Docker

El proyecto incluye un `Dockerfile` que compila SUPG dentro de una etapa de construcción y posteriormente crea una imagen más pequeña para ejecutar el simulador.

El flujo es:

```text
Código fuente
     │
     ▼
Dockerfile
     │
     ▼
Etapa builder
     │
     │ CMake + compilación
     ▼
Ejecutable supg
     │
     ▼
Etapa runtime
     │
     ▼
Imagen Docker
```

Para construir la imagen y ejecutar el contenedor:

```bash
docker compose up --build
```

El contenedor se conecta a:

```text
chirpstack-lscr_default
```

y utiliza:

```text
chirpstack-gateway-bridge:1700
```

como destino de los paquetes Semtech UDP.

---

# 13. Verificar el contenedor

Después de ejecutar la simulación se puede comprobar su estado con:

```bash
docker compose ps -a
```

Para consultar los logs:

```bash
docker logs supg-standalone-1
```

Una ejecución correcta debe finalizar con código:

```text
Exited (0)
```

Los logs básicos del simulador muestran:

```text
[info] [CONFIG]
[info] [RUN]
[info] [STOP]
```

La duración depende del parámetro:

```toml
[simulator]
duration = 60
```

---

# 14. Prueba de integración realizada

Se realizó una prueba de integración utilizando el entorno Docker de FOTON-IA.

Configuración utilizada:

```text
Duración:          60 segundos
Dispositivos:      1
Uplink:            cada 10 segundos
Frecuencia:        915.2 MHz
Bandwidth:         125 kHz
Spreading Factor:  7
FPort:              10
```

Durante la prueba se verificó el flujo:

```text
SUPG
 ↓
Semtech UDP :1700
 ↓
ChirpStack Gateway Bridge
 ↓
MQTT
 ↓
Mosquitto
 ↓
ChirpStack
```

Los logs de Gateway Bridge mostraron la recepción de los paquetes enviados por SUPG.

Los logs de ChirpStack permitieron comprobar posteriormente:

* recepción de uplinks;
* información del gateway;
* procesamiento mediante Redis;
* eventos de aplicación;
* generación de métricas;
* generación de downlinks;
* recepción de ACK.

Por lo tanto, se comprobó el funcionamiento de extremo a extremo del flujo de comunicación utilizado en las pruebas de FOTON-IA.

---

# 15. Adaptaciones realizadas para FOTON-IA

El código original de SUPG fue adaptado para integrarlo con el entorno Docker y la configuración LoRaWAN utilizada en FOTON-IA.

## 15.1. Inclusión de `<cstdint>`

Archivo:

```text
include/supg/util/data_types.h
```

Se agregó:

```cpp
#include <cstdint>
```

Esto permite utilizar explícitamente tipos enteros de ancho fijo proporcionados por C++, como `uint64_t`.

---

## 15.2. Inclusión de `<stdexcept>`

Archivo:

```text
include/supg/util/channel.h
```

Se agregó:

```cpp
#include <stdexcept>
```

Esto permite utilizar las excepciones correspondientes de la biblioteca estándar.

---

## 15.3. Soporte para nombres de host

Archivo:

```text
src/core/simulator.cpp
```

El código fue adaptado para permitir que `network_server.host` pueda utilizar tanto:

* una dirección IPv4;
* un nombre de host.

Esto permite utilizar:

```text
chirpstack-gateway-bridge
```

como destino dentro de Docker.

El simulador intenta resolver el destino mediante DNS cuando el valor configurado no corresponde a una dirección IPv4.

Si el host no puede resolverse, el simulador genera un error indicando que no pudo resolver el destino.

---

## 15.4. Corrección de la Application Session Key

Se corrigió la utilización de la clave correspondiente a la **Application Session Key** durante la inicialización del dispositivo.

Esto evita utilizar incorrectamente la Network Session Key en ese punto del proceso.

---

## 15.5. Corrección del Code Rate

Se modificó el Code Rate utilizado por el simulador:

```text
3/4
```

a:

```text
4/5
```

Esta modificación fue necesaria porque Gateway Bridge estaba rechazando anteriormente los paquetes debido a un Code Rate no válido para la configuración utilizada.

Después de esta modificación, la prueba de integración no presentó el error:

```text
invalid CodR: 3/4
```

---

# 16. Problemas comunes

## 16.1. Gateway Bridge no recibe paquetes

Verificar que los contenedores de ChirpStack estén ejecutándose:

```bash
docker ps
```

Comprobar que Gateway Bridge tenga disponible el puerto UDP:

```text
1700/udp
```

También verificar que SUPG y Gateway Bridge estén conectados a la misma red Docker.

---

## 16.2. Docker no puede resolver `chirpstack-gateway-bridge`

Comprobar las redes disponibles:

```bash
docker network ls
```

Debe existir:

```text
chirpstack-lscr_default
```

También verificar que Gateway Bridge esté conectado a esta red.

---

## 16.3. Error `invalid CodR`

Si Gateway Bridge muestra:

```text
invalid CodR: 3/4
```

verificar el Code Rate utilizado por SUPG.

La versión adaptada para FOTON-IA utiliza:

```text
4/5
```

---

## 16.4. Problemas con Frame Counters

Al ejecutar varias veces una simulación utilizando los mismos dispositivos, ChirpStack puede rechazar los paquetes si el `f_cnt` entra en conflicto con el estado registrado del dispositivo.

En ese caso se debe revisar:

```toml
f_cnt = 0
```

y ajustar el valor según el estado del dispositivo utilizado en ChirpStack.

---

# 17. SUPG vs. ChirpStack

Es importante diferenciar las responsabilidades de cada componente:

| Componente                    | Responsabilidad                                      |
| ----------------------------- | ---------------------------------------------------- |
| **SUPG**                      | Simular gateways y dispositivos LoRaWAN              |
| **ChirpStack Gateway Bridge** | Recibir el tráfico Semtech UDP e integrarlo con MQTT |
| **Mosquitto**                 | Actuar como broker MQTT                              |
| **ChirpStack**                | Procesar y administrar la red LoRaWAN                |

SUPG **no reemplaza** ninguno de los componentes de la infraestructura de ChirpStack.

Su función dentro de FOTON-IA es proporcionar una fuente de tráfico LoRaWAN controlada para realizar pruebas de la infraestructura.

---

# 18. Notas importantes

### Frame Counter

Si se ejecuta repetidamente una simulación con los mismos dispositivos, puede ser necesario modificar `f_cnt` para evitar conflictos con los contadores registrados en ChirpStack.

### Configuración de claves

Los valores de claves incluidos en las configuraciones de ejemplo son valores de prueba y no deben considerarse credenciales reales de producción.

### Red Docker

El archivo `docker-compose.yml` utiliza una red externa:

```text
chirpstack-lscr_default
```

Esta red debe existir antes de ejecutar la integración con el stack de ChirpStack.

### Separación de proyectos

SUPG y `chirpstack-LSCR` son proyectos independientes.

SUPG proporciona el tráfico simulado, mientras que `chirpstack-LSCR` proporciona la infraestructura de ChirpStack.

---

# 19. Licencia

Este proyecto conserva la licencia **MIT** del proyecto original de SUPG.

Consulte el archivo de licencia incluido en el repositorio para conocer los términos completos.

---

## Referencias

* [ChirpStack](https://www.chirpstack.io/)
* [ChirpStack Gateway Bridge](https://www.chirpstack.io/docs/gateway-bridge/)
* [CMake](https://cmake.org/)
* [Docker](https://www.docker.com/)
* [LoRa Alliance](https://lora-alliance.org/)
