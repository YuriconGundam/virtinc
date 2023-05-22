#!/bin/bash

#source topo.config
nodes=(host1 host2 host3 switch)
links=( host1 iface1 switch iface1 \
        host2 iface1 switch iface2 \
        host3 iface1 switch iface3 )

function create_images()
{
	docker build -t mycontainer .
}

function create_nodes(){
	echo "======================================"
	echo "create docker container here"
	
	port_cast=(8081 31 8082 32 8083 33 8084 34)
	idx=0

	for h in ${nodes[@]}; do
		docker create --cap-add NET_ADMIN --name $h -p ${port_cast[$idx]}:${port_cast[$(($idx+1))]} mycontainer
		idx=$(($idx+2))
		echo create $h
	done
}

function run_containers() 
{
	systemctl daemon-reload
	systemctl restart docker
	for h in ${nodes[@]}; do
		docker start $h
	done
}

function stop_containers()
{
	for h in ${nodes[@]}; do
		docker stop $h
	done
}

function destroy_containers()
{
	for h in ${nodes[@]}; do
		docker stop $h
		docker rm $h
	done
}
function create_links(){
	echo "======================================"
	echo "create links"

	id=()
	for((i=0;i<4;i++));
	do
		id[$i]=$(sudo docker inspect -f '{{.State.Pid}}' ${nodes[$i]})
		ln -s /proc/${id[$i]}/ns/net /var/run/netns/${id[$i]}
	done
	node_id=()
	node_id[0]=${id[0]}
	node_id[1]=${id[3]}
	node_id[2]=${id[1]}
	node_id[3]=${id[3]}
	node_id[4]=${id[2]}
	node_id[5]=${id[3]}
 	total=${#links[*]}
	ipAddr=("10.0.0.1/24" "10.0.0.2/24" "10.0.1.1/24" "10.0.1.2/24" "10.0.2.1/24" "10.0.2.2/24")
	idx=0

	for ((i=0; i<$total; i=i+4)) do
		echo ${links[$i]}-${links[$i+1]}, ${links[$i+2]}-${links[$i+3]}
		ip link add ${links[$i]}-${links[$i+1]} type veth peer name ${links[$i+2]}-${links[$i+3]}

		ip link set ${links[$i]}-${links[$i+1]} netns ${node_id[$idx]}
		ip netns exec ${node_id[$idx]} ip link set ${links[$i]}-${links[$i+1]} up
		ip netns exec ${node_id[$idx]} ip addr add ${ipAddr[$idx]} dev ${links[$i]}-${links[$i+1]}
		idx=$(($idx+1))

		ip link set ${links[$i+2]}-${links[$i+3]} netns ${node_id[$idx]}
		ip netns exec ${node_id[$idx]} ip link set ${links[$i+2]}-${links[$i+3]} up
		ip netns exec ${node_id[$idx]} ip addr add ${ipAddr[$idx]} dev ${links[$i+2]}-${links[$i+3]}
		idx=$(($idx+1))
	done
}


function destroy_links(){
	ip link del host1-iface1
	ip link del host2-iface1
	ip link del host3-iface1
	for((i=0;i<3;i++));
	do
		id[$i]=$(sudo docker inspect -f '{{.State.Pid}}' ${nodes[$i]})
		ip netns del ${id[$i]}
	done
}



case $1 in
	"-ci")
		echo "create images"
		create_images
		;;
	"-cn")
		echo "create nodes"
		create_nodes
		;;
	"-rc")
		echo "run_containers"
		run_containers
		;;
	"-sc")
		echo "stop_containers"
		stop_containers
		;;
	"-dc")
		echo "destroy_containers"
		destroy_containers
		;;
	"-di")
		echo "destroy_images"
		destroy_images
		;;
	"-cl")
		#echo "create Links"
		create_links
		;;
	"-dl")
		echo "destroy_links"
		destroy_links
		;;
	"-dn")
		echo "destroy_network"
		destroy_containers
		destroy_links
		;;
	*)
    	echo "input error !"
		;;
esac

echo $?
