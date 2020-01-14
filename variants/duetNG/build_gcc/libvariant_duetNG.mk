#
#  Copyright (c) 2012 Arduino.  All right reserved.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2.1 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

# Makefile for compiling libArduino
.SUFFIXES: .o .a .c .s

CHIP=__SAM4E8E__
VARIANT=duetNG
LIBNAME=libFreeRTOS
TOOLCHAIN=gcc

#-------------------------------------------------------------------------------
# Path
#-------------------------------------------------------------------------------

# Output directories
OUTPUT_BIN = ../../../SAM4E

# Libraries
PROJECT_BASE_PATH = ../../..
CORENG_PATH = ../../../../CoreNG

VARIANT_BASE_PATH = ../../../variants
VARIANT_PATH = ../../../variants/$(VARIANT)

#-------------------------------------------------------------------------------
# Files
#-------------------------------------------------------------------------------

#vpath %.h $(PROJECT_BASE_PATH) $(SYSTEM_PATH) $(VARIANT_PATH)
vpath %.cpp $(PROJECT_BASE_PATH)

VPATH+=$(PROJECT_BASE_PATH)

INCLUDES =
#INCLUDES += -I$(PROJECT_BASE_PATH)
INCLUDES += -I../../../src/include
INCLUDES += -I$(CORENG_PATH)/asf
INCLUDES += -I$(CORENG_PATH)/asf/common/utils
INCLUDES += -I$(CORENG_PATH)/asf/sam/utils
INCLUDES += -I$(CORENG_PATH)/asf/sam/utils/preprocessor
INCLUDES += -I$(CORENG_PATH)/asf/sam/utils/header_files
INCLUDES += -I$(CORENG_PATH)/asf/sam/utils/cmsis/sam4e/include
INCLUDES += -I$(CORENG_PATH)/asf/thirdparty/CMSIS/Include
INCLUDES += -I$(CORENG_PATH)/asf/sam/drivers
INCLUDES += -I$(CORENG_PATH)/variants/duetNG

#-------------------------------------------------------------------------------
ifdef DEBUG
include debug.mk
else
include release.mk
endif

#-------------------------------------------------------------------------------
# Tools
#-------------------------------------------------------------------------------

include $(TOOLCHAIN).mk
CFLAGS += -c -std=gnu99 -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard -ffunction-sections -fdata-sections -nostdlib -Wundef -Wdouble-promotion -fsingle-precision-constant "-Wa,-ahl=$*.s"

#-------------------------------------------------------------------------------
ifdef DEBUG
OUTPUT_OBJ=debug
OUTPUT_LIB_POSTFIX=dbg
else
OUTPUT_OBJ=release
OUTPUT_LIB_POSTFIX=rel
endif

OUTPUT_LIB= $(LIBNAME).a
OUTPUT_PATH=$(OUTPUT_OBJ)_$(VARIANT)

#-------------------------------------------------------------------------------
# C source files and objects
#-------------------------------------------------------------------------------

# Make does not offer a recursive wildcard function
# from https://stackoverflow.com/a/12959694:
rwildcard=$(wildcard $1$2)$(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))
C_SRC := $(call rwildcard,../../../src/,*.c)
#C_SRC=$(wildcard $(PROJECT_BASE_PATH)/*.c)

# during development, remove some files
C_OBJ_FILTER=
C_OBJ_FILTER += $(PROJECT_BASE_PATH)/src/portable/GCC/ARM_CM0/%
C_OBJ_FILTER += $(PROJECT_BASE_PATH)/src/portable/MemMang/heap_1.c
C_OBJ_FILTER += $(PROJECT_BASE_PATH)/src/croutine.c
C_OBJ_FILTER += $(PROJECT_BASE_PATH)/src/portable/MemMang/heap_3.c
C_OBJ_FILTER += $(PROJECT_BASE_PATH)/src/portable/MemMang/heap_2.c
C_OBJ_FILTER += $(PROJECT_BASE_PATH)/src/portable/MemMang/heap_4.c
C_OBJ_FILTER += $(PROJECT_BASE_PATH)/src/portable/MemMang/heap_5.c
C_OBJ_FILTER += $(PROJECT_BASE_PATH)/src/portable/Common/%
C_OBJ_FILTER += $(PROJECT_BASE_PATH)/src/portable/Tasking/ARM_CM4F/%
C_OBJ_FILTER += $(PROJECT_BASE_PATH)/src/portable/GCC/ARM7_AT91SAM7S/%
C_OBJ_FILTER += $(PROJECT_BASE_PATH)/src/portable/GCC/ARM7_AT91FR40008/%
C_OBJ_FILTER += $(PROJECT_BASE_PATH)/src/portable/GCC/ARM_CM7/%
C_OBJ_FILTER += $(PROJECT_BASE_PATH)/src/portable/GCC/ARM_CM4_MPU/%
C_OBJ_FILTER += $(PROJECT_BASE_PATH)/src/portable/GCC/ARM_CM3_MPU/%
C_OBJ_FILTER += $(PROJECT_BASE_PATH)/src/portable/GCC/ARM_CM3/%

