#!/usr/bin/env python3
"""TFT Bitmap Font and RGB565 Picture Generator (PyQt5 + Pillow).

Generates C header files for small TFT/LCD bitmap fonts.  The default output
matches this common embedded layout::

    #define CHAR_WIDTH 6
    #define CHAR_HEIGHT 8
    static const unsigned char font[96][6] = { ... };

Each value represents one vertical column of a glyph.  By default, bit 0 is
the top pixel.  The last column can be reserved as character spacing.

The integrated picture converter loads a common image format, optionally
resizes or rotates it, converts every pixel to RGB565, and generates a C header
whose pixel bytes are ordered high byte first for ILI9341 SPI transfers.

Install and run on Windows:

    py -m pip install PyQt5 Pillow
    py tft_font_generator.py
"""

from __future__ import annotations

import math
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Sequence, Tuple

from PIL import Image, ImageDraw, ImageFont, ImageOps

try:
    from PyQt5.QtCore import QPoint, QSize, Qt, QTimer, pyqtSignal
    from PyQt5.QtGui import QColor, QFont, QImage, QPainter, QPen, QPixmap
    from PyQt5.QtWidgets import (
        QApplication,
        QCheckBox,
        QComboBox,
        QDialog,
        QFileDialog,
        QFormLayout,
        QGridLayout,
        QGroupBox,
        QHBoxLayout,
        QLabel,
        QLineEdit,
        QMainWindow,
        QMessageBox,
        QPushButton,
        QSpinBox,
        QSplitter,
        QStatusBar,
        QTextEdit,
        QVBoxLayout,
        QWidget,
    )

    QT_AVAILABLE = True
except ImportError:
    QT_AVAILABLE = False


PixelMatrix = List[List[bool]]


@dataclass(frozen=True)
class FontSettings:
    font_path: str
    font_size: int = 8
    cell_width: int = 6
    cell_height: int = 8
    right_spacing: int = 1
    x_offset: int = 0
    y_offset: int = 0
    threshold: int = 128
    center_glyphs: bool = True
    lsb_is_top: bool = True


@dataclass(frozen=True)
class ImageExportSettings:
    """Settings used to prepare an image and generate an RGB565 C header."""

    image_path: str
    width: int = 320
    height: int = 240
    resize_mode: str = "stretch"
    rotation: int = 0
    symbol_name: str = "image_data"
    guard_name: str = "IMAGE_DATA_H"


def parse_codepoints(specification: str) -> List[int]:
    """Parse ``32-127,176,0xB0`` into a sorted list of Unicode codepoints."""
    specification = specification.strip()
    if not specification:
        raise ValueError("Character range cannot be empty.")

    result = set()
    for raw_item in specification.split(","):
        item = raw_item.strip()
        if not item:
            continue

        match = re.fullmatch(r"(.+?)\s*-\s*(.+)", item)
        if match:
            start = int(match.group(1), 0)
            end = int(match.group(2), 0)
            if end < start:
                raise ValueError(f"Invalid descending range: {item}")
            if end - start > 4096:
                raise ValueError(f"Range is too large: {item}")
            result.update(range(start, end + 1))
        else:
            result.add(int(item, 0))

    if not result:
        raise ValueError("No valid character code was entered.")
    if min(result) < 0 or max(result) > 0x10FFFF:
        raise ValueError("Character codes must be between 0 and 0x10FFFF.")
    return sorted(result)


def find_default_font() -> str:
    """Return a sensible monospace font path on Windows, Linux, or macOS."""
    candidates = [
        r"C:\Windows\Fonts\consola.ttf",
        r"C:\Windows\Fonts\lucon.ttf",
        r"C:\Windows\Fonts\cour.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/liberation2/LiberationMono-Regular.ttf",
        "/System/Library/Fonts/Menlo.ttc",
        "/System/Library/Fonts/Monaco.ttf",
    ]
    for candidate in candidates:
        if Path(candidate).is_file():
            return candidate
    return ""


def rasterize_glyph(character: str, settings: FontSettings) -> PixelMatrix:
    """Rasterize one character into a boolean row-major pixel matrix."""
    if not settings.font_path or not Path(settings.font_path).is_file():
        raise ValueError("Select a valid .ttf, .otf, or .ttc font file.")
    if not 1 <= settings.cell_height <= 32:
        raise ValueError("Character height must be from 1 to 32 pixels.")
    if not 1 <= settings.cell_width <= 64:
        raise ValueError("Character width must be from 1 to 64 pixels.")
    if not 0 <= settings.right_spacing < settings.cell_width:
        raise ValueError("Right spacing must be smaller than character width.")

    font = ImageFont.truetype(settings.font_path, settings.font_size)
    image = Image.new("L", (settings.cell_width, settings.cell_height), 0)
    draw = ImageDraw.Draw(image)
    drawable_width = settings.cell_width - settings.right_spacing

    # The left-baseline anchor keeps uppercase, lowercase, and punctuation on
    # one common baseline.  Font metrics provide a predictable starting point.
    _ascent, descent = font.getmetrics()
    baseline = settings.cell_height - descent + settings.y_offset
    bbox = draw.textbbox((0, baseline), character, font=font, anchor="ls")
    glyph_width = max(0, bbox[2] - bbox[0])

    if settings.center_glyphs:
        x_position = (drawable_width - glyph_width) // 2 - bbox[0]
    else:
        x_position = -bbox[0]
    x_position += settings.x_offset

    draw.text(
        (x_position, baseline),
        character,
        font=font,
        fill=255,
        anchor="ls",
    )

    pixels = image.load()
    return [
        [pixels[x, y] >= settings.threshold for x in range(settings.cell_width)]
        for y in range(settings.cell_height)
    ]


