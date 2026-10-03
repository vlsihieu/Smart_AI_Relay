#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ILI9341.h>
#include "mit_thui.h"

// Cấu hình chân SPI cho ESP32
#define TFT_CS    5
#define TFT_DC   21
#define TFT_RST   4
#define TFT_MOSI 23
#define TFT_CLK  18
#define TFT_MISO 19

Adafruit_ILI9341 tft = Adafruit_ILI9341(TFT_CS, TFT_DC, TFT_RST);

#define SCREEN_W 320
#define SCREEN_H 240

// Link GitHub dự án
const char* GITHUB_URL = "https://github.com/vlsihieu/Smart_AI_Relay";

// Quản lý trạng thái màn hình
enum AppState {
  STATE_MENU,
  STATE_PROGRAM,
  STATE_USER
};

AppState currentState = STATE_MENU;

struct ButtonPos {
  int x;
  int y;
  int w;
  int h;
  const char* name;
};

// Vị trí 6 ô trên giao diện Menu chính
const ButtonPos buttons[6] = {
  { 10,  32,  94,  78, "Start"   }, // Index 0
  { 113, 32,  94,  78, "Setup"   }, // Index 1
  { 216, 32,  94,  78, "Program" }, // Index 2 -> Mở Relay Control
  { 10,  118, 94,  78, "Card"    }, // Index 3
  { 113, 118, 94,  78, "Diag."   }, // Index 4
  { 216, 118, 94,  78, "User"    }  // Index 5 -> Mở QR Code
};

int currentIndex = 2; // Mặc định trỏ ô Program
int prevIndex = -1;

void drawHighlight(int index, uint16_t color) {
  if (index < 0 || index >= 6) return;
  tft.drawRoundRect(buttons[index].x, buttons[index].y, buttons[index].w, buttons[index].h, 8, color);
  tft.drawRoundRect(buttons[index].x - 1, buttons[index].y - 1, buttons[index].w + 2, buttons[index].h + 2, 8, color);
}

// 1. Màn hình Menu chính
void showMainMenu() {
  currentState = STATE_MENU;
  tft.drawRGBBitmap(0, 0, smart_relay_img, SCREEN_W, SCREEN_H);
  drawHighlight(currentIndex, ILI9341_CYAN);
  Serial.println("\n[MENU CHINH] Dung W/A/S/D de chon, E hoac Space de mo.");
}

// 2. Màn hình Program (Relay Control)
void showProgramScreen() {
  currentState = STATE_PROGRAM;
  tft.drawRGBBitmap(0, 0, relay_control_img, SCREEN_W, SCREEN_H);
  Serial.println("\n[TRANG PROGRAM] Nhan 'B' hoac 'X' tren ban phim de quay ve Menu.");
}

// Ma trận dữ liệu QR Code V4 (33x33) cho link https://github.com/vlsihieu/Smart_AI_Relay
const uint8_t PROGMEM qrMatrixData[33][5] = {
  {0xFE, 0xCE, 0xBE, 0x1F, 0x80},
  {0x82, 0x58, 0x6E, 0x10, 0x80},
  {0xBA, 0xF9, 0x17, 0x17, 0x80},
  {0xBA, 0x2A, 0x93, 0x17, 0x80},
  {0xBA, 0x18, 0x8B, 0x17, 0x80},
  {0x82, 0x05, 0x09, 0x10, 0x80},
  {0xFE, 0x55, 0x55, 0x1F, 0x80},
  {0x00, 0x33, 0x33, 0x00, 0x00},
  {0xEE, 0xEF, 0x23, 0x56, 0x00},
  {0xC5, 0x2D, 0x6B, 0xAD, 0x80},
  {0x92, 0x16, 0xD4, 0x48, 0x80},
  {0xFB, 0x7E, 0x7F, 0x96, 0x00},
  {0x6A, 0x95, 0x42, 0x6E, 0x00},
  {0x6D, 0xCE, 0xBD, 0xB6, 0x80},
  {0x44, 0x89, 0xE7, 0x5C, 0x00},
  {0x76, 0x35, 0x1A, 0x69, 0x00},
  {0x0B, 0x16, 0x6C, 0x66, 0x80},
  {0x35, 0xEA, 0xD6, 0xDF, 0x80},
  {0x56, 0x8B, 0x54, 0xB8, 0x00},
  {0x98, 0xF4, 0x49, 0x63, 0x00},
  {0x5F, 0x02, 0x3F, 0x39, 0x80},
  {0x52, 0x50, 0xE7, 0x87, 0x80},
  {0x00, 0xAC, 0x9B, 0x8A, 0x80},
  {0xFE, 0x5E, 0x95, 0x0A, 0x80},
  {0x82, 0x9F, 0x66, 0x70, 0x00},
  {0xBA, 0x67, 0x8B, 0xB3, 0x80},
  {0xBA, 0xFB, 0x6E, 0x5E, 0x80},
  {0xBA, 0x00, 0xF5, 0x5C, 0x80},
  {0x82, 0xC6, 0x5A, 0xA2, 0x00},
  {0xFE, 0x38, 0xA8, 0x82, 0x80},
  {0x00, 0x00, 0x00, 0x00, 0x00},
  {0x00, 0x00, 0x00, 0x00, 0x00},
  {0x00, 0x00, 0x00, 0x00, 0x00}
};

