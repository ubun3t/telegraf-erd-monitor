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
