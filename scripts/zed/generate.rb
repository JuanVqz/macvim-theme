#!/usr/bin/env ruby
# Generates zed/themes/macvim.json from the colors in static/macvim.vim.
# Run: ruby scripts/zed/generate.rb
# Hex values were resolved by nvim itself (`nvim_get_hl` after sourcing the file).
require "json"

# Groups shared by both backgrounds.
COMMON = {
  diff_add: "#3cb371",      # DiffAdd       MediumSeaGreen
  directory: "#1600ff",     # Directory
  error_msg: "#ee2c2c",     # ErrorMsg      Firebrick2
  error: "#cd2626",         # Error         Firebrick3
  more_msg: "#2e8b57",      # MoreMsg       SeaGreen4
  question: "#458b00",      # Question      Chartreuse4
  pmenu: "#cae1ff",         # Pmenu         LightSteelBlue1
  pmenu_sel: "#4a708b",     # PmenuSel      SkyBlue4
  status_line: "#2f4f4f",   # StatusLine    DarkSlateGray
  status_nc_fg: "#708090",  # StatusLineNC  SlateGray
  status_nc_bg: "#e5e5e5",  # StatusLineNC  Gray90
  tab_line: "#d3d3d3",      # TabLine       LightGrey
  title: "#009acd",         # Title         DeepSkyBlue3
  visual: "#72f7ff",        # Visual
  diff_delete: "#6a5acd",   # DiffDelete    SlateBlue
  identifier: "#458b74",    # Identifier    Aquamarine4
  preproc: "#1874cd",       # PreProc       DodgerBlue3
  special: "#8a2be2",       # Special       BlueViolet
  string: "#4a708b",        # String        SkyBlue4
  underlined: "#63b8ff",    # Underlined    SteelBlue1
  folded: "#e6e6e6",        # Folded
  grey: "#bebebe"           # FoldColumn    Grey
}.freeze

# The original dark variant is hard to read (Grey50 text, SkyBlue4 strings,
# DeepPink4 booleans on Grey10). This keeps the MacVim hue families but uses
# brighter X11 shades of the same colors.
DARK = COMMON.merge(
  normal_fg: "#cccccc",     # Grey80        (orig Grey50)
  normal_bg: "#1a1a1a",     # Normal        Grey10
  gutter_bg: "#0d0d0d",     # LineNr bg     Grey5
  line_nr: "#5d478b",       # MediumPurple4 (orig #552A7B)
  boolean: "#ee6aa7",       # HotPink2      (orig DeepPink4)
  comment: "#7ac5cd",       # Comment       CadetBlue3
  constant: "#ffc125",      # Constant      Goldenrod1
  cursor: "#eedd82",        # Cursor        LightGoldenrod
  cursor_line: "#2b2b2b",   # Gray17        (orig Gray20)
  diff_change: "#5d478b",   # DiffChange    MediumPurple4
  diff_text: "#4682b4",     # DiffText      SteelBlue
  match_paren: "#8b008b",   # Magenta4      (orig Magenta)
  search: "#00008b",        # Search        Blue4
  statement: "#ab82ff",     # MediumPurple1 (orig Purple1)
  type: "#b4eeb4",          # DarkSeaGreen2 (orig Cyan4)
  identifier: "#66cdaa",    # Aquamarine3   (orig Aquamarine4)
  preproc: "#1e90ff",       # DodgerBlue1   (orig DodgerBlue3)
  special: "#e066ff",       # MediumOrchid1 (orig BlueViolet)
  string: "#7ec0ee",        # SkyBlue2      (orig SkyBlue4)
  title: "#00bfff",         # DeepSkyBlue1  (orig DeepSkyBlue3)
  visual: "#104e8b",        # DodgerBlue4   (orig #72F7FF)
  pmenu_sel: "#104e8b"      # DodgerBlue4
)

LIGHT = COMMON.merge(
  normal_fg: "#000000",     # Normal        Black
  normal_bg: "#ffffff",     # Normal        White
  gutter_bg: "#e6e6e6",     # LineNr bg
  line_nr: "#888888",       # LineNr
  boolean: "#cd0000",       # Boolean       Red3
  comment: "#0000ee",       # Comment       Blue2
  constant: "#ff8c00",      # Constant      DarkOrange
  cursor: "#000000",        # Cursor        fg
  cursor_line: "#f1f5fa",   # CursorLine
  diff_change: "#00bfff",   # DiffChange    DeepSkyBlue
  diff_text: "#ffd700",     # DiffText      Gold
  match_paren: "#ab82ff",   # MatchParen    MediumPurple1
  search: "#98f5ff",        # Search        CadetBlue1
  statement: "#800000",     # Statement     Maroon (nvim resolves it to #800000)
  type: "#008b00"           # Type          Green4
)

def hl(color, style: nil, weight: nil)
  h = { "color" => color }
  h["font_style"] = style if style
  h["font_weight"] = weight if weight
  h
end

def alpha(color, aa) = "#{color}#{aa}"