// 3. Màn hình User (Khung QR Code GitHub)
void showUserScreen() {
  currentState = STATE_USER;
  tft.fillScreen(0x0A2B); // Màu xanh dương đậm chuẩn giao diện

  // 1. Vẽ thanh tiêu đề Top bar
  tft.fillRect(0, 0, SCREEN_W, 26, 0x0188);
  tft.setTextColor(ILI9341_WHITE);
  tft.setTextSize(1);
  tft.setCursor(10, 8);
  tft.print("<- Project Demo");
  tft.setCursor(290, 8);
  tft.setTextColor(ILI9341_GREEN);
  tft.print("OK");

  // 2. Kích thước và tọa độ vẽ QR
  const int qrSize = 33;
  const int pixelSize = 4;
  int qrWidth = qrSize * pixelSize;
  int startX = (SCREEN_W - qrWidth) / 2;
  int startY = 36;

  // Viền trắng bảo vệ mã QR
  tft.fillRect(startX - 8, startY - 8, qrWidth + 16, qrWidth + 16, ILI9341_WHITE);

  // Vẽ các hạt module QR
  for (int y = 0; y < qrSize; y++) {
    for (int x = 0; x < qrSize; x++) {
      uint8_t byteVal = pgm_read_byte(&qrMatrixData[y][x / 8]);
      bool isBlack = (byteVal >> (7 - (x % 8))) & 0x01;
      if (isBlack) {
        tft.fillRect(startX + (x * pixelSize), startY + (y * pixelSize), pixelSize, pixelSize, ILI9341_BLACK);
      }
    }
  }

  // 3. Chú thích phía dưới
  tft.setTextColor(ILI9341_WHITE);
  tft.setTextSize(1);
  tft.setCursor(75, 195);
  tft.print("Scan to open GitHub demo");
  tft.setTextColor(0x8410);
  tft.setCursor(85, 215);
  tft.print("Press 'B' to return");

  Serial.println("\n[TRANG USER] Da hien QR Code. Nhan 'B' de quay ve Menu.");
}

void setup() {
  Serial.begin(115200);
  tft.begin();
  tft.setRotation(1); // Xoay ngang màn hình (320x240)
  tft.fillScreen(ILI9341_BLACK);

  showMainMenu();
}

void loop() {
  if (Serial.available() > 0) {
    char cmd = Serial.read();
    if (cmd == '\r' || cmd == '\n') return;

    // Quay về Menu nếu đang ở trang con
    if (currentState != STATE_MENU) {
      if (cmd == 'b' || cmd == 'B' || cmd == 'x' || cmd == 'X') {
        showMainMenu();
      }
      return;
    }

    // Đang ở Menu chính: Di chuyển khung chọn
    prevIndex = currentIndex;

    switch (cmd) {
      case 'a':
      case 'A': // Sang trái
        if (currentIndex % 3 > 0) currentIndex--;
        break;

      case 'd':
      case 'D': // Sang phải
        if (currentIndex % 3 < 2) currentIndex++;
        break;

      case 'w':
      case 'W': // Lên trên
        if (currentIndex >= 3) currentIndex -= 3;
        break;

      case 's':
      case 'S': // Xuống dưới
        if (currentIndex < 3) currentIndex += 3;
        break;

      case 'e':
      case 'E':
      case ' ': // Enter / Mở mục
        if (currentIndex == 2) {
          showProgramScreen();
        } else if (currentIndex == 5) {
          showUserScreen();
        } else {
          Serial.print("Chuc nang ");
          Serial.print(buttons[currentIndex].name);
          Serial.println(" dang phat trien.");
        }
        return;
    }

    // Cập nhật lại viền lựa chọn
    if (currentIndex != prevIndex && prevIndex != -1) {
      drawHighlight(prevIndex, 0x0188); // Xóa viền cũ
      drawHighlight(currentIndex, ILI9341_CYAN); // Tô viền mới
    }
  }
}