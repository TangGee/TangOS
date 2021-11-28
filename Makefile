ARM_CROSSPREFIX ?= aarch64-linux-android-

board ?= rpi4

ifeq ($(board), rpi3)
CC_FLAGS += -DCONFIG_BOARD_PI3B
QEMU_OPS  += -machine raspi3
else ifeq ($(board), rpi4)
CC_FLAGS += -DCONFIG_BOARD_PI4B
QEMU_OPS  += -machine raspi4
endif

CC = $(ARM_CROSSPREFIX)gcc
LD = $(ARM_CROSSPREFIX)ld
OBJCPY = $(ARM_CROSSPREFIX)objcpy

#注意每行后面不要有空格，否则会算到目录名里面，导致问题
SRC_DIR = src
BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/obj
DEPS_DIR  = $(BUILD_DIR)/deps

INC_DIR = \
	-I./include \
	-I./src \

#这里添加编译参数
CC_FLAGS += -g -Wall -nostdlib -nostdinc INC_DIR
ASM_FLAGS = -g $(INC_DIR)
LNK_FLAGS :=

#这里递归遍历3级子目录
DIRS := $(shell find $(SRC_DIR) -maxdepth 10 -type d)

#将每个子目录添加到搜索路径
VPATH = $(DIRS)

#查找src_dir下面包含子目录的所有cpp文件
C_SOURCES   = $(foreach dir, $(DIRS), $(wildcard $(dir)/*.c))

ASM_SOURCE =  $(foreach dir, $(DIRS), $(wildcard $(dir)/*.S))


all: tang.bin

#编译之前要创建OBJ目录，确保目录存在
$(OBJ_DIR)/%_c.o:%.c
	mkdir -p $(@D)
	$(CC) -c $(CC_FLAGS) -MMD -c $< -o $@

$(OBJ_DIR)/%_s.o:%.S
	@echo  "make all, build tang os"
	mkdir -p $(@D)
	$(CC) -c $(ASM_FLAGS) -o $@ $<

C_OBJS   = $(addprefix $(OBJ_DIR)/,$(patsubst %.c,%_c.o,$(notdir $(C_SOURCES))))
ASM_OBJS   = $(addprefix $(OBJ_DIR)/,$(patsubst %.S,%_s.o,$(notdir $(ASM_SOURCE))))
OBJ_FILES = $(C_OBJS)
OBJ_FILES += $(ASM_OBJS)

DEP_FILES = $(OBJ_FILES:%.o=%.d)
-include $(DEP_FILES)

tang.bin: $(SRC_DIR)/tang.link.lds $(OBJ_FILES)
	$(ARM_CROSSPREFIX)ld -T $(SRC_DIR)/tang.link.lds -Map $(BUILD_DIR)/tang.map -o $(BUILD_DIR)/tang.elf  $(OBJ_FILES)
	$(ARM_CROSSPREFIX)objcopy $(BUILD_DIR)/tang.elf -O binary $(BUILD_DIR)/tang.bin


#前面加-表示忽略错误
-include $(DEPS)
.PHONY : clean
clean:
	rm -rf $(BUILD_DIR) $(TARGET)

QEMU_OPS  += -nographic
PHONY += run

run:
	qemu-system-aarch64 $(QEMU_OPS) -kernel tang.bin

PHONY += debug
debug:
	qemu-system-aarch64 $(QEMU_OPS) -kernel tang.bin -S -s

PHONY += help
help :
	@echo  "make all, build tang os"
	@echo  "make run, build tang os, and run qemu"
	@echo  "make debug, build tang os, and run qemu and debug"

