# Lib(X)SVF  -  A library for implementing SVF and XSVF JTAG players
#
# Copyright (C) 2009  RIEGL Research ForschungsGmbH
# Copyright (C) 2009  Clifford Wolf <clifford@clifford.at>
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

AR = ar
RANLIB = ranlib
CC = gcc

CFLAGS += -Wall -Os -ggdb -MD

help:
		@echo ""
		@echo "Usage:"
		@echo ""
		@echo "  $(MAKE) libxsvf.a"
		@echo "                .... build only the library"
		@echo ""
		@echo "  $(MAKE) xsvftool-gpio"
		@echo "                .... build the library and xsvftool-gpio"
		@echo ""
		@echo "  $(MAKE) all"
		@echo "                .... build the library and all examples"
		@echo ""
		@echo "  $(MAKE) install"
		@echo "                .... install everything in /usr/local/"
		@echo ""

all: libxsvf.a xsvftool-gpio

libxsvf.a: tap.o statename.o memname.o svf.o xsvf.o scan.o play.o impl_gpio.o
		rm -f libxsvf.a
		$(AR) qc $@ $^
		$(RANLIB) $@

xsvftool-gpio: LDLIBS += -lbcm2835
xsvftool-gpio: libxsvf.a xsvftool-gpio.o

clean:
		rm -f xsvftool-gpio
		rm -f libxsvf.a *.o *.d

-include *.d
