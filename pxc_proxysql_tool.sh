#!/bin/bash
# Created by Ramesh Sivaraman, Percona LLC
# Prerequisites
#  * Percona-Server-client-56 should be installed
#  * proxysql should be running with default port.

#Check Percona client is installed or not
if ! rpm -qa  | grep Percona-Server-client-56 >/dev/null ;then
  echo "Percona client is not present; Please run yum install Percona-Server-client-56"
fi

#Checking proxysql running status
if [ `mysql -h 127.0.0.1 -P6032 -uadmin -padmin -Bse 'select 1'  2>/dev/null` -ne 1 ];then
  echo "Proxysql is not running on port 6032"
  exit 1
fi

# Dispay script usage details
usage () {
  echo "Usage: [ options ]"
  echo -e "Options:\n"
    echo "help			: help info."
    echo "node-list		: List of available cluster node info."
    echo "connection-pool	: Cluster connection pool status info."
    echo "user-list		: Cluster users info."
    echo "query-rules		: Cluster read write split query rule info."
    echo "add			: Add new user, node and query-rule into to proxysql."
}

# Dispay script usage details for adding new user, node and query-rule
add_usage(){
  echo -e "pxc_proxysql_tool 'add' requires valid argument.\n"
  echo -e "Usage: [ options ]\n"
    echo "user		: Add user in followng format username:password:hostgroup_id:max_connections"
    echo -e "		Sample - root:root:0:1024\n"
    echo "node		: Add node in followng format hostgroup_id:hostname:port"
    echo -e "		Sample - 0:127.0.0.1:30500\n"
    echo "query-rule	: Add query rule in followng format match_pattern:destination_hostgroup"
    echo -e "		Sample - ^SELECT:0\n"
}

#Add new user function
add_user(){
  add_string=$1
  array=(${add_string//:/ })
  if [ `echo ${array[@]} | wc -w` -eq 4 ];then
    echo -e "\nUsername         : ${array[0]}"
    echo -e "Password           : ${array[1]}"
    echo -e "Hostgroup ID       : ${array[2]}"
    echo -e "Max connections    : ${array[3]}\n"
    read -p "Please confirm above user information?" yn
    case "$yn" in
      [Yy]* ) 
        echo  "INSERT INTO mysql_users (username, password, default_hostgroup, max_connections) VALUES ('${array[0]}', '${array[1]}', ${array[2]}, ${array[3]})" | mysql -h 127.0.0.1 -P6032 -uadmin -padmin 2>/dev/null 
        echo "LOAD MYSQL USERS TO RUNTIME; SAVE MYSQL USERS TO DISK;" | mysql -h 127.0.0.1 -P6032 -uadmin -padmin 2>/dev/null 
        echo "User has been added!"
        mysql -h 127.0.0.1 -P6032 -uadmin -padmin  -t -e"SELECT username,active,use_ssl,default_hostgroup,max_connections FROM disk.mysql_users where username='${array[0]}'" 2>/dev/null
      ;;
      [Nn]* )
        exit 1
      ;;
    esac
  else
    echo "Please enter valid string"
    exit 1
  fi
  
}

#Add new node function
add_node(){
  node_string=$1
  array=(${node_string//:/ })
  if [ `echo ${array[@]} | wc -w` -eq 3 ];then
    echo -e "\nHostname		: ${array[0]}"
    echo -e "Port		: ${array[1]}"
    echo -e "Hostgroup ID	: ${array[2]}\n"
    read -p "Please confirm above node information?" yn
    case "$yn" in
      [Yy]* )
        echo  "INSERT INTO mysql_servers ( hostname, port, hostgroup_id ) VALUES ('${array[0]}', ${array[1]}, ${array[2]})" | mysql -h 127.0.0.1 -P6032 -uadmin -padmin 2>/dev/null 
        echo "LOAD MYSQL SERVERS TO RUNTIME; SAVE MYSQL SERVERS TO DISK;" | mysql -h 127.0.0.1 -P6032 -uadmin -padmin  2>/dev/null 
        echo "Node has been added!"
        mysql -h 127.0.0.1 -P6032 -uadmin -padmin  -t -e"SELECT hostgroup_id,hostname,port,status from disk.mysql_servers where hostname='${array[0]}' and port=${array[1]}" 2>/dev/null 
      ;;
      [Nn]* )
        exit 1
      ;;
    esac
  else
    echo "Please enter valid string"
    exit 1
  fi
}

