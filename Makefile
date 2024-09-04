CC := clang-18
LD := ld.lld-18
OBJCOPY := llvm-objcopy-18
AR := llvm-ar-18
RANLIB := llvm-ranlib-18

UNAME := $(shell uname)
ifeq ($(UNAME), Darwin)
	LD := ld.lld
	OBJCOPY := llvm-objcopy
	RANLIB := llvm-ranlib
endif

CFLAGS := --target=riscv64 -march=rv64imc_zba_zbb_zbc_zbs
CFLAGS += -g -Os \
		-Wall -Werror -Wno-nonnull -Wno-unused-function \
		-fno-builtin-printf -fno-builtin-memcmp \
		-nostdinc -nostdlib \
		-fdata-sections -ffunction-sections

CFLAGS += -I deps/ckb-c-stdlib/libc -I deps/ckb-c-stdlib
CFLAGS += -I include -I include/c-stdlib
CFLAGS += -I deps/compiler-rt-builtins-riscv/compiler-rt/lib/builtins

CFLAGS += -Wextra -Wno-sign-compare -Wno-missing-field-initializers -Wundef -Wuninitialized \
          -Wunused -Wno-unused-parameter -Wchar-subscripts -funsigned-char -Wno-unused-function \
          -DCONFIG_VERSION=\"2021-03-27-CKB\"
CFLAGS += -Wno-incompatible-library-redeclaration -Wno-implicit-const-int-float-conversion -Wno-invalid-noreturn

CFLAGS += -DCKB_DECLARATION_ONLY
CFLAGS += -D__BYTE_ORDER=1234 -D__LITTLE_ENDIAN=1234 -D__ISO_C_VISIBLE=1999 -D__GNU_VISIBLE
CFLAGS += -DCKB_MALLOC_DECLARATION_ONLY -DCKB_PRINTF_DECLARATION_ONLY -DCONFIG_BIGNUM -DCONFIG_STACK_CHECK
# uncomment to dump memory usage
# CFLAGS += -DMEMORY_USAGE

LDFLAGS := -static --gc-sections
LDFLAGS += -Ldeps/compiler-rt-builtins-riscv/build -lcompiler-rt

CFLAGS2 := --target=riscv64 -march=rv64imc_zba_zbb_zbc_zbs
CFLAGS2 += -g -Os \
		-Wall -Werror -Wno-nonnull -Wno-unused-function \
		-fno-builtin-printf -fno-builtin-memcmp \
		-nostdinc -nostdlib \
		-fdata-sections -ffunction-sections

CFLAGS2 += -I deps/ckb-c-stdlib
CFLAGS2 += -I include -I include/c-stdlib
CFLAGS2 += -I deps/compiler-rt-builtins-riscv/compiler-rt/lib/builtins

CFLAGS2 += -Wextra -Wno-sign-compare -Wno-missing-field-initializers -Wundef -Wuninitialized \
          -Wunused -Wno-unused-parameter -Wchar-subscripts -funsigned-char -Wno-unused-function \
          -DCONFIG_VERSION=\"2021-03-27-CKB\"
CFLAGS2 += -Wno-incompatible-library-redeclaration -Wno-implicit-const-int-float-conversion -Wno-invalid-noreturn

CFLAGS2 += -DCKB_DECLARATION_ONLY
CFLAGS2 += -D__BYTE_ORDER=1234 -D__LITTLE_ENDIAN=1234 -D__ISO_C_VISIBLE=1999 -D__GNU_VISIBLE
CFLAGS2 += -DCKB_MALLOC_DECLARATION_ONLY -DCKB_PRINTF_DECLARATION_ONLY -DCONFIG_BIGNUM -DCONFIG_STACK_CHECK
CFLAGS2 += -isystem deps/musl/release/include

LDFLAGS2 := -static --gc-sections -nostdlib
LDFLAGS2 += -Ldeps/compiler-rt-builtins-riscv/build -lcompiler-rt
LDFLAGS2 += --sysroot deps/musl/release -Ldeps/musl/release/lib -lc -lgcc -nostdlib
LDFLAGS2 += -wrap=gettimeofday
LDFLAGS2 += -wrap=printf
LDFLAGS2 += -wrap=stderr
LDFLAGS2 += -wrap=stdout
LDFLAGS2 += -wrap=fesetround
LDFLAGS2 += -wrap=localtime_r

