install :
	clang -O1 -c main.c -Iinclude -I/usr/local/include
	clang -O1 -o main main.o -Wl,-rpath -Wl,\$$ORIGIN/lib -Llib -L/usr/local/lib -lm -lluajit -ldl
	