def pack_columns(matrix: PixelMatrix, lsb_is_top: bool = True) -> List[int]:
    """Pack a row-major bitmap into one integer per vertical column."""
    if not matrix or not matrix[0]:
        return []
    height = len(matrix)
    width = len(matrix[0])
    if height > 32:
        raise ValueError("Column packing supports at most 32 rows.")
    if any(len(row) != width for row in matrix):
        raise ValueError("Pixel matrix rows have different widths.")

    columns: List[int] = []
    for x in range(width):
        value = 0
        for y in range(height):
            if matrix[y][x]:
                bit = y if lsb_is_top else height - 1 - y
                value |= 1 << bit
        columns.append(value)
    return columns


def unpack_columns(
    columns: Sequence[int], height: int, lsb_is_top: bool = True
) -> PixelMatrix:
    """Convert packed columns back to a row-major bitmap."""
    matrix: PixelMatrix = [[False for _ in columns] for _ in range(height)]
    for x, value in enumerate(columns):
        for y in range(height):
            bit = y if lsb_is_top else height - 1 - y
            matrix[y][x] = bool(value & (1 << bit))
    return matrix


def c_identifier(text: str, uppercase: bool = False) -> str:
    """Convert arbitrary text into a valid C identifier."""
    value = re.sub(r"[^A-Za-z0-9_]", "_", text.strip())
    value = re.sub(r"_+", "_", value).strip("_") or "font"
    if value[0].isdigit():
        value = "_" + value
    return value.upper() if uppercase else value


def character_comment(codepoint: int) -> str:
    """Create a safe, readable end-of-line comment for a character."""
    if codepoint == 32:
        label = "space"
    elif codepoint == 127:
        label = "DEL"
    else:
        character = chr(codepoint)
        if character == "\\":
            label = r"\\"
        elif character == "'":
            label = r"\'"
        elif character.isprintable():
            label = character
        else:
            label = f"U+{codepoint:04X}"
    return f"{codepoint:3d} '{label}'"


def integer_type(height: int, use_unsigned_char: bool) -> Tuple[str, int, str]:
    """Return C type, hexadecimal digit count, and optional include line."""
    if use_unsigned_char:
        if height > 8:
            raise ValueError("unsigned char output supports a maximum height of 8.")
        return "unsigned char", 2, ""
    if height <= 8:
        return "uint8_t", 2, "#include <stdint.h>\n\n"
    if height <= 16:
        return "uint16_t", 4, "#include <stdint.h>\n\n"
    return "uint32_t", 8, "#include <stdint.h>\n\n"


def generate_header(
    codepoints: Sequence[int],
    glyphs: Dict[int, Sequence[int]],
    width: int,
    height: int,
    symbol_name: str = "font",
    guard_name: str = "BASIC_5X5_FONT_H",
    use_unsigned_char: bool = True,
    lsb_is_top: bool = True,
) -> str:
    """Generate a complete C header from packed glyph columns."""
    if not codepoints:
        raise ValueError("There are no characters to export.")
    c_type, hex_digits, include_line = integer_type(height, use_unsigned_char)
    symbol = c_identifier(symbol_name)
    guard = c_identifier(guard_name, uppercase=True)

    missing = [codepoint for codepoint in codepoints if codepoint not in glyphs]
    if missing:
        raise ValueError(f"Missing bitmap for character code {missing[0]}.")
    for codepoint in codepoints:
        if len(glyphs[codepoint]) != width:
            raise ValueError(f"Character {codepoint} does not contain {width} columns.")

    bit_description = "bit 0 is top pixel" if lsb_is_top else "highest used bit is top pixel"
    lines = [
        f"#ifndef {guard}",
        f"#define {guard}",
        "",
    ]
    if include_line:
        lines.extend(include_line.rstrip().splitlines())
        lines.append("")
    lines.extend(
        [
            f"#define CHAR_WIDTH {width}",
            f"#define CHAR_HEIGHT {height}",
            f"#define FONT_FIRST_CHAR {codepoints[0]}",
            f"#define FONT_LAST_CHAR {codepoints[-1]}",
            f"#define FONT_CHAR_COUNT {len(codepoints)}",
            "",
            f"/* Column-major bitmap; {bit_description}. */",
            f"static const {c_type} {symbol}[{len(codepoints)}][{width}] = {{",
        ]
    )

    for codepoint in codepoints:
        values = ",".join(f"0x{value:0{hex_digits}X}" for value in glyphs[codepoint])
        lines.append(f"    {{{values}}}, // {character_comment(codepoint)}")

    lines.extend(["};", "", f"#endif /* {guard} */", ""])
    return "\n".join(lines)


