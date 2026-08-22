CJM410 hardware design note

Pleae refer to the datasheet for pin definiton and EVB schematic for reference hardware design.
Besdies, please also notice the following items while hardware board design.

1. Pin 20: IOT_MODE_EN: JP5, keep high.
2. Pin 18: GPIO0: JP9, keep low.
3. Pin 11: GPIO8: JP11, keep low.
4. Pin 13, GPIO4, JP10, high is for UART mode, and low is for ART mode. 
ART mode is used for firmware update and certification test, so this pin is designed for mode switch.
5. Pin 26, 27: USB. The USB port is used for ART mode.
6. Pin 19: CHIP_PWD_L: S1, hardware rest.
7. Pin 29: GPIO_IOE1, S2, wake up from MCU. If the application needn't enter power save mode, pleae keep high.
8. The pin 2, 3, 4,5 : High speed UART, and Pin 38, 39: debug UART. 
The pin definition in datasheet is different from EVB schematic, but please follow the datasheet.