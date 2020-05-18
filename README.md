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

#### 3. Vamos a crear la base de datos en Influxdb para que Telegraf pueda guardar toda la info relativa al nodo
    
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
 #### 4. Configurar Telegraf 

Ahora que ya tenemos influxdb esperando datos, vamos a configurar telegraf para que lea métricas del nodo y las envíe a la base de datos. El archivo de configuración de telegraf está en "/etc/telegraf/telegraf.conf". 
Este archivo por defecto trae un muchos "inputs" que permiten leer métricas de todo tipo de servicios (mysql, apache, nginx, postfix, red, cpu, etc...). Vamos a guardar este archivo como backup y vamos a crear un archivo desde 0 más limpio y sólo con los inputs que necesitamos. Así todo será más fácil :)

      ##################### Global Agent Configuration #########################
        [agent]
        hostname = "erd.node"           
        flush_interval = "60s"        
        interval = "60s"               

        # Input Plugins                
        [[inputs.cpu]]
            percpu = true
            totalcpu = true
            collect_cpu_time = false
            report_active = false
        [[inputs.disk]]
            ignore_fs = ["tmpfs", "devtmpfs", "devfs"]
        [[inputs.io]]
        [[inputs.mem]]
        [[inputs.net]]
        [[inputs.system]]
        [[inputs.swap]]
        [[inputs.netstat]]
        [[inputs.processes]]
        [[inputs.kernel]]

        # Output Plugin InfluxDB       
        [[outputs.influxdb]]           
        database = "telegraf"          
        urls = [ "http://127.0.0.1:8086" ]
        username = "telegraf"        
        password = "loquesea"         
        
        [[inputs.exec]]                     
        commands = ["/etc/telegraf/check_erd_node_metrics_0"]
        timeout = "5s"                        
        name_override = "node0_stats"       
        data_format = "json"            
        json_string_fields = ["erd_node_type","erd_peer_type"]
#### Puntos importantes del archivo : 

Nombre que quieres enviar a la base de datos y será el que luego uses en las consultas en Grafana. 

    hostname = "erd.node"  
Intervalo, cada cuanto tiempo quieres leer la info. 
       
    interval = "60s"
Conexión con InfluxDB. Vamos a declarar un "output" basado en influxdb para decirle a telegraf que lo use para almacenar ahí las métricas. Usamos los datos del punto 3 de esta guía. 

Si nuestro servidor influxdb está en la misma máquina que telegraf. 
    
    urls = [ "http://127.0.0.1:8086" ]   
Si hemos instalado influxdb y grafana en otro servidor 

    urls = [ "http://YOUR-SERVER-IP:8086" ]  

Vamos a definir un "input" del tipo de exec. Este tipo de input es un plugin le dice a telegraf que debe de ejecutar un comando en cada intervalo y hace un "output" en el formato que le digamos. 

    [[inputs.exec]]

Path al el script que nos servirá como input y nos dará datos para poder enviar a influxdb. Le podéis poner el nombre que queráis.
    
    commands = ["/etc/telegraf/check_erd_node_metrics_0"]
Nombre de la métrica. Este nombre es el que vamos a ver en Grafana y el que vamos a seleccionar para acceder a todas las métricas. Imagínalo como una tabla dentro de la base de datos.  

    name_override = "node0_stats"
Importante : formato en el que vamos a recibir la informamción del script. En nuestro caso será json.

    data_format = "json"

Esta opción nos permite enviar cadenas de texto como output. Sin esta config las variables leidas  erd_node_type","erd_peer_type" que tiene cadenas de texto no se almacenarían y no las tendríamos disponibles en grafana para poder mostrarlas en nuestros dashboard. 

    json_string_fields = ["erd_node_type","erd_peer_type"]

Si quisiérmos confiugrar más nodos debemos de agregar más inputs con : el script que leerá del nodo y cambiamos el nombre. Por ejemplo : 

      [[inputs.exec]]
        commands = ["/etc/telegraf/check_erd_node_metrics_1"]
        timeout = "5s"
        name_override = "node1_stats"
        data_format = "json"
        json_string_fields = ["erd_node_type","erd_peer_type"]

        [[inputs.exec]]
        commands = ["/etc/telegraf/check_erd_node_metrics_2"]
        timeout = "5s"
        name_override = "node2_stats"
        data_format = "json"
        json_string_fields = ["erd_node_type","erd_peer_type"]
  
  #### 4.1 Script para leer información del nodo.       
Por defecto al instalar un node se crean varios directorios dentro del home del usuario que hemos usado para instalar. 
Una de estas carpetas es "/elrond-utils" donde tenemos dos herramientas que nos ayudan a tener una visón en tiempo real del nodo mediante CLI : logviewer y termui. 
Cada nodo cuando inica lanza un servicio escuchando en el puerto 8080 para el primer nodo, 8081 para el segundo, 808X para los sguientes. Podemos acceder a ese servicio mediante el siguiente comando : 

    cd /home/tu-usuario/elrond-utils/
    
    ./termui -address localhost:8080
        



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