def prepare_rgb565_image(settings: ImageExportSettings) -> Image.Image:
    """Load, orient, and resize an image before RGB565 conversion."""
    image_path = Path(settings.image_path)
    if not image_path.is_file():
        raise ValueError("Select a valid picture file.")
    if not 1 <= settings.width <= 4096 or not 1 <= settings.height <= 4096:
        raise ValueError("Image width and height must be from 1 to 4096 pixels.")
    if settings.resize_mode not in {"original", "stretch", "fit", "crop"}:
        raise ValueError(f"Unsupported resize mode: {settings.resize_mode}")
    if settings.rotation not in {0, 90, 180, 270}:
        raise ValueError("Rotation must be 0, 90, 180, or 270 degrees.")

    with Image.open(image_path) as source:
        oriented = ImageOps.exif_transpose(source)
        if "A" in oriented.getbands():
            rgba_image = oriented.convert("RGBA")
            background = Image.new("RGBA", rgba_image.size, (0, 0, 0, 255))
            background.alpha_composite(rgba_image)
            image = background.convert("RGB")
        else:
            image = oriented.convert("RGB")

    transpose_operations = {
        90: Image.Transpose.ROTATE_270,
        180: Image.Transpose.ROTATE_180,
        270: Image.Transpose.ROTATE_90,
    }
    if settings.rotation:
        image = image.transpose(transpose_operations[settings.rotation])

    if settings.resize_mode == "original":
        return image

    target_size = (settings.width, settings.height)
    if settings.resize_mode == "stretch":
        return image.resize(target_size, Image.Resampling.LANCZOS)
    if settings.resize_mode == "fit":
        contained = ImageOps.contain(image, target_size, Image.Resampling.LANCZOS)
        canvas = Image.new("RGB", target_size, (0, 0, 0))
        position = (
            (settings.width - contained.width) // 2,
            (settings.height - contained.height) // 2,
        )
        canvas.paste(contained, position)
        return canvas
    return ImageOps.fit(
        image,
        target_size,
        method=Image.Resampling.LANCZOS,
        centering=(0.5, 0.5),
    )


def rgb565_bytes(image: Image.Image) -> bytes:
    """Convert an RGB image to high-byte-first RGB565 pixel data."""
    rgb_image = image.convert("RGB")
    output = bytearray(rgb_image.width * rgb_image.height * 2)
    offset = 0
    for red, green, blue in rgb_image.getdata():
        value = ((red & 0xF8) << 8) | ((green & 0xFC) << 3) | (blue >> 3)
        output[offset] = (value >> 8) & 0xFF
        output[offset + 1] = value & 0xFF
        offset += 2
    return bytes(output)


def generate_image_header(
    image: Image.Image,
    symbol_name: str = "image_data",
    guard_name: str = "IMAGE_DATA_H",
    bytes_per_line: int = 16,
) -> str:
    """Generate a C header containing high-byte-first RGB565 image data."""
    if image.width <= 0 or image.height <= 0:
        raise ValueError("The converted picture is empty.")
    if bytes_per_line <= 0:
        raise ValueError("Bytes per line must be greater than zero.")

    symbol = c_identifier(symbol_name)
    guard = c_identifier(guard_name, uppercase=True)
    macro_prefix = c_identifier(symbol_name, uppercase=True)
    data = rgb565_bytes(image)
    file_name = f"{symbol}.h"

    lines = [
        "/*******************************************************************************************************************//**",
        f" * @file {file_name}",
        " * @brief Contains RGB565 picture data for an ILI9341 TFT LCD.",
        " *",
        " * Pixels are ordered from left to right and top to bottom. Each pixel is stored as high byte followed by low byte.",
        " **********************************************************************************************************************/",
        "",
        f"#ifndef {guard}",
        f"#define {guard}",
        "",
        "#include <stdint.h>",
        "",
        f"#define {macro_prefix}_WIDTH        ({image.width}U)",
        f"#define {macro_prefix}_HEIGHT       ({image.height}U)",
        f"#define {macro_prefix}_PIXEL_COUNT  ({image.width * image.height}U)",
        f"#define {macro_prefix}_BYTE_COUNT   ({len(data)}U)",
        "",
        "/* Pass this array to ILI9341_Draw_Image() as (const char *). */",
        f"static const uint8_t {symbol}[{macro_prefix}_BYTE_COUNT] =",
        "{",
    ]

    for start in range(0, len(data), bytes_per_line):
        chunk = data[start : start + bytes_per_line]
        values = ", ".join(f"0x{value:02X}U" for value in chunk)
        lines.append(f"    {values},")

    lines.extend(
        [
            "};",
            "",
            f"#endif /* {guard} */",
            "",
        ]
    )
    return "\n".join(lines)