#Add new query rule function
add_query_rule(){
  query_rule_string=$1
  array=(${query_rule_string//:/ })
  if [ `echo ${array[@]} | wc -w` -eq 2 ];then
    echo -e "\nMatching pattern	: ${array[0]}"
    echo -e "Hostgroup ID	: ${array[1]}"
    echo -e "Active		: Yes\n"
    read -p "Please confirm above query rule information?" yn
    case "$yn" in
      [Yy]* )
        echo  "INSERT INTO mysql_query_rules(active,match_pattern,destination_hostgroup,apply) VALUES(1, '${array[0]}', ${array[1]}, 1)" | mysql -h 127.0.0.1 -P6032 -uadmin -padmin 2>/dev/null 
        echo "LOAD MYSQL QUERY RULES TO RUNTIME;SAVE MYSQL QUERY RULES TO DISK;" | mysql -h 127.0.0.1 -P6032 -uadmin -padmin  2>/dev/null 
        echo "Query rule has been added!"
        mysql -h 127.0.0.1 -P6032 -uadmin -padmin  -t -e "SELECT active, match_pattern,destination_hostgroup hg_id, apply FROM disk.mysql_query_rules where match_pattern='${array[0]}'" 2>/dev/null 
      ;;
      [Nn]* )
        exit 1
      ;;
    esac
  else
    echo "Please enter valid string"
    exit 1
  fi
}

#Lists cluster nodes
cluster_nodes(){
  #Cluster node list 
  mysql -h 127.0.0.1 -P6032 -uadmin -padmin  -t -e"SELECT hostgroup_id,hostname,port,status from disk.mysql_servers;" 2>/dev/null
}

#Lists cluster connection pool info
cluster_connection_pool(){
  #Cluster connection pool status 
  mysql -h 127.0.0.1 -P6032 -uadmin -padmin  -t -e"select srv_host,srv_port,status,Queries,Bytes_data_sent,Bytes_data_recv from stats_mysql_connection_pool" 2>/dev/null
}

#Lists cluster users
cluster_user_list(){
  #Cluster user list 
  mysql -h 127.0.0.1 -P6032 -uadmin -padmin  -t -e"SELECT username,active,use_ssl,default_hostgroup,max_connections FROM disk.mysql_users" 2>/dev/null
}

#Lists query rules
cluster_query_rules(){
  #Cluster query rules
  mysql -h 127.0.0.1 -P6032 -uadmin -padmin  -t -e"SELECT rule_id, match_pattern,destination_hostgroup hg_id, apply FROM disk.mysql_query_rules WHERE active=1" 2>/dev/null
}

#Checks user arguments
case "$1" in
  node-list)
    cluster_nodes
  ;;
  connection-pool)
    cluster_connection_pool
  ;;
  user-list)
    cluster_user_list
  ;;
  query-rules)
    cluster_query_rules
  ;;
  add)
    case "$2" in
      user)
        echo "Add user in followng format username:password:hostgroup_id:max_connections"
        echo -e "Sample : root:root:0:1024\n"
        read user_info
        add_user $user_info
      ;;
      node)
        echo "Add node in followng format hostname:port:hostgroup_id"
        echo -e "Sample : 127.0.0.1:30500:0\n"
        read node_info
        add_node $node_info
      ;;
      query-rule)
        echo "Add query rule in followng format match_pattern:destination_hostgroup"
        echo -e "Sample : ^SELECT:0\n"
        read query_rule_info
        add_query_rule $query_rule_info
      ;;
      *)
        add_usage
      ;;
    esac
  ;;
  help)
    usage
  ;;
  *)
     usage
     exit 1
  ;;
esac
