-- Pull in the wezterm API
local wezterm = require 'wezterm'
local mux = wezterm.mux
local act = wezterm.action

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

local function is_neovim(p)
  return p:get_user_vars().IS_NVIM == 'true'
end

local direction_keys = {
  Left           = 'LeftArrow',
  Down           = 'DownArrow',
  Up             = 'UpArrow',
  Right          = 'RightArrow',
  -- reverse lookup
  ['LeftArrow']  = 'Left',
  ['DownArrow']  = 'Down',
  ['UpArrow']    = 'Up',
  ['RightArrow'] = 'Right',
}

local function neovim_keybinding_handler(neovim_keybinding_callback_function, wezterm_keybinding_callback_function)
  return wezterm.action_callback(function(window, pane)
    if is_neovim(pane) then
      neovim_keybinding_callback_function(window, pane)
    else
      if wezterm_keybinding_callback_function ~= nil then
        wezterm_keybinding_callback_function(window, pane)
      end
    end
  end)
end

-- Key only affects Neovim
local function bind_neovim_key(key, mods, action)
  return {
    key = key,
    mods = mods,
    action = neovim_keybinding_handler(
      function(window, pane)
        window:perform_action(action, pane)
      end
    ),
  }
end

local function split_nav(action, key)
  local mods = action == 'resize' and 'CTRL' or 'ALT'
  return {
    key = key,
    mods = mods,
    action = neovim_keybinding_handler(
      function(window, pane)
        -- pass the keys through to vim/nvim
        window:perform_action({ SendKey = { key = key, mods = mods } }, pane)
      end,
      function(window, pane)
        if action == 'resize' then
          window:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
        else
          window:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
        end
      end
    ),
  }
end

local wezterm_config_dir = os.getenv('WEZTERM_CONFIG_DIR')
local wezterm_config_file = os.getenv('WEZTERM_CONFIG_FILE')

wezterm.on("gui-startup", function(cmd)
  local _, _, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

config.window_background_opacity = 0.8
config.color_scheme = '3024 Night'
config.font = wezterm.font 'JetBrainsMono NF'
-- config.use_fancy_tab_bar = false
-- config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true

config.keys = {
  {
    key = '\\',
    mods = 'CMD',
    action = act.SplitPane {
      direction = 'Down',
      size = { Percent = 50 },
    },
  },
  {
    key = '|',
    mods = 'CMD|SHIFT',
    action = act.SplitPane {
      direction = 'Right',
      size = { Percent = 50 },
    },
  },
  {
    key = 't',
    mods = 'CMD|SHIFT',
    action = act.ShowTabNavigator,
  },
  {
    key = ',',
    mods = "CMD",
    action = act.SpawnCommandInNewTab {
      set_environment_variables = {
        TERM = 'screen-256color',
        -- NVIM_APPNAME = 'nvim_ansidev',
      },
      args = {
        '/usr/local/bin/nvim',
        wezterm_config_file,
      },
    },
  },
  {
    key = 'R',
    mods = 'CMD|SHIFT',
    action = act.PromptInputLine {
      description = 'Enter new name for tab',
      action = wezterm.action_callback(function(window, _, line)
        -- line will be `nil` if they hit escape without entering anything
        -- An empty string if they just hit enter
        -- Or the actual line of text they wrote
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
  },
  -- move between split panes
  split_nav('move', 'LeftArrow'),
  split_nav('move', 'DownArrow'),
  split_nav('move', 'UpArrow'),
  split_nav('move', 'RightArrow'),
  -- resize panes
  split_nav('resize', 'LeftArrow'),
  split_nav('resize', 'DownArrow'),
  split_nav('resize', 'UpArrow'),
  split_nav('resize', 'RightArrow'),
  -- Type <escape>:w<enter> to save neovim
  -- bind_neovim_key('s', 'CMD', act.SendString '\x1b\x1b\x3a\x77\x0a'),
  -- Type <escape>:S<enter> to save neovim
  bind_neovim_key('s', 'CTRL', act.SendString '\x1b\x1b\x3a\x53\x0a'),
}

return config