def syntax(c)
  statement = hl(c[:statement], weight: 700)
  type = hl(c[:type], weight: 700)
  special = hl(c[:special])
  plain = hl(c[:normal_fg])

  {
    "attribute" => hl(c[:preproc]),
    "boolean" => hl(c[:boolean]),
    "comment" => hl(c[:comment], style: "italic"),
    "comment.doc" => hl(c[:comment], style: "italic"),
    "constant" => hl(c[:constant]),
    "constructor" => special,
    "embedded" => plain,
    "emphasis" => hl(c[:normal_fg], style: "italic"),
    "emphasis.strong" => hl(c[:normal_fg], weight: 700),
    "enum" => type,
    "function" => hl(c[:identifier]),
    "hint" => hl(c[:status_nc_fg], style: "italic"),
    "keyword" => statement,
    "label" => statement,
    "link_text" => hl(c[:underlined], style: "italic"),
    "link_uri" => hl(c[:underlined]),
    "namespace" => type,
    "number" => hl(c[:constant]),
    "operator" => plain,
    "predictive" => hl(c[:status_nc_fg], style: "italic"),
    "preproc" => hl(c[:preproc]),
    "primary" => plain,
    "property" => hl(c[:identifier]),
    "punctuation" => plain,
    "punctuation.bracket" => plain,
    "punctuation.delimiter" => plain,
    "punctuation.list_marker" => statement,
    "punctuation.markup" => plain,
    "punctuation.special" => special,
    "selector" => statement,
    "selector.pseudo" => hl(c[:preproc]),
    "string" => hl(c[:string]),
    "string.escape" => special,
    "string.regex" => special,
    "string.special" => special,
    "string.special.symbol" => special,
    "tag" => statement,
    "text.literal" => hl(c[:string]),
    "title" => hl(c[:title], weight: 700),
    "type" => type,
    "variable" => plain,
    "variable.special" => special,
    "variant" => hl(c[:constant])
  }
end

def terminal(c, dark)
  {
    "terminal.background" => c[:normal_bg],
    "terminal.foreground" => c[:normal_fg],
    "terminal.bright_foreground" => dark ? "#e5e5e5" : "#000000",
    "terminal.dim_foreground" => dark ? "#555555" : "#7f7f7f",
    "terminal.ansi.black" => dark ? "#1a1a1a" : "#000000",
    "terminal.ansi.red" => c[:error],
    "terminal.ansi.green" => "#008b00",
    "terminal.ansi.yellow" => c[:constant],
    "terminal.ansi.blue" => c[:preproc],
    "terminal.ansi.magenta" => c[:special],
    "terminal.ansi.cyan" => "#008b8b",
    "terminal.ansi.white" => "#bebebe",
    "terminal.ansi.bright_black" => "#7f7f7f",
    "terminal.ansi.bright_red" => c[:error_msg],
    "terminal.ansi.bright_green" => c[:diff_add],
    "terminal.ansi.bright_yellow" => dark ? "#eedd82" : "#ffc125",
    "terminal.ansi.bright_blue" => c[:underlined],
    "terminal.ansi.bright_magenta" => "#9b30ff",
    "terminal.ansi.bright_cyan" => "#7ac5cd",
    "terminal.ansi.bright_white" => "#ffffff"
  }
end

