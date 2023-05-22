main: main.o util.o host.o switch.o
	cc -o main main.o util.o host.o switch.o -lpcap -pthread
	
main.o:net.h
	cc -c main.c
util.o: util.c
	cc -c util.c
host.o: util.h host.c net.h
	cc -c host.c -lpcap
switch.o:switch.c net.h
	cc -c switch.c -lpcap -pthread
clean :
	rm main util.o host.o switch.o main.o