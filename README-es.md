# Monitor ERD Node with Telegraf+Grafana

In this guide we are going to see how to install and configure Grafana + Influxdb + Telegraf to monitor a Elrond node based on Ubuntu 18.0.4.

## Pre-requisitos 📋
 
 Este documento no cubre la instalación de Ubuntu ni el nodo de Elrond. Hay muy buenas guías para ello. 

## Agenda
   1. Añadir repositorios necesarios para instalar Grafana + Influxdb + Telegraf
  
   2. Instalar paquetes. Dependiendo de tu diseño, se hará todo en el mismo servidor donde tengas el nodo o en nodos separados. Telegraf siempre deberá de correr en el nodo. Grafana e Influxdb pueden correr fuera en otro server.
  
   3. Crear base de datos en Influxdb + usuario de acceso.
  
   4. Configurar Telegraf para leer información del nodo y enviarla a la base de datos Influxdb recién creada.
  
   5. Configurar Grafana y agregar el oriegen de datos recién creado de Influxdb para hacer consultas a los datos que se vayan almacenando ahí.
  
   6. Importar dashboard para tener información útil del estado del nodo.
   
   7. Alertas via Telegram. 


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
Cada nodo cuando inicia lanza un servicio escuchando en el puerto 8080 para el primer nodo, 8081 para el segundo, 808X para los siguientes. Podemos acceder a ese servicio mediante el siguiente comando : 

    cd /home/tu-usuario/elrond-utils/
    
    ./termui -address localhost:8080
El script check_erd_node_metrics_X lo que hace es hacer uso de esa información de una forma muy sencilla : 
      
    cd /etc/telegraf/
    vim check_erd_node_metrics_0   

Pegamos el siguiente contenido :

    #!/bin/bash
   
    OUTPUT=`curl -s 127.0.0.1:8080/node/status 2>/dev/null | jq ".details // empty"` # returns "" when null  
      
    ret=$?
    if [ -z "${OUTPUT}" ] || [ ${ret} -ne 0 ]; then
       echo "NODE NOT RUNNING!!"
       exit 2 
    fi
    echo ${OUTPUT}
Guardar los cambios, hacer el archivo ejecutable y hacer a telegraf propietario : 

    chmod +x check_erd_node_metrics_0
    chown telegraf check_erd_node_metrics_0 

Probamos que todo funcione :

    sudo telegraf telegraf --config telegraf.conf
    
Si ves algo como lo siguiente, es que todo ha ido bien : 

    2020-05-17T17:57:32Z I! Starting Telegraf 1.14.2
    2020-05-17T17:57:32Z I! Using config file: /etc/telegraf/telegraf.conf
    2020-05-17T17:57:32Z I! Loaded inputs: exec exec exec diskio net swap kernel netstat processes cpu disk mem system
    2020-05-17T17:57:32Z I! Loaded aggregators: 
    2020-05-17T17:57:32Z I! Loaded processors: 
    2020-05-17T17:57:32Z I! Loaded outputs: influxdb
    2020-05-17T17:57:32Z I! Tags enabled: host=erd.node
    2020-05-17T17:57:32Z I! [agent] Config: Interval:1m0s, Quiet:false, Hostname:"erd.node", Flush Interval:1m0s


#### 5. Configurar Grafana.
Grafana por defecto escucha en el puerto 3000. Así que deberás escribir la ip-your-server:3000 para acceder a su entoreno web : 
     
     http://IP:address:3000

![login](https://user-images.githubusercontent.com/16337441/82241923-3e918380-993d-11ea-9efd-709c82ffcffa.png)

El usuario y contraseña por defecto son  admin/admin. Te pedirá que cambies la contraseña. 

![password](https://user-images.githubusercontent.com/16337441/82241938-42250a80-993d-11ea-8e6d-8ade7f7d6225.png)

Ya estamos dentro!! 

![data_source](https://user-images.githubusercontent.com/16337441/82241953-481aeb80-993d-11ea-9e98-69f24a21357b.png)

Ahora hay que agregar un origen de datos : InfluxDB en nuestro caso. 

![InfluxDB Settings Grafana](https://user-images.githubusercontent.com/16337441/82244171-1e63c380-9941-11ea-9c0e-5c5657fe5caa.png)

#### 6. Importar el dashboard. 
Usa el .json **erd_dashboard.json** que comparto como plantilla para tener rápidamente información en tu dashboard. 
Tendrás que hacer algunos ajustes en las consultas de los diferentes gráficos si has puesto otro nombre a tu nodo.

![import_json](https://user-images.githubusercontent.com/16337441/82244777-0b052800-9942-11ea-88e1-2750460ecf9d.png)

Algunas imágenes de los dashboard : 


![erd_node_status](https://user-images.githubusercontent.com/16337441/82245314-012ff480-9943-11ea-811c-6ab05206f046.png)
![erd_node_performace](https://user-images.githubusercontent.com/16337441/82245319-02f9b800-9943-11ea-8bce-128128d51560.png)


#### 7. Alertas vía Telegram. 

To receive notifications on telegram we’ll need to create a new Telegram bot. 

#### Create your bot
Open your telegram app and search for the user @BotFather and write this message:
  
    /newbot
This is a command that tells the @BotFather to create you a new bot. 
         
![telegram_bot](https://user-images.githubusercontent.com/16337441/82247637-042ce400-9947-11ea-89e8-c5c76b218400.png)

Save your "Token ID". Now, create a new group in telegram, for example : Erd Alerts. Add to this group your bot, in this example "My first bot" was the name that used it. 
To know your chat-id you can add a @RawDataBot. This bot send to group a message with all info related to group. Something like this : 

    "chat": {
            "id": -457484388,    <-- this is your chat-id
            "title": "Alerts ERD",
            "type": "group",

Now in Grafana we go to create a new "Notification Channel". This image explain itself. 

![erd_node_telegram](https://user-images.githubusercontent.com/16337441/82247820-566e0500-9947-11ea-9dd8-d2525012c9e7.png)

Test it !! 

