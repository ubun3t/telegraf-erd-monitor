# Monitor ERD Node with Telegraf+Grafana

In this guide we are going to see how to install and configure Grafana + Influxdb + Telegraf to monitor a Elrond node based on Ubuntu 18.0.4.

## Pre requirements 📋
 
 This document does not cover Ubuntu installation or Elrond node. There are very good guides for this.
 
 https://docs.elrond.com/validators/system-requirements

## Agenda
   1. Add necessary repositories to install Grafana + Influxdb + Telegraf
  
   2. Install packages. Depending on your design, everything will be done on the same server where you have the node or on separate nodes. Telegraf should always run on the node. Grafana and Influxdb can run outside on another server.
  
   3. Create database on Influxdb + login user.
  
   4. Configure Telegraf to read node information and send it to the newly created Influxdb database.
  
   5. Configure Grafana and add the newly created data source of Influxdb to query the data that is stored there.
  
   6. Import dashboard to have useful information on node status.
   
   7. Alerts via Telegram. 


## Starting  🚀

We are going to add the necessary repositories:

 #### 1. Add repositories. (https://docs.influxdata.com/telegraf/v1.14/introduction/installation/#)
    
   Influxdb + Telegraf :
    
    wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
    source /etc/lsb-release
    echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
           
   Grafana :
    
   We add the stable branch of the enterprise version that has the same as the "open source" but allows us to subscribe at any time in the future without doing anything.
    
    sudo add-apt-repository "deb https://packages.grafana.com/enterprise/deb stable main"

#### 2. Install packages
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

#### 3. We are going to create the database in Influxdb so that Telegraf can save all the information related to the node
    
 With this command we enter the influxdb console to be able to launch commands, create databases, users, etc.
         
         influx 
         
 We create the database called "telegraf". 
   
        create database telegraf   
 
 We create the user "telegraf" with password "whatever". Here you can put the user / pass you want, it is not relevant. We will use it in the telegraf.conf file to insert the database.
   
        create user telegraf with password 'password-change'  
  
 Show available databases, including ours :
  
         show databases                    
            > show databases
            name: databases
            name
            ----
            _internal
            telegraf
 Users :
 
         show users                        
            user     admin
            ----     -----
            telegraf false
            
 #### 4. Config Telegraf 

Now that we have influxdb waiting for data, we are going to configure telegraf to read node metrics and send them to the database. The telegraf configuration file is at "/etc/telegraf/telegraf.conf".
This file by default has many "inputs" that allow metrics to be read from all kinds of services (mysql, apache, nginx, postfix, network, cpu, etc ...). We are going to save this file as a backup and we are going to create a cleaner file from 0 and only with the inputs that we need. This will make everything easier :)

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
#### Important points of the file : 

Name that you want to send to the database and it will be the one that you later use in the queries in Grafana. 

    hostname = "erd.node"  
Interval, how often do you want to read the info.       
    
    interval = "60s"
    
InfluxDB connection. We are going to declare an "output" based on influexdb to tell telegraf to use it to store metrics there. We use the data from point 3 of this guide.

If our server influxdb is on the same machine as telegraph.
    
    urls = [ "http://127.0.0.1:8086" ]   
If we have installed influxdb and grafana on another server

    urls = [ "http://YOUR-SERVER-IP:8086" ]  

We are going to define an "input" of the exec type. This type of input is a plugin that tells telegraf that it must execute a command in each interval and it does an "output" in the format that we call it.

    [[inputs.exec]]

Path to the script that will serve as input and will give us data to send to influxdb. You can put the name you want.
    
    commands = ["/etc/telegraf/check_erd_node_metrics_0"]

Metric name. This name is the one that we are going to see in Grafana and the one that we are going to select to access all the metrics. Imagine it as a table within the database.

    name_override = "node0_stats"
Important: format in which we will receive the script information. In our case it will be json.

    data_format = "json"

