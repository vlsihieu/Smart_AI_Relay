################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/ip/cjm410/cjm410.c 

C_DEPS += \
./src/ip/cjm410/cjm410.d 

OBJS += \
./src/ip/cjm410/cjm410.o 

SREC += \
spi_ek_ra6m5_ep.srec 

MAP += \
spi_ek_ra6m5_ep.map 


# Each subdirectory must supply rules for building sources it contributes
src/ip/cjm410/%.o: ../src/ip/cjm410/%.c
	$(file > $@.in,-mcpu=cortex-m33 -mthumb -mfloat-abi=hard -mfpu=fpv5-sp-d16 -O2 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -Wunused -Wuninitialized -Wall -Wextra -Wmissing-declarations -Wconversion -Wpointer-arith -Wshadow -Wlogical-op -Waggregate-return -Wfloat-equal -g -D_RENESAS_RA_ -D_RA_CORE=CM33 -D_RA_ORDINAL=1 -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/src" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/ra/fsp/inc" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/ra/fsp/inc/api" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/ra/fsp/inc/instances" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/ra_gen" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/ra_cfg/fsp_cfg/bsp" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/ra_cfg/fsp_cfg" -I"." -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/ra/arm/CMSIS_6/CMSIS/Core/Include" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/src/hld/inc" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/src/ipc/inc" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/src/ip/relay" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/src/ip/ili9341" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/src/ip/assert/font" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/src/ip/assert/ui" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/src/ip/cjm410" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/src/ip/cjm410_port" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/src/ip/button" -std=c99 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" -x c "$<")
	@echo Building file: $< && arm-none-eabi-gcc @"$@.in"

