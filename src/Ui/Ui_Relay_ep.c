/*******************************************************************************************************************//**
 * @file UI_Relay.c
 * @brief Implements the eight-channel relay-control UI for the Smart Relay application.
 *
 * The full-screen RGB565 bitmap is loaded when the Program item is opened. Direction actions move the focus through
 * a two-row by four-column grid. SELECT toggles the focused relay, BACK requests the previous screen, and HOME requests
 * the Home screen. Only the changed cursor or relay-state area is redrawn after the initial full-screen transfer.
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include <stddef.h>
#include "Ui_Relay_ep.h"
#include "ILI9341_GFX.h"
#include "relay_control_320x240_rgb565.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

/* Relay menu geometry. */
#define UI_RELAY_COLUMN_COUNT                 (4U)
#define UI_RELAY_ROW_COUNT                    (2U)

/* Colors sampled from the Relay Control bitmap. */
#define UI_RELAY_OUTER_BACKGROUND_COLOR       (0x08A5U)
#define UI_RELAY_TILE_BACKGROUND_COLOR        (0x1149U)
#define UI_RELAY_CURSOR_COLOR                 (0xFFE0U)
#define UI_RELAY_STATE_ON_COLOR               (0x262FU)
#define UI_RELAY_STATE_OFF_COLOR              (0x5B2FU)
#define UI_RELAY_SWITCH_TRACK_COLOR           (0x21CAU)

/* Buffered dynamic-state drawing area inside each relay tile. */
#define UI_RELAY_STATE_AREA_WIDTH             (64U)
#define UI_RELAY_STATE_AREA_HEIGHT            (45U)
#define UI_RELAY_STATE_TEXT_Y                  (2U)
#define UI_RELAY_STATE_GLYPH_WIDTH             (5U)
#define UI_RELAY_STATE_GLYPH_HEIGHT            (7U)
#define UI_RELAY_STATE_GLYPH_SCALE             (2U)
#define UI_RELAY_STATE_GLYPH_SPACING           (2U)
#define UI_RELAY_SWITCH_X                      (13U)
#define UI_RELAY_SWITCH_Y                      (32U)
#define UI_RELAY_SWITCH_WIDTH                  (38U)
#define UI_RELAY_SWITCH_HEIGHT                 (10U)
#define UI_RELAY_SWITCH_KNOB_RADIUS            (5)
#define UI_RELAY_SWITCH_KNOB_OFF_X             (18)
#define UI_RELAY_SWITCH_KNOB_ON_X              (46)
#define UI_RELAY_SWITCH_KNOB_Y                 (37)

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/** Cursor rectangle and dynamic-state origin associated with one relay tile. */
typedef struct st_ui_relay_position
{
    uint16_t cursor_x0;
    uint16_t cursor_y0;
    uint16_t cursor_x1;
    uint16_t cursor_y1;
    uint16_t state_x;
    uint16_t state_y;
} ui_relay_position_t;

/***********************************************************************************************************************
 * Private function declarations
 **********************************************************************************************************************/

static fsp_err_t ui_relay_render_screen(void);
static fsp_err_t ui_relay_draw_cursor(ui_relay_channel_t channel, uint16_t color);
static fsp_err_t ui_relay_draw_all_states(void);
static fsp_err_t ui_relay_draw_state(ui_relay_channel_t channel);
static fsp_err_t ui_relay_move_focus(uint32_t action);
static fsp_err_t ui_relay_toggle_selected(void);
static void      ui_relay_prepare_state_buffer(bool enabled);
static void      ui_relay_render_word(bool enabled, uint16_t color);
static void      ui_relay_render_glyph(uint8_t const glyph[UI_RELAY_STATE_GLYPH_HEIGHT],
                                       uint16_t      x,
                                       uint16_t      y,
                                       uint16_t      color);
static void      ui_relay_render_knob(int32_t center_x, int32_t center_y, uint16_t color);

