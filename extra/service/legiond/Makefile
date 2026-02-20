CC ?= clang

CFLAGS ?= -O2
CFLAGS += -Wall
LDFLAGS += -linih -lrt

SRC = $(wildcard modules/*.c)
OBJ = $(SRC:.c=.o)

TARGET = legiond legiond-ctl
all: $(TARGET)

legiond: $(OBJ) legiond.o
	$(CC) $(CFLAGS) $(OBJ) legiond.o -o legiond $(LDFLAGS)

legiond-ctl: legiond-ctl.o
	$(CC) $(CFLAGS) legiond-ctl.o -o legiond-ctl

%.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ) $(TARGET) legiond.o legiond-ctl.o

.PHONY: all clean