def style(c, dark:)
  chrome = c[:gutter_bg]
  border = dark ? c[:status_line] : c[:grey]
  surface = dark ? "#262626" : c[:pmenu]
  selected = dark ? c[:pmenu_sel] : "#a4c8f0"
  hover = dark ? c[:cursor_line] : "#dde8f5"
  muted = c[:status_nc_fg]

  {
    "background" => chrome,
    "background.appearance" => "opaque",
    "border" => border,
    "border.variant" => dark ? c[:cursor_line] : c[:tab_line],
    "border.focused" => c[:preproc],
    "border.selected" => c[:preproc],
    "border.transparent" => "#00000000",
    "border.disabled" => dark ? c[:cursor_line] : c[:tab_line],
    "surface.background" => chrome,
    "elevated_surface.background" => surface,
    "panel.background" => chrome,
    "panel.focused_border" => c[:preproc],
    "pane.focused_border" => c[:preproc],
    "pane_group.border" => border,
    "drop_target.background" => alpha(c[:preproc], "40"),

    "element.background" => dark ? c[:cursor_line] : c[:tab_line],
    "element.hover" => hover,
    "element.active" => selected,
    "element.selected" => selected,
    "element.disabled" => dark ? c[:cursor_line] : c[:tab_line],
    "ghost_element.background" => "#00000000",
    "ghost_element.hover" => hover,
    "ghost_element.active" => selected,
    "ghost_element.selected" => selected,
    "ghost_element.disabled" => "#00000000",

    "text" => c[:normal_fg],
    "text.muted" => muted,
    "text.placeholder" => muted,
    "text.disabled" => dark ? "#555555" : c[:grey],
    "text.accent" => c[:preproc],
    "icon" => c[:normal_fg],
    "icon.muted" => muted,
    "icon.disabled" => dark ? "#555555" : c[:grey],
    "icon.placeholder" => muted,
    "icon.accent" => c[:preproc],
    "link_text.hover" => c[:underlined],

    "status_bar.background" => dark ? chrome : c[:status_nc_bg],
    "title_bar.background" => chrome,
    "title_bar.inactive_background" => chrome,
    "toolbar.background" => c[:normal_bg],
    "tab_bar.background" => dark ? chrome : c[:tab_line],
    "tab.inactive_background" => dark ? chrome : c[:tab_line],
    "tab.active_background" => c[:normal_bg],

    "scrollbar.thumb.background" => alpha(c[:normal_fg], "40"),
    "scrollbar.thumb.hover_background" => alpha(c[:normal_fg], "80"),
    "scrollbar.thumb.border" => "#00000000",
    "scrollbar.track.background" => "#00000000",
    "scrollbar.track.border" => "#00000000",

    "editor.background" => c[:normal_bg],
    "editor.foreground" => c[:normal_fg],
    "editor.gutter.background" => c[:gutter_bg],
    "editor.subheader.background" => chrome,
    "editor.active_line.background" => c[:cursor_line],
    "editor.highlighted_line.background" => c[:cursor_line],
    "editor.line_number" => c[:line_nr],
    "editor.active_line_number" => c[:normal_fg],
    "editor.hover_line_number" => c[:normal_fg],
    "editor.invisible" => alpha(c[:normal_fg], "55"),
    "editor.wrap_guide" => alpha(c[:normal_fg], "20"),
    "editor.active_wrap_guide" => alpha(c[:normal_fg], "40"),
    "editor.indent_guide" => alpha(c[:normal_fg], "20"),
    "editor.indent_guide_active" => alpha(c[:normal_fg], "50"),
    "editor.document_highlight.read_background" => alpha(c[:visual], "30"),
    "editor.document_highlight.write_background" => alpha(c[:visual], "50"),
    "editor.document_highlight.bracket_background" => c[:match_paren],

    "search.match_background" => c[:search],
    "search.active_match_background" => dark ? c[:preproc] : c[:diff_change],

    "created" => c[:diff_add],
    "created.background" => alpha(c[:diff_add], "30"),
    "created.border" => c[:diff_add],
    "modified" => c[:diff_change],
    "modified.background" => alpha(c[:diff_change], "30"),
    "modified.border" => c[:diff_change],
    "deleted" => c[:error_msg],
    "deleted.background" => alpha(c[:error_msg], "30"),
    "deleted.border" => c[:error_msg],
    "renamed" => c[:diff_text],
    "renamed.background" => alpha(c[:diff_text], "30"),
    "renamed.border" => c[:diff_text],
    "conflict" => c[:constant],
    "conflict.background" => alpha(c[:constant], "30"),
    "conflict.border" => c[:constant],
    "ignored" => muted,
    "ignored.background" => "#00000000",
    "ignored.border" => border,
    "hidden" => muted,
    "hidden.background" => "#00000000",
    "hidden.border" => border,
    "unreachable" => muted,
    "unreachable.background" => "#00000000",
    "unreachable.border" => border,
    "version_control.added" => c[:diff_add],
    "version_control.modified" => c[:diff_change],
    "version_control.deleted" => c[:error_msg],

    "error" => c[:error_msg],
    "error.background" => alpha(c[:error_msg], "20"),
    "error.border" => c[:error_msg],
    "warning" => c[:constant],
    "warning.background" => alpha(c[:constant], "20"),
    "warning.border" => c[:constant],
    "info" => c[:preproc],
    "info.background" => alpha(c[:preproc], "20"),
    "info.border" => c[:preproc],
    "hint" => muted,
    "hint.background" => alpha(muted, "20"),
    "hint.border" => muted,
    "success" => c[:more_msg],
    "success.background" => alpha(c[:more_msg], "20"),
    "success.border" => c[:more_msg],
    "predictive" => muted,
    "predictive.background" => alpha(muted, "20"),
    "predictive.border" => muted,

    "players" => [
      { "cursor" => c[:cursor], "background" => c[:cursor], "selection" => c[:visual] },
      { "cursor" => c[:special], "background" => c[:special], "selection" => alpha(c[:special], "40") },
      { "cursor" => c[:identifier], "background" => c[:identifier], "selection" => alpha(c[:identifier], "40") },
      { "cursor" => c[:constant], "background" => c[:constant], "selection" => alpha(c[:constant], "40") }
    ],
    "syntax" => syntax(c)
  }.merge(terminal(c, dark))
end

theme = {
  "$schema" => "https://zed.dev/schema/themes/v0.2.0.json",
  "name" => "MacVim",
  "author" => "Juan Vásquez (port of the MacVim colorscheme by Bjorn Winckler)",
  "themes" => [
    { "name" => "MacVim Dark", "appearance" => "dark", "style" => style(DARK, dark: true) },
    { "name" => "MacVim Light", "appearance" => "light", "style" => style(LIGHT, dark: false) }
  ]
}

File.write(File.expand_path("../../zed/themes/macvim.json", __dir__), JSON.pretty_generate(theme) + "\n")