/***********************************************************************************************************************
 * Private global variables
 **********************************************************************************************************************/

/* Cursor rectangles are one pixel outside the rounded tile borders in the bitmap. */
static ui_relay_position_t const g_ui_relay_positions[UI_RELAY_CHANNEL_COUNT] =
{
    {4U,   48U,  80U, 128U,  11U,  77U},
    {82U,  48U, 158U, 128U,  89U,  77U},
    {160U, 48U, 236U, 128U, 167U,  77U},
    {238U, 48U, 314U, 128U, 245U,  77U},
    {4U,  130U,  80U, 210U,  11U, 159U},
    {82U, 130U, 158U, 210U,  89U, 159U},
    {160U,130U, 236U, 210U, 167U, 159U},
    {238U,130U, 314U, 210U, 245U, 159U}
};

/* Five-by-seven glyph rows. Bits 4 through 0 represent the five columns. */
static uint8_t const g_ui_relay_glyph_o[UI_RELAY_STATE_GLYPH_HEIGHT] =
{
    0x0EU, 0x11U, 0x11U, 0x11U, 0x11U, 0x11U, 0x0EU
};

static uint8_t const g_ui_relay_glyph_n[UI_RELAY_STATE_GLYPH_HEIGHT] =
{
    0x11U, 0x19U, 0x19U, 0x15U, 0x13U, 0x13U, 0x11U
};

static uint8_t const g_ui_relay_glyph_f[UI_RELAY_STATE_GLYPH_HEIGHT] =
{
    0x1FU, 0x10U, 0x10U, 0x1EU, 0x10U, 0x10U, 0x10U
};

static ui_relay_cfg_t     g_ui_relay_cfg;
static ui_relay_channel_t g_ui_relay_selected_channel = UI_RELAY_CHANNEL_1;
static uint8_t            g_ui_relay_state_mask;
static bool               g_ui_relay_initialized;
static bool               g_ui_relay_active;
static uint16_t           g_ui_relay_state_buffer[UI_RELAY_STATE_AREA_WIDTH * UI_RELAY_STATE_AREA_HEIGHT];

/*******************************************************************************************************************//**
 * @addtogroup UI_Relay
 * @{
 **********************************************************************************************************************/

void app_main_relay(void)
{
    fsp_err_t err;

    err = ILI9341_Init();
    if (FSP_SUCCESS != err)
    {
        return;
    }

    err = UI_Relay_Init(NULL);
    if (FSP_SUCCESS != err)
    {
        return;
    }

    err = UI_Relay_Open();
    if (FSP_SUCCESS != err)
    {
        return;
    }

    while (1)
    {
        /* Relay screen remains displayed. */
    }
}

/*******************************************************************************************************************//**
 * @brief Initializes the Relay UI state without drawing the screen.
 *
 * Pass NULL to use simulated outputs with all relays initially OFF. When p_output_write is configured, SELECT calls
 * the callback before committing and redrawing the new relay state.
 *
 * @param[in] p_cfg Optional Relay UI configuration.
 *
 * @retval FSP_SUCCESS          The Relay UI state was initialized successfully.
 * @retval FSP_ERR_ALREADY_OPEN The module is already initialized.
 **********************************************************************************************************************/
