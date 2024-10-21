##
# Puff - a Huff compiler in Racket
#
# @file
# @version 0.1

KECCAK_LIB_DIR = rust_src/keccaklib
KECCAK_LIB_TARGET_DIR = $(KECCAK_LIB_DIR)/target/release
LIB_NAME = libkeccak_lib
LIB_DIR = lib

ifeq ($(OS),Windows_NT)
    LIB_EXT = .dll
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        LIB_EXT = .so
    endif
    ifeq ($(UNAME_S),Darwin)
        LIB_EXT = .dylib
    endif
endif

deps: build_rust copy_lib

racket_executable:
	@echo "Building Racket executable..."
	raco exe -o puffc main.rkt

install_racket_libs:
	@echo "Installing Racket libraries..."
	raco pkg install --auto --batch --link threading-lib brag

build_rust:
	@echo "Building Rust library..."
	cd $(KECCAK_LIB_DIR) && cargo build --release

copy_lib:
	@echo "Copying library to $(LIB_DIR) directory..."
	mkdir -p $(LIB_DIR)
	cp $(KECCAK_LIB_TARGET_DIR)/$(LIB_NAME)$(LIB_EXT) $(LIB_DIR)/$(LIB_NAME)$(LIB_EXT)

clean:
	@echo "Cleaning up..."
	cd $(KECCAK_LIB_DIR) && cargo clean
	rm -f $(LIB_DIR)/$(LIB_NAME)$(LIB_EXT)

# end
