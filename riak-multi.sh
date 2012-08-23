#!/bin/bash
# Riak multi node setup script for single host.

ROOT=$(cd `dirname $0`; pwd)

usage() {
  cat<<EOS
usage
-----
  $0 create node_count riak_home
  $0 start node_id
  $0 start_all
  $0 stop node_id
  $0 stop_all
  $0 clean

example)
  $0 create 3 /usr/local/riak
  $0 stop 2
  $0 start 2
EOS
}

clean(){
  for node in `ls -1 $ROOT/nodes`;do
    echo "rm $ROOT/nodes/$node"
    rm -rf $ROOT/nodes/$node
  done
  rmdir $ROOT/nodes
}

create_nodes(){
  node_cnt=$1
  riak_home=$2

  mkdir -p $ROOT/nodes

  i=1
  while [[ $i -le $node_cnt ]];do
    mkdir -pv $ROOT/nodes/$i

    for dir in bin erts-5.9.1 etc lib releases;do
      cp -pr $riak_home/$dir $ROOT/nodes/$i/$dir
    done

    cat $riak_home/etc/vm.args |\
      sed "s|riak@127.0.0.1|riak${i}@127.0.0.1|" \
      > $ROOT/nodes/$i/etc/vm.args

    cat $riak_home/etc/app.config  |\
      sed "s|8087|$((8087-1+$i*100))|g" |\
      sed "s|8098|$((8098-1+$i*100))|g" |\
      sed "s|8099|$((8099-1+$i*100))|g" \
      > $ROOT/nodes/$i/etc/app.config

    i=$(($i+1))
  done
}

start_all(){
  for node in `ls -1 $ROOT/nodes`;do
    start $node
  done
}

start(){
  node=$1
  echo "starting node$node"
  $ROOT/nodes/$node/bin/riak start
}

stop_all(){
  for node in `ls -1 $ROOT/nodes`;do
    stop $node
  done
}

stop(){
  node=$1
  echo "killing node$node"
  $ROOT/nodes/$node/bin/riak stop
}

required_args(){
  actual=$1
  required=$2
  if [[ $actual -lt $required ]]; then
    usage
    exit 1
  fi
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

case $1 in
  create)
    required_args $# 3
    create_nodes $2 $3
    ;;
  clean)
    clean
    ;;
  start_all)
    start_all
    ;;
  start)
    required_args $# 2
    start $2
    ;;
  stop_all)
    stop_all
    ;;
  stop)
    required_args $# 2
    stop $2
    ;;
  *)
    usage
    ;;
esac
