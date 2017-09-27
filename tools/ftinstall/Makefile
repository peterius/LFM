all:
	gcc -c -Wall -Werror -fPIC write_redirect.c
	gcc -shared -ldl -o write_redirect.so write_redirect.o
	gcc -o ftinstall -Wl,--format=binary -Wl,write_redirect.so -Wl,--format=default ftinstall.c
clean:
	-rm *.o
	-rm *.so
	-rm ftinstall

