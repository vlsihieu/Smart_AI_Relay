################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/ILI9341/aplication/Application.c \
../src/ILI9341/aplication/BTN_ep.c \
../src/ILI9341/aplication/Ui_Home_ep.c \
../src/ILI9341/aplication/Ui_Qr_ep.c \
../src/ILI9341/aplication/Ui_Relay_ep.c 

C_DEPS += \
./src/ILI9341/aplication/Application.d \
./src/ILI9341/aplication/BTN_ep.d \
./src/ILI9341/aplication/Ui_Home_ep.d \
./src/ILI9341/aplication/Ui_Qr_ep.d \
./src/ILI9341/aplication/Ui_Relay_ep.d 

OBJS += \
./src/ILI9341/aplication/Application.o \
./src/ILI9341/aplication/BTN_ep.o \
./src/ILI9341/aplication/Ui_Home_ep.o \
./src/ILI9341/aplication/Ui_Qr_ep.o \
./src/ILI9341/aplication/Ui_Relay_ep.o 

SREC += \
spi_ek_ra6m5_ep.srec 

MAP += \
spi_ek_ra6m5_ep.map 


# Each subdirectory must supply rules for building sources it contributes
src/ILI9341/aplication/%.o: ../src/ILI9341/aplication/%.c
	$(file > $@.in,-mcpu=cortex-m33 -mthumb -mfloat-abi=hard -mfpu=fpv5-sp-d16 -O2 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -Wunused -Wuninitialized -Wall -Wextra -Wmissing-declarations -Wconversion -Wpointer-arith -Wshadow -Wlogical-op -Waggregate-return -Wfloat-equal -g -D_RENESAS_RA_ -D_RA_CORE=CM33 -D_RA_ORDINAL=1 -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/src" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/ra/fsp/inc" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/ra/fsp/inc/api" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/ra/fsp/inc/instances" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/ra_gen" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/ra_cfg/fsp_cfg/bsp" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/ra_cfg/fsp_cfg" -I"." -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/ra/arm/CMSIS_6/CMSIS/Core/Include" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/src/ILI9341" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/src/ILI9341/driver" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/src/ILI9341/aplication" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/src/ILI9341/assert/font" -I"D:/workspace/spi_ek_ra6m5_ep/e2studio/src/ILI9341/assert/ui" -std=c99 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" -x c "$<")
	@echo Building file: $< && arm-none-eabi-gcc @"$@.in"

