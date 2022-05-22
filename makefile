CFLAGS = -O3 -fPIC -ffast-math -march=native
FLAGS = -shared
TARGET = lib.so

$(TARGET): lib.c
	cc lib.c $(CFLAGS) $(FLAGS) -o $(TARGET)