if QT_AVAILABLE:

    class ImageConverterDialog(QDialog):
        """GUI for converting a picture into an ILI9341 RGB565 C array."""

        def __init__(self, parent: QWidget | None = None) -> None:
            super().__init__(parent)
            self.setWindowTitle("Picture to RGB565 Converter")
            self.resize(1120, 760)
            self._converted_image: Image.Image | None = None
            self._generated_header = ""
            self._build_ui()
            self._connect_signals()
            self._update_size_controls()

        def _spin(self, minimum: int, maximum: int, value: int) -> QSpinBox:
            widget = QSpinBox()
            widget.setRange(minimum, maximum)
            widget.setValue(value)
            return widget

        def _build_ui(self) -> None:
            outer = QVBoxLayout(self)

            title = QLabel("Picture to RGB565 Converter")
            title_font = QFont()
            title_font.setPointSize(16)
            title_font.setBold(True)
            title.setFont(title_font)
            outer.addWidget(title)

            description = QLabel(
                "Convert PNG, JPEG, BMP, and other Pillow-supported pictures into a high-byte-first "
                "RGB565 C array for ILI9341_Draw_Image()."
            )
            description.setWordWrap(True)
            outer.addWidget(description)

            source_group = QGroupBox("Picture source")
            source_form = QFormLayout(source_group)
            source_row = QHBoxLayout()
            self.image_path = QLineEdit()
            self.image_path.setPlaceholderText("Select a picture file...")
            self.browse_image_button = QPushButton("Browse...")
            source_row.addWidget(self.image_path, 1)
            source_row.addWidget(self.browse_image_button)
            source_form.addRow("Picture file:", source_row)
            outer.addWidget(source_group)

            settings_group = QGroupBox("RGB565 output")
            settings_grid = QGridLayout(settings_group)
            self.image_width = self._spin(1, 4096, 320)
            self.image_height = self._spin(1, 4096, 240)
            self.resize_mode = QComboBox()
            self.resize_mode.addItem("Stretch to output size", "stretch")
            self.resize_mode.addItem("Fit with black bars", "fit")
            self.resize_mode.addItem("Fill and center crop", "crop")
            self.resize_mode.addItem("Keep original size", "original")
            self.rotation = QComboBox()
            self.rotation.addItem("0 degrees", 0)
            self.rotation.addItem("90 degrees clockwise", 90)
            self.rotation.addItem("180 degrees", 180)
            self.rotation.addItem("270 degrees clockwise", 270)
            self.image_symbol = QLineEdit("image_data")
            self.image_guard = QLineEdit("IMAGE_DATA_H")

            settings_grid.addWidget(QLabel("Output width:"), 0, 0)
            settings_grid.addWidget(self.image_width, 0, 1)
            settings_grid.addWidget(QLabel("Output height:"), 0, 2)
            settings_grid.addWidget(self.image_height, 0, 3)
            settings_grid.addWidget(QLabel("Resize mode:"), 1, 0)
            settings_grid.addWidget(self.resize_mode, 1, 1)
            settings_grid.addWidget(QLabel("Rotate picture:"), 1, 2)
            settings_grid.addWidget(self.rotation, 1, 3)
            settings_grid.addWidget(QLabel("C array name:"), 2, 0)
            settings_grid.addWidget(self.image_symbol, 2, 1)
            settings_grid.addWidget(QLabel("Header guard:"), 2, 2)
            settings_grid.addWidget(self.image_guard, 2, 3)
            outer.addWidget(settings_group)

            splitter = QSplitter(Qt.Horizontal)
            outer.addWidget(splitter, 1)

            preview_panel = QWidget()
            preview_layout = QVBoxLayout(preview_panel)
            preview_layout.addWidget(QLabel("Converted picture preview:"))
            self.image_preview = QLabel("No picture selected")
            self.image_preview.setAlignment(Qt.AlignCenter)
            self.image_preview.setMinimumSize(360, 300)
            self.image_preview.setStyleSheet(
                "QLabel { background: #20252B; color: #DDE3EA; border: 1px solid #68717C; }"
            )
            preview_layout.addWidget(self.image_preview, 1)
            self.image_information = QLabel("Output: --")
            self.image_information.setTextInteractionFlags(Qt.TextSelectableByMouse)
            preview_layout.addWidget(self.image_information)
            splitter.addWidget(preview_panel)

            output_panel = QWidget()
            output_layout = QVBoxLayout(output_panel)
            output_layout.addWidget(QLabel("Generated RGB565 C header:"))
            self.image_header_preview = QTextEdit()
            self.image_header_preview.setReadOnly(True)
            mono = QFont("Consolas")
            mono.setStyleHint(QFont.Monospace)
            self.image_header_preview.setFont(mono)
            output_layout.addWidget(self.image_header_preview, 1)
            splitter.addWidget(output_panel)
            splitter.setSizes([430, 650])

            button_row = QHBoxLayout()
            self.convert_image_button = QPushButton("Convert picture")
            self.copy_image_button = QPushButton("Copy C code")
            self.save_image_button = QPushButton("Save .h...")
            self.close_image_button = QPushButton("Close")
            button_row.addWidget(self.convert_image_button)
            button_row.addStretch(1)
            button_row.addWidget(self.copy_image_button)
            button_row.addWidget(self.save_image_button)
            button_row.addWidget(self.close_image_button)
            outer.addLayout(button_row)

        def _connect_signals(self) -> None:
            self.browse_image_button.clicked.connect(self.choose_picture)
            self.resize_mode.currentIndexChanged.connect(self._update_size_controls)
            self.convert_image_button.clicked.connect(self.convert_picture)
            self.copy_image_button.clicked.connect(self.copy_image_header)
            self.save_image_button.clicked.connect(self.save_image_header)
            self.close_image_button.clicked.connect(self.accept)

        def _update_size_controls(self, *_args) -> None:
            enabled = self.resize_mode.currentData() != "original"
            self.image_width.setEnabled(enabled)
            self.image_height.setEnabled(enabled)

        def choose_picture(self) -> None:
            selected, _ = QFileDialog.getOpenFileName(
                self,
                "Select picture",
                self.image_path.text() or str(Path.home()),
                "Picture files (*.png *.jpg *.jpeg *.bmp *.gif *.tif *.tiff *.webp);;All files (*.*)",
            )
            if not selected:
                return
            self.image_path.setText(selected)
            symbol = c_identifier(Path(selected).stem) + "_rgb565"
            self.image_symbol.setText(symbol)
            self.image_guard.setText(c_identifier(symbol + "_H", uppercase=True))
            self.convert_picture()

        def current_image_settings(self) -> ImageExportSettings:
            return ImageExportSettings(
                image_path=self.image_path.text().strip(),
                width=self.image_width.value(),
                height=self.image_height.value(),
                resize_mode=str(self.resize_mode.currentData()),
                rotation=int(self.rotation.currentData()),
                symbol_name=self.image_symbol.text(),
                guard_name=self.image_guard.text(),
            )

        def convert_picture(self) -> bool:
            try:
                settings = self.current_image_settings()
                image = prepare_rgb565_image(settings)
                header = generate_image_header(
                    image,
                    symbol_name=settings.symbol_name,
                    guard_name=settings.guard_name,
                )
                self._converted_image = image
                self._generated_header = header
                self.image_header_preview.setPlainText(header)
                self._show_picture_preview(image)
                byte_count = image.width * image.height * 2
                self.image_information.setText(
                    f"Output: {image.width} x {image.height} pixels | RGB565 | {byte_count:,} bytes"
                )
                return True
            except Exception as error:
                self._converted_image = None
                self._generated_header = ""
                self.image_header_preview.setPlainText(f"Conversion error:\n{error}")
                self.image_information.setText("Output: --")
                QMessageBox.critical(self, "Cannot convert picture", str(error))
                return False

        def _show_picture_preview(self, image: Image.Image) -> None:
            rgb_image = image.convert("RGB")
            raw_data = rgb_image.tobytes()
            qt_image = QImage(
                raw_data,
                rgb_image.width,
                rgb_image.height,
                rgb_image.width * 3,
                QImage.Format_RGB888,
            ).copy()
            pixmap = QPixmap.fromImage(qt_image)
            self.image_preview.setPixmap(
                pixmap.scaled(
                    self.image_preview.size(),
                    Qt.KeepAspectRatio,
                    Qt.SmoothTransformation,
                )
            )

        def copy_image_header(self) -> None:
            if not self.convert_picture():
                return
            QApplication.clipboard().setText(self._generated_header)
            QMessageBox.information(self, "RGB565 converter", "C header copied to clipboard.")

        def save_image_header(self) -> None:
            if not self.convert_picture():
                return
            suggested = c_identifier(self.image_symbol.text()) + ".h"
            selected, _ = QFileDialog.getSaveFileName(
                self,
                "Save RGB565 C header",
                suggested,
                "C header (*.h);;All files (*.*)",
            )
            if not selected:
                return
            try:
                Path(selected).write_text(self._generated_header, encoding="utf-8", newline="\n")
                QMessageBox.information(self, "RGB565 converter", f"Saved:\n{selected}")
            except OSError as error:
                QMessageBox.critical(self, "Cannot save file", str(error))

    class PixelEditor(QWidget):
        """Clickable grid used to inspect and manually correct one glyph."""

        bitmap_changed = pyqtSignal()

        def __init__(self, parent: QWidget | None = None) -> None:
            super().__init__(parent)
            self._matrix: PixelMatrix = [[False] * 6 for _ in range(8)]
            self.setMinimumSize(260, 260)

        def sizeHint(self) -> QSize:  # noqa: N802 - Qt API naming
            return QSize(360, 360)

        def set_matrix(self, matrix: PixelMatrix) -> None:
            self._matrix = [row[:] for row in matrix]
            self.update()

        def matrix(self) -> PixelMatrix:
            return [row[:] for row in self._matrix]

        def _geometry(self) -> Tuple[int, int, int]:
            rows = max(1, len(self._matrix))
            columns = max(1, len(self._matrix[0]) if self._matrix else 1)
            cell = max(4, min((self.width() - 20) // columns, (self.height() - 20) // rows))
            grid_width = cell * columns
            grid_height = cell * rows
            return cell, (self.width() - grid_width) // 2, (self.height() - grid_height) // 2

        def paintEvent(self, _event) -> None:  # noqa: N802 - Qt API naming
            painter = QPainter(self)
            painter.fillRect(self.rect(), QColor("#F4F6F8"))
            if not self._matrix or not self._matrix[0]:
                return
            cell, origin_x, origin_y = self._geometry()
            painter.setPen(QPen(QColor("#AAB2BD"), 1))
            for y, row in enumerate(self._matrix):
                for x, enabled in enumerate(row):
                    color = QColor("#18212B") if enabled else QColor("#FFFFFF")
                    painter.fillRect(origin_x + x * cell, origin_y + y * cell, cell, cell, color)
                    painter.drawRect(origin_x + x * cell, origin_y + y * cell, cell, cell)

        def mousePressEvent(self, event) -> None:  # noqa: N802 - Qt API naming
            if event.button() != Qt.LeftButton or not self._matrix or not self._matrix[0]:
                return
            cell, origin_x, origin_y = self._geometry()
            x = (event.x() - origin_x) // cell
            y = (event.y() - origin_y) // cell
            if 0 <= y < len(self._matrix) and 0 <= x < len(self._matrix[0]):
                self._matrix[y][x] = not self._matrix[y][x]
                self.update()
                self.bitmap_changed.emit()


    class MainWindow(QMainWindow):
        def __init__(self) -> None:
            super().__init__()
            self.setWindowTitle("TFT Bitmap Font Generator")
            self.resize(1180, 760)

            self.codepoints: List[int] = []
            self.generated_matrices: Dict[int, PixelMatrix] = {}
            self.manual_matrices: Dict[int, PixelMatrix] = {}
            self._updating_editor = False

            self._build_ui()
            self._connect_signals()
            self.regenerate()

        def _spin(self, minimum: int, maximum: int, value: int) -> QSpinBox:
            widget = QSpinBox()
            widget.setRange(minimum, maximum)
            widget.setValue(value)
            return widget

        def _build_ui(self) -> None:
            root = QWidget()
            self.setCentralWidget(root)
            outer = QVBoxLayout(root)

            title_row = QHBoxLayout()
            title = QLabel("TFT Bitmap Font Generator")
            title_font = QFont()
            title_font.setPointSize(18)
            title_font.setBold(True)
            title.setFont(title_font)
            title_row.addWidget(title)
            title_row.addStretch(1)
            self.picture_converter_button = QPushButton("Picture to RGB565...")
            title_row.addWidget(self.picture_converter_button)
            outer.addLayout(title_row)

            subtitle = QLabel(
                "Generate column-major C font arrays for ILI9341 and other TFT/LCD drivers. "
                "Click pixels in the preview to correct a glyph manually."
            )
            subtitle.setWordWrap(True)
            outer.addWidget(subtitle)

            settings_row = QHBoxLayout()
            outer.addLayout(settings_row)

            source_group = QGroupBox("Font source")
            source_form = QFormLayout(source_group)
            font_path_row = QHBoxLayout()
            self.font_path = QLineEdit(find_default_font())
            self.browse_button = QPushButton("Browse...")
            font_path_row.addWidget(self.font_path, 1)
            font_path_row.addWidget(self.browse_button)
            source_form.addRow("TTF/OTF file:", font_path_row)
            self.font_size = self._spin(4, 128, 8)
            self.range_edit = QLineEdit("32-127")
            self.range_edit.setToolTip("Examples: 32-127 or 32-126,176 or 0x20-0x7F")
            source_form.addRow("Font size:", self.font_size)
            source_form.addRow("Character codes:", self.range_edit)
            settings_row.addWidget(source_group, 2)

            bitmap_group = QGroupBox("Bitmap")
            bitmap_grid = QGridLayout(bitmap_group)
            self.cell_width = self._spin(1, 64, 6)
            self.cell_height = self._spin(1, 32, 8)
            self.spacing = self._spin(0, 63, 1)
            self.x_offset = self._spin(-32, 32, 0)
            self.y_offset = self._spin(-32, 32, 0)
            self.threshold = self._spin(1, 254, 128)
            self.center_glyphs = QCheckBox("Center glyphs")
            self.center_glyphs.setChecked(True)
            bitmap_grid.addWidget(QLabel("Width:"), 0, 0)
            bitmap_grid.addWidget(self.cell_width, 0, 1)
            bitmap_grid.addWidget(QLabel("Height:"), 0, 2)
            bitmap_grid.addWidget(self.cell_height, 0, 3)
            bitmap_grid.addWidget(QLabel("Right spacing:"), 1, 0)
            bitmap_grid.addWidget(self.spacing, 1, 1)
            bitmap_grid.addWidget(QLabel("X offset:"), 1, 2)
            bitmap_grid.addWidget(self.x_offset, 1, 3)
            bitmap_grid.addWidget(QLabel("Y offset:"), 2, 0)
            bitmap_grid.addWidget(self.y_offset, 2, 1)
            bitmap_grid.addWidget(QLabel("Threshold:"), 2, 2)
            bitmap_grid.addWidget(self.threshold, 2, 3)
            bitmap_grid.addWidget(self.center_glyphs, 3, 0, 1, 2)
            settings_row.addWidget(bitmap_group, 2)

            output_group = QGroupBox("C output")
            output_form = QFormLayout(output_group)
            self.symbol_name = QLineEdit("font")
            self.guard_name = QLineEdit("BASIC_5X5_FONT_H")
            self.c_type = QComboBox()
            self.c_type.addItems(["unsigned char (height <= 8)", "Auto uint8_t/uint16_t/uint32_t"])
            self.bit_order = QComboBox()
            self.bit_order.addItems(["LSB = top pixel", "MSB = top pixel"])
            output_form.addRow("Array name:", self.symbol_name)
            output_form.addRow("Header guard:", self.guard_name)
            output_form.addRow("C type:", self.c_type)
            output_form.addRow("Bit order:", self.bit_order)
            settings_row.addWidget(output_group, 2)

            splitter = QSplitter(Qt.Horizontal)
            outer.addWidget(splitter, 1)

            preview_panel = QWidget()
            preview_layout = QVBoxLayout(preview_panel)
            character_row = QHBoxLayout()
            character_row.addWidget(QLabel("Preview character:"))
            self.character_combo = QComboBox()
            character_row.addWidget(self.character_combo, 1)
            self.reset_character = QPushButton("Reset character")
            character_row.addWidget(self.reset_character)
            preview_layout.addLayout(character_row)
            self.pixel_editor = PixelEditor()
            preview_layout.addWidget(self.pixel_editor, 1)
            self.byte_label = QLabel("Bytes: --")
            self.byte_label.setTextInteractionFlags(Qt.TextSelectableByMouse)
            preview_layout.addWidget(self.byte_label)
            splitter.addWidget(preview_panel)

            output_panel = QWidget()
            output_layout = QVBoxLayout(output_panel)
            output_layout.addWidget(QLabel("Generated header preview:"))
            self.header_preview = QTextEdit()
            self.header_preview.setReadOnly(True)
            mono = QFont("Consolas")
            mono.setStyleHint(QFont.Monospace)
            self.header_preview.setFont(mono)
            output_layout.addWidget(self.header_preview, 1)
            button_row = QHBoxLayout()
            self.regenerate_button = QPushButton("Regenerate")
            self.copy_button = QPushButton("Copy C code")
            self.save_button = QPushButton("Save .h...")
            button_row.addWidget(self.regenerate_button)
            button_row.addStretch(1)
            button_row.addWidget(self.copy_button)
            button_row.addWidget(self.save_button)
            output_layout.addLayout(button_row)
            splitter.addWidget(output_panel)
            splitter.setSizes([430, 700])

            self.setStatusBar(QStatusBar())
            self._timer = QTimer(self)
            self._timer.setSingleShot(True)
            self._timer.setInterval(180)
            self._timer.timeout.connect(self.regenerate)

        def _connect_signals(self) -> None:
            self.browse_button.clicked.connect(self.choose_font)
            self.picture_converter_button.clicked.connect(self.open_picture_converter)
            self.regenerate_button.clicked.connect(self.regenerate)
            self.save_button.clicked.connect(self.save_header)
            self.copy_button.clicked.connect(self.copy_header)
            self.character_combo.currentIndexChanged.connect(self.show_current_character)
            self.pixel_editor.bitmap_changed.connect(self.store_manual_edit)
            self.reset_character.clicked.connect(self.reset_current_character)

            widgets = [
                self.font_path,
                self.range_edit,
                self.symbol_name,
                self.guard_name,
                self.font_size,
                self.cell_width,
                self.cell_height,
                self.spacing,
                self.x_offset,
                self.y_offset,
                self.threshold,
                self.center_glyphs,
                self.c_type,
                self.bit_order,
            ]
            for widget in widgets:
                if isinstance(widget, QLineEdit):
                    widget.textChanged.connect(self.schedule_regenerate)
                elif isinstance(widget, QSpinBox):
                    widget.valueChanged.connect(self.schedule_regenerate)
                elif isinstance(widget, QCheckBox):
                    widget.stateChanged.connect(self.schedule_regenerate)
                elif isinstance(widget, QComboBox):
                    widget.currentIndexChanged.connect(self.schedule_regenerate)

        def schedule_regenerate(self, *_args) -> None:
            self.manual_matrices.clear()
            self._timer.start()

        def current_settings(self) -> FontSettings:
            return FontSettings(
                font_path=self.font_path.text().strip(),
                font_size=self.font_size.value(),
                cell_width=self.cell_width.value(),
                cell_height=self.cell_height.value(),
                right_spacing=self.spacing.value(),
                x_offset=self.x_offset.value(),
                y_offset=self.y_offset.value(),
                threshold=self.threshold.value(),
                center_glyphs=self.center_glyphs.isChecked(),
                lsb_is_top=self.bit_order.currentIndex() == 0,
            )

        def choose_font(self) -> None:
            selected, _ = QFileDialog.getOpenFileName(
                self,
                "Select font",
                self.font_path.text() or str(Path.home()),
                "Font files (*.ttf *.otf *.ttc);;All files (*.*)",
            )
            if selected:
                self.font_path.setText(selected)

        def open_picture_converter(self) -> None:
            dialog = ImageConverterDialog(self)
            dialog.exec_()

        def regenerate(self) -> None:
            try:
                settings = self.current_settings()
                if settings.right_spacing >= settings.cell_width:
                    self.spacing.setValue(max(0, settings.cell_width - 1))
                    settings = self.current_settings()
                codepoints = parse_codepoints(self.range_edit.text())
                previous_codepoint = self.current_codepoint()
                matrices = {
                    codepoint: rasterize_glyph(chr(codepoint), settings)
                    for codepoint in codepoints
                }
                self.codepoints = codepoints
                self.generated_matrices = matrices
                self.manual_matrices = {
                    codepoint: matrix
                    for codepoint, matrix in self.manual_matrices.items()
                    if codepoint in matrices
                }
                self._populate_character_combo(previous_codepoint)
                self.refresh_header()
                self.show_current_character()
                self.statusBar().showMessage(
                    f"Generated {len(codepoints)} glyphs at "
                    f"{settings.cell_width}x{settings.cell_height} pixels.",
                    5000,
                )
            except Exception as error:
                self.header_preview.setPlainText(f"Generation error:\n{error}")
                self.byte_label.setText("Bytes: --")
                self.statusBar().showMessage(str(error))

        def _populate_character_combo(self, preferred: int | None) -> None:
            self.character_combo.blockSignals(True)
            self.character_combo.clear()
            selected_index = 0
            for index, codepoint in enumerate(self.codepoints):
                label = "space" if codepoint == 32 else ("DEL" if codepoint == 127 else chr(codepoint))
                self.character_combo.addItem(f"{codepoint:3d}  {label}", codepoint)
                if codepoint == preferred:
                    selected_index = index
            if self.character_combo.count():
                self.character_combo.setCurrentIndex(selected_index)
            self.character_combo.blockSignals(False)

        def current_codepoint(self) -> int | None:
            value = self.character_combo.currentData()
            return int(value) if value is not None else None

        def active_matrix(self, codepoint: int) -> PixelMatrix:
            matrix = self.manual_matrices.get(codepoint, self.generated_matrices[codepoint])
            return [row[:] for row in matrix]

        def show_current_character(self, *_args) -> None:
            codepoint = self.current_codepoint()
            if codepoint is None or codepoint not in self.generated_matrices:
                return
            self._updating_editor = True
            matrix = self.active_matrix(codepoint)
            self.pixel_editor.set_matrix(matrix)
            self._updating_editor = False
            values = pack_columns(matrix, self.current_settings().lsb_is_top)
            digits = 2 if self.cell_height.value() <= 8 else (4 if self.cell_height.value() <= 16 else 8)
            self.byte_label.setText(
                "Columns: " + ", ".join(f"0x{value:0{digits}X}" for value in values)
            )

        def store_manual_edit(self) -> None:
            if self._updating_editor:
                return
            codepoint = self.current_codepoint()
            if codepoint is None:
                return
            self.manual_matrices[codepoint] = self.pixel_editor.matrix()
            self.refresh_header()
            self.show_current_character()

        def reset_current_character(self) -> None:
            codepoint = self.current_codepoint()
            if codepoint is not None:
                self.manual_matrices.pop(codepoint, None)
                self.refresh_header()
                self.show_current_character()

        def packed_glyphs(self) -> Dict[int, List[int]]:
            lsb_is_top = self.current_settings().lsb_is_top
            return {
                codepoint: pack_columns(self.active_matrix(codepoint), lsb_is_top)
                for codepoint in self.codepoints
            }

        def build_header(self) -> str:
            settings = self.current_settings()
            return generate_header(
                codepoints=self.codepoints,
                glyphs=self.packed_glyphs(),
                width=settings.cell_width,
                height=settings.cell_height,
                symbol_name=self.symbol_name.text(),
                guard_name=self.guard_name.text(),
                use_unsigned_char=self.c_type.currentIndex() == 0,
                lsb_is_top=settings.lsb_is_top,
            )

        def refresh_header(self) -> None:
            try:
                self.header_preview.setPlainText(self.build_header())
            except Exception as error:
                self.header_preview.setPlainText(f"Generation error:\n{error}")

        def copy_header(self) -> None:
            try:
                QApplication.clipboard().setText(self.build_header())
                self.statusBar().showMessage("C header copied to clipboard.", 4000)
            except Exception as error:
                QMessageBox.critical(self, "Cannot copy", str(error))

        def save_header(self) -> None:
            try:
                content = self.build_header()
            except Exception as error:
                QMessageBox.critical(self, "Cannot generate header", str(error))
                return
            suggested = c_identifier(self.symbol_name.text()) + ".h"
            selected, _ = QFileDialog.getSaveFileName(
                self, "Save C header", suggested, "C header (*.h);;All files (*.*)"
            )
            if not selected:
                return
            try:
                Path(selected).write_text(content, encoding="utf-8", newline="\n")
                self.statusBar().showMessage(f"Saved: {selected}", 6000)
            except OSError as error:
                QMessageBox.critical(self, "Cannot save file", str(error))


def main() -> int:
    if not QT_AVAILABLE:
        print("PyQt5 is not installed.", file=sys.stderr)
        print("Install dependencies with: py -m pip install PyQt5 Pillow", file=sys.stderr)
        return 1
    application = QApplication(sys.argv)
    application.setApplicationName("TFT Bitmap Font Generator")
    window = MainWindow()
    window.show()
    return application.exec_()


if __name__ == "__main__":
    raise SystemExit(main())