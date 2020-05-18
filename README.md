# Monitor ERD Node with Telegraf+Grafana

_In this guide we are going to see how to install and configure Grafana + Influxdb + Telegraf to monitor a node based on Ubuntu 18.0.4._

## Pre-requisitos 📋
 
 Este documento no cubre la instalación de Ubuntu ni el nodo de Elrond. Hay muy buenas guías para ello. 

## Agenda
   1. Añadir repositorios necesarios para instalar Grafana + Influxdb + Telegraf
  
   2. Instalar paquetes. Dependiendo de tu diseño, se hará todo en el mismo servidor donde tengas el nodo o en nodos separados. Telegraf siempre deberá de correr en el nodo. Grafana e Influxdb pueden correr fuera en otro server.
  
   3. Crear base de datos en Influxdb + usuario de acceso.
  
   4. Configurar Telegraf para leer información del nodo y enviarla a la base de datos Influxdb recién creada.
  
   5. Configurar Grafana y agregar el oriegen de datos recién creado de Influxdb para hacer consultas a los datos que se vayan almacenando ahí.
  
   6. Importar dashboard para tener información útil del estado del nodo.


## Comenzando 🚀

Vamos a añadir los repositorios necesarios :

 #### _1. Añadir repositorios. (https://docs.influxdata.com/telegraf/v1.14/introduction/installation/#)_
    
   Influxdb + Telegraf :
    
    wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
    source /etc/lsb-release
    echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
           
   Grafana :
    
   Añadimos la rama estable  de la versión enterprise que tiene lo mismo que la "open source" pero nos permite suscribirnos en cualquier momento del futuro sin hacer nada.
    
    sudo add-apt-repository "deb https://packages.grafana.com/enterprise/deb stable main"

#### 2. Instalar paquetes
   Influxdb + Telegraf :
    
    sudo apt-get update && sudo apt-get install apt-transport-https
    sudo apt-get update && sudo apt-get install telegraf influxdb
    sudo service telegraf start 
    sudo service influxdb start 
   
   Grafana :  (https://grafana.com/docs/grafana/latest/installation/debian/)
            
    sudo apt-get install -y software-properties-common wget
    wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
    sudo apt-get update
    sudo apt-get install grafana
    sudo service grafana-server start

#### _3. Vamos a crear la base de datos en Influxdb para que Telegraf pueda guardar toda la info relativa al nodo_
    
   Con este comando entramos en la consola de influxdb para poder lanzar comandos, crear bases de datos, usuarios, etc..
         
         influx 
   Cremaos la base de datos llamada "telegraf". Podmeos dar le nombre que queramos pero es bueno que dejemos telegraf para que luego el dashboard al importarlo en grafana funcione bien.
   
        create database telegraf   
   Creamos el usuario "telegraf" con password "lo que sea". Aquí puedes poner el user/pass que quieras, no es relevante. Lo usaremos en el archivo de telegraf.conf para hacer insert a la base de datos. 
   
        create user telegraf with password 'contraseña'  
  
   Muestra las bases de datos disposibles, entre ellas la nuestra
  
         show databases                    
            > show databases
            name: databases
            name
            ----
            _internal
            telegraf
 Nos muestra los usuarios
 
         show users                        
            user     admin
            ----     -----
            telegraf false


Mira **Deployment** para conocer como desplegar el proyecto.


### Pre-requisitos 📋

_Que cosas necesitas para instalar el software y como instalarlas_

```
Da un ejemplo
```

### Instalación 🔧

_Una serie de ejemplos paso a paso que te dice lo que debes ejecutar para tener un entorno de desarrollo ejecutandose_

_Dí cómo será ese paso_

```
Da un ejemplo
```

_Y repite_

```
hasta finalizar
```

_Finaliza con un ejemplo de cómo obtener datos del sistema o como usarlos para una pequeña demo_

## Ejecutando las pruebas ⚙️

_Explica como ejecutar las pruebas automatizadas para este sistema_

### Analice las pruebas end-to-end 🔩

_Explica que verifican estas pruebas y por qué_

```
Da un ejemplo
```

### Y las pruebas de estilo de codificación ⌨️

_Explica que verifican estas pruebas y por qué_

```
Da un ejemplo
```

## Despliegue 📦

_Agrega notas adicionales sobre como hacer deploy_

## Construido con 🛠️

_Menciona las herramientas que utilizaste para crear tu proyecto_

* [Dropwizard](http://www.dropwizard.io/1.0.2/docs/) - El framework web usado
* [Maven](https://maven.apache.org/) - Manejador de dependencias
* [ROME](https://rometools.github.io/rome/) - Usado para generar RSS

## Contribuyendo 🖇️

Por favor lee el [CONTRIBUTING.md](https://gist.github.com/villanuevand/xxxxxx) para detalles de nuestro código de conducta, y el proceso para enviarnos pull requests.

## Wiki 📖

Puedes encontrar mucho más de cómo utilizar este proyecto en nuestra [Wiki](https://github.com/tu/proyecto/wiki)

## Versionado 📌

Usamos [SemVer](http://semver.org/) para el versionado. Para todas las versiones disponibles, mira los [tags en este repositorio](https://github.com/tu/proyecto/tags).

## Autores ✒️

_Menciona a todos aquellos que ayudaron a levantar el proyecto desde sus inicios_

* **Andrés Villanueva** - *Trabajo Inicial* - [villanuevand](https://github.com/villanuevand)
* **Fulanito Detal** - *Documentación* - [fulanitodetal](#fulanito-de-tal)

También puedes mirar la lista de todos los [contribuyentes](https://github.com/your/project/contributors) quíenes han participado en este proyecto. 

## Licencia 📄

Este proyecto está bajo la Licencia (Tu Licencia) - mira el archivo [LICENSE.md](LICENSE.md) para detalles

## Expresiones de Gratitud 🎁

* Comenta a otros sobre este proyecto 📢
* Invita una cerveza 🍺 o un café ☕ a alguien del equipo. 
* Da las gracias públicamente 🤓.
* etc.



---
⌨️ con ❤️ por [Villanuevand](https://github.com/Villanuevand) 😊