This option allows us to send text strings as output. Without this config the variables read erd_node_type "," erd_peer_type "that have text strings would not be stored and we would not have them available in grafana to be able to show them in our dashboards. 

    json_string_fields = ["erd_node_type","erd_peer_type"]

If we wanted to configure more nodes you should add more inputs with: the script that will read from the node and we change the name. For example : 

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
      
  #### 4.1 Script to read node information..       
By default, when installing a node, several directories are created within the home of the user that we have used to install. One of these folders is "/ elrond-utils" where we have two tools that help us have a real-time view of the node using the CLI: logviewer and termui.
Each node when it starts launches a service listening on port 8080 for the first node, 8081 for the second node, 808X for the following ones. We can access that service using the following command:
    
    cd /home/tu-usuario/elrond-utils/
    ./termui -address localhost:8080

What the check_erd_node_metrics_X script does is make use of that information in a very simple way:

    cd /etc/telegraf/
    vim check_erd_node_metrics_0   

We paste the following content:

    #!/bin/bash
   
    OUTPUT=`curl -s 127.0.0.1:8080/node/status 2>/dev/null | jq ".details // empty"` # returns "" when null  
      
    ret=$?
    if [ -z "${OUTPUT}" ] || [ ${ret} -ne 0 ]; then
       echo "NODE NOT RUNNING!!"
       exit 2 
    fi
    echo ${OUTPUT}
    
Save the changes, make the file executable and make the owner telegraf: 

    chmod +x check_erd_node_metrics_0
    chown telegraf check_erd_node_metrics_0 

We test that everything works:

    sudo telegraf telegraf --config telegraf.conf
    
If you see something like the following, it is that everything went well: 

    2020-05-17T17:57:32Z I! Starting Telegraf 1.14.2
    2020-05-17T17:57:32Z I! Using config file: /etc/telegraf/telegraf.conf
    2020-05-17T17:57:32Z I! Loaded inputs: exec exec exec diskio net swap kernel netstat processes cpu disk mem system
    2020-05-17T17:57:32Z I! Loaded aggregators: 
    2020-05-17T17:57:32Z I! Loaded processors: 
    2020-05-17T17:57:32Z I! Loaded outputs: influxdb
    2020-05-17T17:57:32Z I! Tags enabled: host=erd.node
    2020-05-17T17:57:32Z I! [agent] Config: Interval:1m0s, Quiet:false, Hostname:"erd.node", Flush Interval:1m0s


#### 5. Configurar Grafana.
Grafana by default listens on port 3000. So you will have to write the ip-your-server: 3000 to access its web environment:
     
     http://IP:address:3000

![login](https://user-images.githubusercontent.com/16337441/82241923-3e918380-993d-11ea-9efd-709c82ffcffa.png)

The default username and password are admin / admin. It will ask you to change the password.

![password](https://user-images.githubusercontent.com/16337441/82241938-42250a80-993d-11ea-8e6d-8ade7f7d6225.png)

![data_source](https://user-images.githubusercontent.com/16337441/82241953-481aeb80-993d-11ea-9e98-69f24a21357b.png)

Now we have to add a data source: InfluxDB in our case. 

![InfluxDB Settings Grafana](https://user-images.githubusercontent.com/16337441/82244171-1e63c380-9941-11ea-9c0e-5c5657fe5caa.png)

#### 6. Import the dashboard. 
Use the .json **erd_dashboard.json** that I share as a template to quickly have information on your dashboard.
You will have to make some adjustments in the queries of the different graphs if you have given another name to your node.

![import_json](https://user-images.githubusercontent.com/16337441/82244777-0b052800-9942-11ea-88e1-2750460ecf9d.png)

Dashboard : 


![erd_node_status](https://user-images.githubusercontent.com/16337441/82245314-012ff480-9943-11ea-811c-6ab05206f046.png)
![erd_node_performace](https://user-images.githubusercontent.com/16337441/82245319-02f9b800-9943-11ea-8bce-128128d51560.png)


#### 7. Alerts via Telegram. 

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






