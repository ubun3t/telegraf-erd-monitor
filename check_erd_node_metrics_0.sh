#!/bin/bash

OUTPUT=`curl -s 127.0.0.1:8080/node/status 2>/dev/null | jq ".data // empty"` # returns "" when null  
  
ret=$?
if [ -z "${OUTPUT}" ] || [ ${ret} -ne 0 ]; then
   echo "NODE NOT RUNNING!!"
   exit 2 
fi
echo ${OUTPUT}