fsp_err_t UI_Relay_Init(ui_relay_cfg_t const * p_cfg)
{
    if (g_ui_relay_initialized)
    {
        return FSP_ERR_ALREADY_OPEN;
    }

    if (NULL != p_cfg)
    {
        g_ui_relay_cfg = *p_cfg;
        g_ui_relay_state_mask = (uint8_t) (p_cfg->initial_state_mask & UI_RELAY_ALL_CHANNELS_MASK);
    }
    else
    {
        g_ui_relay_cfg.p_output_write     = NULL;
        g_ui_relay_cfg.p_context          = NULL;
        g_ui_relay_cfg.initial_state_mask = 0U;
        g_ui_relay_state_mask             = 0U;
    }

    g_ui_relay_selected_channel = UI_RELAY_CHANNEL_1;
    g_ui_relay_active           = false;
    g_ui_relay_initialized      = true;

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Opens the Relay Control screen and resets focus to Relay 1.
 *
 * @retval FSP_SUCCESS      The bitmap, eight states, and focus cursor were drawn successfully.
 * @retval FSP_ERR_NOT_OPEN UI_Relay_Init() has not been called.
 * @return Any other FSP error code returned by the ILI9341 driver.
 **********************************************************************************************************************/
fsp_err_t UI_Relay_Open(void)
{
    fsp_err_t err;

    if (!g_ui_relay_initialized)
    {
        return FSP_ERR_NOT_OPEN;
    }

    g_ui_relay_selected_channel = UI_RELAY_CHANNEL_1;
    g_ui_relay_active           = true;

    err = ui_relay_render_screen();

    if (FSP_SUCCESS != err)
    {
        g_ui_relay_active = false;
    }

    return err;
}

/*******************************************************************************************************************//**
 * @brief Processes one Relay-screen action.
 *
 * Action priority is HOME, BACK, SELECT, UP, DOWN, LEFT, then RIGHT. Direction movement stops at the grid edges.
 *
 * @param[in]  actions      Bit mask containing ui_relay_action_t values.
 * @param[out] p_navigation Navigation request returned to the application.
 *
 * @retval FSP_SUCCESS              The action was processed successfully.
 * @retval FSP_ERR_NOT_OPEN         The module is not initialized or the Relay screen is inactive.
 * @retval FSP_ERR_INVALID_ARGUMENT p_navigation is NULL.
 * @return Any other FSP error code returned by the display or relay-output callback.
 **********************************************************************************************************************/
fsp_err_t UI_Relay_Process(uint32_t actions, ui_relay_navigation_t * p_navigation)
{
    if (NULL == p_navigation)
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    *p_navigation = UI_RELAY_NAVIGATION_NONE;

    if ((!g_ui_relay_initialized) || (!g_ui_relay_active))
    {
        return FSP_ERR_NOT_OPEN;
    }

    if (0U != (actions & (uint32_t) UI_RELAY_ACTION_HOME))
    {
        g_ui_relay_active = false;
        *p_navigation = UI_RELAY_NAVIGATION_HOME;
        return FSP_SUCCESS;
    }

    if (0U != (actions & (uint32_t) UI_RELAY_ACTION_BACK))
    {
        g_ui_relay_active = false;
        *p_navigation = UI_RELAY_NAVIGATION_BACK;
        return FSP_SUCCESS;
    }

    if (0U != (actions & (uint32_t) UI_RELAY_ACTION_SELECT))
    {
        return ui_relay_toggle_selected();
    }

    if (0U != (actions & (uint32_t) UI_RELAY_ACTION_UP))
    {
        return ui_relay_move_focus((uint32_t) UI_RELAY_ACTION_UP);
    }

    if (0U != (actions & (uint32_t) UI_RELAY_ACTION_DOWN))
    {
        return ui_relay_move_focus((uint32_t) UI_RELAY_ACTION_DOWN);
    }

    if (0U != (actions & (uint32_t) UI_RELAY_ACTION_LEFT))
    {
        return ui_relay_move_focus((uint32_t) UI_RELAY_ACTION_LEFT);
    }

    if (0U != (actions & (uint32_t) UI_RELAY_ACTION_RIGHT))
    {
        return ui_relay_move_focus((uint32_t) UI_RELAY_ACTION_RIGHT);
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Updates one relay state and redraws it when the Relay screen is active.
 *
 * This API reflects an externally observed state and therefore does not call p_output_write.
 *
 * @param[in] channel Relay channel to update.
 * @param[in] enabled true for ON; false for OFF.
 *
 * @retval FSP_SUCCESS              The state was stored and, when active, redrawn successfully.
 * @retval FSP_ERR_NOT_OPEN         UI_Relay_Init() has not been called.
 * @retval FSP_ERR_INVALID_ARGUMENT channel is outside Relay 1 through Relay 8.
 * @return Any other FSP error code returned by the graphics driver.
 **********************************************************************************************************************/
fsp_err_t UI_Relay_Set_State(ui_relay_channel_t channel, bool enabled)
{
    uint8_t mask;

    if (!g_ui_relay_initialized)
    {
        return FSP_ERR_NOT_OPEN;
    }

    if ((uint32_t) channel >= (uint32_t) UI_RELAY_CHANNEL_MAX)
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    mask = (uint8_t) (1U << (uint32_t) channel);

    if (enabled)
    {
        g_ui_relay_state_mask = (uint8_t) (g_ui_relay_state_mask | mask);
    }
    else
    {
        g_ui_relay_state_mask = (uint8_t) (g_ui_relay_state_mask & (uint8_t) ~mask);
    }

    if (g_ui_relay_active)
    {
        return ui_relay_draw_state(channel);
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Marks the Relay screen inactive without changing relay states.
 *
 * @retval FSP_SUCCESS      The Relay screen was closed successfully.
 * @retval FSP_ERR_NOT_OPEN UI_Relay_Init() has not been called.
 **********************************************************************************************************************/
fsp_err_t UI_Relay_Close(void)
{
    if (!g_ui_relay_initialized)
    {
        return FSP_ERR_NOT_OPEN;
    }

    g_ui_relay_active = false;

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Returns the currently focused relay.
 *
 * @return Selected Relay channel.
 **********************************************************************************************************************/
ui_relay_channel_t UI_Relay_Get_Selected_Channel(void)
{
    return g_ui_relay_selected_channel;
}

/*******************************************************************************************************************//**
 * @brief Returns the eight-bit relay-state mask.
 *
 * @return Bit 0 through bit 7 represent Relay 1 through Relay 8; one means ON.
 **********************************************************************************************************************/
uint8_t UI_Relay_Get_State_Mask(void)
{
    return g_ui_relay_state_mask;
}

/*******************************************************************************************************************//**
 * @brief Returns one relay state.
 *
 * @param[in] channel Relay channel to query.
 *
 * @return true when the channel is valid and ON; otherwise false.
 **********************************************************************************************************************/
bool UI_Relay_Get_State(ui_relay_channel_t channel)
{
    if ((uint32_t) channel >= (uint32_t) UI_RELAY_CHANNEL_MAX)
    {
        return false;
    }

    return (0U != (g_ui_relay_state_mask & (uint8_t) (1U << (uint32_t) channel)));
}

/*******************************************************************************************************************//**
 * @brief Reports whether the Relay screen currently owns the display actions.
 *
 * @return true when active; otherwise false.
 **********************************************************************************************************************/
bool UI_Relay_Is_Active(void)
{
    return g_ui_relay_active;
}

/*******************************************************************************************************************//**
 * @} (end addtogroup UI_Relay)
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Draws the full Relay bitmap, current states, and selected cursor.
 *
 * @return FSP error code returned by the graphics driver.
 **********************************************************************************************************************/
static fsp_err_t ui_relay_render_screen(void)
{
    fsp_err_t err;

    err = ILI9341_Draw_Image((char const *) use_case_1_relay_control_320x240_rgb565, SCREEN_HORIZONTAL_1);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    err = ui_relay_draw_all_states();

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    return ui_relay_draw_cursor(g_ui_relay_selected_channel, UI_RELAY_CURSOR_COLOR);
}

/*******************************************************************************************************************//**
 * @brief Draws or erases the cursor around one relay tile.
 *
 * @param[in] channel Relay tile whose cursor is updated.
 * @param[in] color   RGB565 cursor or outer-background color.
 *
 * @return FSP error code returned by ILI9341_Draw_Hollow_Rectangle_Coord().
 **********************************************************************************************************************/
static fsp_err_t ui_relay_draw_cursor(ui_relay_channel_t channel, uint16_t color)
{
    ui_relay_position_t const * p_position = &g_ui_relay_positions[(uint32_t) channel];

    return ILI9341_Draw_Hollow_Rectangle_Coord(p_position->cursor_x0,
                                               p_position->cursor_y0,
                                               p_position->cursor_x1,
                                               p_position->cursor_y1,
                                               color);
}

/*******************************************************************************************************************//**
 * @brief Redraws all eight dynamic ON/OFF areas.
 *
 * @return FSP error code returned by the graphics driver.
 **********************************************************************************************************************/
static fsp_err_t ui_relay_draw_all_states(void)
{
    fsp_err_t err;
    uint32_t  index;

    for (index = 0U; index < UI_RELAY_CHANNEL_COUNT; index++)
    {
        err = ui_relay_draw_state((ui_relay_channel_t) index);

        if (FSP_SUCCESS != err)
        {
            return err;
        }
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Draws one relay ON/OFF label and switch using one buffered RGB565 block.
 *
 * @param[in] channel Relay channel to draw.
 *
 * @return FSP error code returned by ILI9341_Draw_RGB565_Block().
 **********************************************************************************************************************/
static fsp_err_t ui_relay_draw_state(ui_relay_channel_t channel)
{
    ui_relay_position_t const * p_position = &g_ui_relay_positions[(uint32_t) channel];
    bool const enabled = UI_Relay_Get_State(channel);

    ui_relay_prepare_state_buffer(enabled);

    return ILI9341_Draw_RGB565_Block(p_position->state_x,
                                     p_position->state_y,
                                     UI_RELAY_STATE_AREA_WIDTH,
                                     UI_RELAY_STATE_AREA_HEIGHT,
                                     g_ui_relay_state_buffer);
}

/*******************************************************************************************************************//**
 * @brief Moves focus by one tile inside the two-row by four-column grid.
 *
 * @param[in] action One directional UI_RELAY_ACTION_* value.
 *
 * @return FSP error code returned by the graphics driver.
 **********************************************************************************************************************/
static fsp_err_t ui_relay_move_focus(uint32_t action)
{
    fsp_err_t         err;
    uint32_t          old_index = (uint32_t) g_ui_relay_selected_channel;
    uint32_t          new_index = old_index;
    uint32_t          row       = old_index / UI_RELAY_COLUMN_COUNT;
    uint32_t          column    = old_index % UI_RELAY_COLUMN_COUNT;
    ui_relay_channel_t new_channel;

    if (((uint32_t) UI_RELAY_ACTION_UP == action) && (0U < row))
    {
        new_index -= UI_RELAY_COLUMN_COUNT;
    }
    else if (((uint32_t) UI_RELAY_ACTION_DOWN == action) && ((row + 1U) < UI_RELAY_ROW_COUNT))
    {
        new_index += UI_RELAY_COLUMN_COUNT;
    }
    else if (((uint32_t) UI_RELAY_ACTION_LEFT == action) && (0U < column))
    {
        new_index--;
    }
    else if (((uint32_t) UI_RELAY_ACTION_RIGHT == action) && ((column + 1U) < UI_RELAY_COLUMN_COUNT))
    {
        new_index++;
    }
    else
    {
        /* Keep the current selection at grid boundaries. */
    }

    if (new_index == old_index)
    {
        return FSP_SUCCESS;
    }

    new_channel = (ui_relay_channel_t) new_index;

    /* Draw the new focus before clearing the old focus to avoid a cursor-free frame. */
    err = ui_relay_draw_cursor(new_channel, UI_RELAY_CURSOR_COLOR);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    err = ui_relay_draw_cursor(g_ui_relay_selected_channel, UI_RELAY_OUTER_BACKGROUND_COLOR);

    if (FSP_SUCCESS != err)
    {
        (void) ui_relay_draw_cursor(new_channel, UI_RELAY_OUTER_BACKGROUND_COLOR);
        (void) ui_relay_draw_cursor(g_ui_relay_selected_channel, UI_RELAY_CURSOR_COLOR);
        return err;
    }

    g_ui_relay_selected_channel = new_channel;

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Toggles the selected relay and commits the state only after the hardware callback succeeds.
 *
 * @return FSP error code returned by the output callback or graphics driver.
 **********************************************************************************************************************/
static fsp_err_t ui_relay_toggle_selected(void)
{
    fsp_err_t err = FSP_SUCCESS;
    bool const enabled = !UI_Relay_Get_State(g_ui_relay_selected_channel);

    if (NULL != g_ui_relay_cfg.p_output_write)
    {
        err = g_ui_relay_cfg.p_output_write(g_ui_relay_selected_channel,
                                             enabled,
                                             g_ui_relay_cfg.p_context);

        if (FSP_SUCCESS != err)
        {
            return err;
        }
    }

    return UI_Relay_Set_State(g_ui_relay_selected_channel, enabled);
}

/*******************************************************************************************************************//**
 * @brief Builds one complete relay-state overlay in RAM before starting the SPI update.
 *
 * @param[in] enabled Relay state to render.
 **********************************************************************************************************************/
static void ui_relay_prepare_state_buffer(bool enabled)
{
    uint32_t index;
    uint32_t x;
    uint32_t y;
    uint16_t const state_color = enabled ? UI_RELAY_STATE_ON_COLOR : UI_RELAY_STATE_OFF_COLOR;

    for (index = 0U; index < (UI_RELAY_STATE_AREA_WIDTH * UI_RELAY_STATE_AREA_HEIGHT); index++)
    {
        g_ui_relay_state_buffer[index] = UI_RELAY_TILE_BACKGROUND_COLOR;
    }

    ui_relay_render_word(enabled, state_color);

    for (y = UI_RELAY_SWITCH_Y; y < (UI_RELAY_SWITCH_Y + UI_RELAY_SWITCH_HEIGHT); y++)
    {
        for (x = UI_RELAY_SWITCH_X; x < (UI_RELAY_SWITCH_X + UI_RELAY_SWITCH_WIDTH); x++)
        {
            g_ui_relay_state_buffer[(y * UI_RELAY_STATE_AREA_WIDTH) + x] = UI_RELAY_SWITCH_TRACK_COLOR;
        }
    }

    ui_relay_render_knob(enabled ? UI_RELAY_SWITCH_KNOB_ON_X : UI_RELAY_SWITCH_KNOB_OFF_X,
                         UI_RELAY_SWITCH_KNOB_Y,
                         state_color);
}

/*******************************************************************************************************************//**
 * @brief Renders ON or OFF into the state buffer.
 *
 * @param[in] enabled Relay state to render.
 * @param[in] color   RGB565 text color.
 **********************************************************************************************************************/
static void ui_relay_render_word(bool enabled, uint16_t color)
{
    uint16_t const scaled_width = UI_RELAY_STATE_GLYPH_WIDTH * UI_RELAY_STATE_GLYPH_SCALE;
    uint16_t x;

    if (enabled)
    {
        uint16_t const word_width = (uint16_t) (((uint32_t) scaled_width * 2U) +
                                                UI_RELAY_STATE_GLYPH_SPACING);
        x = (uint16_t) ((UI_RELAY_STATE_AREA_WIDTH - word_width) / 2U);
        ui_relay_render_glyph(g_ui_relay_glyph_o, x, UI_RELAY_STATE_TEXT_Y, color);
        x = (uint16_t) (x + scaled_width + UI_RELAY_STATE_GLYPH_SPACING);
        ui_relay_render_glyph(g_ui_relay_glyph_n, x, UI_RELAY_STATE_TEXT_Y, color);
    }
    else
    {
        uint16_t const word_width = (uint16_t) (((uint32_t) scaled_width * 3U) +
                                                (UI_RELAY_STATE_GLYPH_SPACING * 2U));
        x = (uint16_t) ((UI_RELAY_STATE_AREA_WIDTH - word_width) / 2U);
        ui_relay_render_glyph(g_ui_relay_glyph_o, x, UI_RELAY_STATE_TEXT_Y, color);
        x = (uint16_t) (x + scaled_width + UI_RELAY_STATE_GLYPH_SPACING);
        ui_relay_render_glyph(g_ui_relay_glyph_f, x, UI_RELAY_STATE_TEXT_Y, color);
        x = (uint16_t) (x + scaled_width + UI_RELAY_STATE_GLYPH_SPACING);
        ui_relay_render_glyph(g_ui_relay_glyph_f, x, UI_RELAY_STATE_TEXT_Y, color);
    }
}

/*******************************************************************************************************************//**
 * @brief Renders one scaled five-by-seven glyph into the relay-state buffer.
 *
 * @param[in] glyph Five-by-seven glyph rows.
 * @param[in] x     Left offset inside the buffer.
 * @param[in] y     Top offset inside the buffer.
 * @param[in] color RGB565 glyph color.
 **********************************************************************************************************************/
static void ui_relay_render_glyph(uint8_t const glyph[UI_RELAY_STATE_GLYPH_HEIGHT],
                                  uint16_t      x,
                                  uint16_t      y,
                                  uint16_t      color)
{
    uint32_t row;
    uint32_t column;
    uint32_t scale_x;
    uint32_t scale_y;

    for (row = 0U; row < UI_RELAY_STATE_GLYPH_HEIGHT; row++)
    {
        for (column = 0U; column < UI_RELAY_STATE_GLYPH_WIDTH; column++)
        {
            uint8_t const mask = (uint8_t) (1U << (4U - column));

            if (0U != (glyph[row] & mask))
            {
                for (scale_y = 0U; scale_y < UI_RELAY_STATE_GLYPH_SCALE; scale_y++)
                {
                    for (scale_x = 0U; scale_x < UI_RELAY_STATE_GLYPH_SCALE; scale_x++)
                    {
                        uint32_t const pixel_x = (uint32_t) x + (column * UI_RELAY_STATE_GLYPH_SCALE) + scale_x;
                        uint32_t const pixel_y = (uint32_t) y + (row * UI_RELAY_STATE_GLYPH_SCALE) + scale_y;

                        g_ui_relay_state_buffer[(pixel_y * UI_RELAY_STATE_AREA_WIDTH) + pixel_x] = color;
                    }
                }
            }
        }
    }
}

/*******************************************************************************************************************//**
 * @brief Renders the circular switch knob into the relay-state buffer.
 *
 * @param[in] center_x Horizontal knob center.
 * @param[in] center_y Vertical knob center.
 * @param[in] color    RGB565 knob color.
 **********************************************************************************************************************/
static void ui_relay_render_knob(int32_t center_x, int32_t center_y, uint16_t color)
{
    int32_t x;
    int32_t y;

    for (y = -UI_RELAY_SWITCH_KNOB_RADIUS; y <= UI_RELAY_SWITCH_KNOB_RADIUS; y++)
    {
        for (x = -UI_RELAY_SWITCH_KNOB_RADIUS; x <= UI_RELAY_SWITCH_KNOB_RADIUS; x++)
        {
            if (((x * x) + (y * y)) <= (UI_RELAY_SWITCH_KNOB_RADIUS * UI_RELAY_SWITCH_KNOB_RADIUS))
            {
                uint32_t const pixel_x = (uint32_t) (center_x + x);
                uint32_t const pixel_y = (uint32_t) (center_y + y);

                if ((pixel_x < UI_RELAY_STATE_AREA_WIDTH) && (pixel_y < UI_RELAY_STATE_AREA_HEIGHT))
                {
                    g_ui_relay_state_buffer[(pixel_y * UI_RELAY_STATE_AREA_WIDTH) + pixel_x] = color;
                }
            }
        }
    }
}