C_SRC_TEMP := $(filter-out $(C_OBJ_FILTER), $(C_SRC))
C_OBJ_TEMP = $(patsubst %.c, %.o, $(notdir $(C_SRC_TEMP)))

C_SRC_PATHS := $(sort $(dir $(C_SRC_TEMP)))

vpath %.c $(C_SRC_PATHS)
vpath %.h $(C_SRC_PATHS)
INCLUDES += $(addprefix -I,$(C_SRC_PATHS))
C_OBJ=$(C_OBJ_TEMP)

#-------------------------------------------------------------------------------
# Assembler source files and objects
#-------------------------------------------------------------------------------
A_SRC=$(wildcard $(PROJECT_BASE_PATH)/*.s)

A_OBJ_TEMP=$(patsubst %.s, %.o, $(notdir $(A_SRC)))

# during development, remove some files
A_OBJ_FILTER=

A_OBJ=$(filter-out $(A_OBJ_FILTER), $(A_OBJ_TEMP))

#-------------------------------------------------------------------------------
# Rules
#-------------------------------------------------------------------------------
all: $(VARIANT)

$(VARIANT): create_output $(OUTPUT_LIB)

.PHONY: create_output
create_output:
	@echo ------------------------------------------------------------------------------------
	@echo -------------------------
	@echo --- Preparing variant $(VARIANT) files in $(OUTPUT_PATH) $(OUTPUT_BIN)
	@echo -------------------------
	@echo $(INCLUDES)
	@echo -------------------------
	@echo $(C_SRC)
	@echo -------------------------
	@echo $(C_SRC_PATHS)
	@echo -------------------------
	@echo $(C_OBJ)
	@echo -------------------------
	@echo $(addprefix $(OUTPUT_PATH)/, $(C_OBJ))
	@echo -------------------------
#	@echo *$(CPP_SRC)
#	@echo -------------------------
#	@echo *$(CPP_OBJ)
#	@echo -------------------------
#	@echo *$(addprefix $(OUTPUT_PATH)/, $(CPP_OBJ))
	@echo -------------------------
	@echo $(A_SRC)
	@echo -------------------------

	-@mkdir -p $(OUTPUT_PATH) 1>NUL 2>&1
	@echo ------------------------------------------------------------------------------------

$(addprefix $(OUTPUT_PATH)/,$(C_OBJ)): $(OUTPUT_PATH)/%.o: %.c
#	@"$(CC)" -v -c $(CFLAGS) $< -o $@
	@"$(CC)" -c $(CFLAGS) $< -o $@

$(addprefix $(OUTPUT_PATH)/,$(A_OBJ)): $(OUTPUT_PATH)/%.o: %.s
	@"$(AS)" -c $(ASFLAGS) $< -o $@

$(OUTPUT_LIB): $(addprefix $(OUTPUT_PATH)/, $(C_OBJ)) $(addprefix $(OUTPUT_PATH)/, $(A_OBJ))
	@mkdir -p $(OUTPUT_BIN)
	@"$(AR)" -v -r "$(OUTPUT_BIN)/$@" $^
	@"$(NM)" "$(OUTPUT_BIN)/$@" > "$(OUTPUT_BIN)/$@.txt"


.PHONY: clean
clean:
	@echo ------------------------------------------------------------------------------------
	@echo --- Cleaning $(VARIANT) files [$(OUTPUT_PATH)$(SEP)*.o]
	-@$(RM) $(OUTPUT_PATH) 1>NUL 2>&1
	-@$(RM) $(OUTPUT_BIN)/$(OUTPUT_LIB) 1>NUL 2>&1
	@echo ------------------------------------------------------------------------------------

