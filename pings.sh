echo "pings from client 3"
docker exec client3 ping -c 2 2.2.2.2

echo "pings from client 2"
docker exec client2 ping -c 2 192.168.13.1