OBJDIR=build

QJS_OBJS=$(OBJDIR)/qjs.o $(OBJDIR)/quickjs.o $(OBJDIR)/libregexp.o $(OBJDIR)/libunicode.o \
		$(OBJDIR)/cutils.o $(OBJDIR)/mocked.o $(OBJDIR)/std_module.o $(OBJDIR)/ckb_module.o $(OBJDIR)/ckb_cell_fs.o \
		$(OBJDIR)/libbf.o $(OBJDIR)/cmdopt.o

STD_OBJS=$(OBJDIR)/malloc_impl.o $(OBJDIR)/printf_impl.o $(OBJDIR)/stdio_impl.o


all: build/ckb-js-vm

deps/compiler-rt-builtins-riscv/build/libcompiler-rt.a:
	cd deps/compiler-rt-builtins-riscv && make

deps/musl/release:
	cd deps/musl && \
	CLANG=$(CC) ./ckb/build.sh

build/ckb-js-vm: $(STD_OBJS) $(QJS_OBJS) deps/compiler-rt-builtins-riscv/build/libcompiler-rt.a
	$(LD) $(LDFLAGS2) -o $@ $^
	cp $@ $@.debug
	$(OBJCOPY) --strip-debug --strip-all $@
	ls -lh build/ckb-js-vm

$(OBJDIR)/%.o: quickjs/%.c
	@echo build $<
	@$(CC) $(CFLAGS2) -c -o $@ $<

$(OBJDIR)/%.o: include/c-stdlib/src/%.c
	@echo build $<
	@$(CC) $(CFLAGS) -c -o $@ $<

$(OBJDIR)/%.o: include/%.c
	@echo build $<
	@$(CC) $(CFLAGS2) -c -o $@ $<

# $(OBJDIR)/ckb_module.o: quickjs/ckb_module.c
# 	@echo build $<
# 	@$(CC) $(CFLAGS2) -c -o $@ $<

# $(OBJDIR)/cmdopt.o: quickjs/cmdopt.c
# 	@echo build $<
# 	@$(CC) $(CFLAGS2) -c -o $@ $<

# $(OBJDIR)/cutils.o: quickjs/cutils.c
# 	@echo build $<
# 	@$(CC) $(CFLAGS2) -c -o $@ $<

# $(OBJDIR)/libbf.o: quickjs/libbf.c
# 	@echo build $<
# 	@$(CC) $(CFLAGS2) -c -o $@ $<

# $(OBJDIR)/libregexp.o: quickjs/libregexp.c
# 	@echo build $<
# 	@$(CC) $(CFLAGS2) -c -o $@ $<

# $(OBJDIR)/libunicode.o: quickjs/libunicode.c
# 	@echo build $<
# 	@$(CC) $(CFLAGS2) -c -o $@ $<

# $(OBJDIR)/mocked.o: quickjs/mocked.c
# 	@echo build $<
# 	@$(CC) $(CFLAGS2) -c -o $@ $<

# $(OBJDIR)/qjs.o: quickjs/qjs.c
# 	@echo build $<
# 	@$(CC) $(CFLAGS2) -c -o $@ $<

# $(OBJDIR)/quickjs.o: quickjs/quickjs.c
# 	@echo build $<
# 	@$(CC) $(CFLAGS2) -c -o $@ $<

# $(OBJDIR)/std_module.o: quickjs/std_module.c
# 	@echo build $<
# 	@$(CC) $(CFLAGS2) -c -o $@ $<

test:
	make -f tests/examples/Makefile
	make -f tests/basic/Makefile
	cd tests/ckb_js_tests && make all

benchmark:
	make -f tests/benchmark/Makefile

clean:
	rm -f build/*.o
	rm -f build/ckb-js-vm
	rm -f build/ckb-js-vm.debug
	cd tests/ckb_js_tests && make clean
	# make -C deps/compiler-rt-builtins-riscv clean

install:
	wget 'https://github.com/nervosnetwork/ckb-standalone-debugger/releases/download/v0.118.0-rc1/ckb-debugger-linux-x64.tar.gz'
	tar zxvf ckb-debugger-linux-x64.tar.gz
	mv ckb-debugger ~/.cargo/bin/ckb-debugger
	make -f tests/ckb_js_tests/Makefile install-lua

.phony: all clean
