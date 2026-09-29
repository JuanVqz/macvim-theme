#!/usr/bin/env ruby
# Renders static/zed.png: a Zed-style editor mockup of samples/preview.rb in
# MacVim Light and MacVim Dark, using the colors in zed/themes/macvim.json.
# Tokens come from Ripper and are mapped to the captures Zed's Ruby grammar
# uses, so highlighting is close to, but not exactly, what Zed shows.
# Run: ruby zed/preview.rb  (needs Google Chrome)
require "cgi"
require "json"
require "ripper"
require "tmpdir"

ROOT = File.expand_path("..", __dir__)
THEME = JSON.parse(File.read(File.join(ROOT, "zed", "themes", "macvim.json")))
SAMPLE = File.join(ROOT, "samples", "preview.rb")
OUTPUT = File.join(ROOT, "static", "zed.png")
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
ACTIVE_LINE = 21

BOOLEANS = %w[true false].freeze
SPECIAL_VARS = %w[self].freeze
CONSTANT_KWS = %w[nil].freeze
VISIBILITY = %w[private protected public].freeze
PUNCTUATION = %i[on_lparen on_rparen on_lbracket on_rbracket on_lbrace on_rbrace on_comma on_period].freeze

# Returns [[capture, text], ...] per line.
def highlight(source)
  tokens = Ripper.lex(source).map { |(_pos, type, text, _state)| [type, text] }
  significant = tokens.each_index.reject { |i| %i[on_sp on_nl on_ignored_nl].include?(tokens[i][0]) }
  prev_of = {}
  next_of = {}
  significant.each_cons(2) do |a, b|
    next_of[a] = b
    prev_of[b] = a
  end
  line_start = true
  in_symbol = false

  captures = tokens.each_with_index.map do |(type, text), i|
    prev = prev_of[i] && tokens[prev_of[i]]
    nxt = next_of[i] && tokens[next_of[i]]
    capture =
      case type
      when :on_comment then "comment"
      when :on_kw
        if BOOLEANS.include?(text) then "boolean"
        elsif SPECIAL_VARS.include?(text) then "variable.special"
        elsif CONSTANT_KWS.include?(text) then "constant"
        else "keyword"
        end
      when :on_const then "type"
      when :on_ivar, :on_cvar, :on_gvar then "property"
      when :on_label, :on_symbeg then "string.special.symbol"
      when :on_tstring_beg, :on_tstring_content, :on_tstring_end then "string"
      when :on_regexp_beg, :on_regexp_end then "string.regex"
      when :on_embexpr_beg, :on_embexpr_end then "punctuation.special"
      when :on_int, :on_float then "number"
      when :on_op, :on_tlambda then "operator"
      when *PUNCTUATION then "punctuation"
      when :on_ident
        if in_symbol then "string.special.symbol"
        elsif line_start && VISIBILITY.include?(text) then "keyword"
        elsif prev && (prev == [:on_kw, "def"] || prev[0] == :on_period) then "function"
        elsif nxt && nxt[0] == :on_lparen then "function"
        elsif line_start && tokens[i + 1]&.first == :on_sp && nxt && !%i[on_op on_period].include?(nxt[0]) then "function"
        else "variable"
        end
      end
    # Inside a regexp every content token belongs to the regex.
    capture = "string.regex" if type == :on_tstring_content && prev&.first == :on_regexp_beg

    in_symbol = type == :on_symbeg
    line_start = %i[on_nl on_ignored_nl].include?(type) || (type == :on_comment && text.end_with?("\n")) ||
      (line_start && type == :on_sp)
    [capture, text]
  end

  lines = [[]]
  captures.each do |capture, text|
    text.split(/(\n)/).each do |part|
      if part == "\n"
        lines << []
      elsif !part.empty?
        lines.last << [capture, part]
      end
    end
  end
  lines.pop if lines.last.empty?
  lines
end

def css_for(syntax, capture)
  style = syntax[capture] || syntax[capture.to_s.split(".").first] || {}
  css = []
  css << "color:#{style["color"]}" if style["color"]
  css << "font-style:#{style["font_style"]}" if style["font_style"]
  css << "font-weight:#{style["font_weight"]}" if style["font_weight"]
  css.join(";")
end

def pane(theme, lines)
  s = theme["style"]
  syntax = s["syntax"]
  code = lines.each_with_index.map do |parts, i|
    number = i + 1
    spans = parts.map do |capture, text|
      next CGI.escapeHTML(text) unless capture

      %(<span style="#{css_for(syntax, capture)}">#{CGI.escapeHTML(text)}</span>)
    end.join
    cursor = number == ACTIVE_LINE ? %(<span class="cursor" style="background:#{s["players"][0]["cursor"]}"></span>) : ""
    active = number == ACTIVE_LINE
    <<~HTML
      <div class="row" style="#{active ? "background:#{s["editor.active_line.background"]}" : ""}">
        <span class="gutter" style="background:#{s["editor.gutter.background"]};color:#{active ? s["editor.active_line_number"] : s["editor.line_number"]}">#{number}</span>
        <span class="code">#{cursor}#{spans}</span>
      </div>
    HTML
  end.join

  <<~HTML
    <div class="window" style="background:#{s["background"]};border-color:#{s["border"]};color:#{s["text"]}">
      <div class="titlebar" style="background:#{s["title_bar.background"]};border-color:#{s["border.variant"]}">
        <span class="lights"><i style="background:#ff5f57"></i><i style="background:#febc2e"></i><i style="background:#28c840"></i></span>
        <span class="title" style="color:#{s["text.muted"]}">macvim-theme</span>
        <span class="theme-name" style="color:#{s["text.muted"]}">#{theme["name"]}</span>
      </div>
      <div class="tabbar" style="background:#{s["tab_bar.background"]};border-color:#{s["border.variant"]}">
        <span class="tab active" style="background:#{s["tab.active_background"]};color:#{s["text"]};border-color:#{s["border.variant"]}">preview.rb</span>
        <span class="tab" style="background:#{s["tab.inactive_background"]};color:#{s["text.muted"]};border-color:#{s["border.variant"]}">user.rb</span>
      </div>
      <div class="editor" style="background:#{s["editor.background"]};color:#{s["editor.foreground"]}">#{code}</div>
      <div class="statusbar" style="background:#{s["status_bar.background"]};border-color:#{s["border.variant"]};color:#{s["text.muted"]}">
        <span>NORMAL</span><span>samples/preview.rb</span><span class="right">Ruby</span>
      </div>
    </div>
  HTML
end

lines = highlight(File.read(SAMPLE))
panes = THEME["themes"].sort_by { |t| t["appearance"] == "light" ? 0 : 1 }.map { |t| pane(t, lines) }

html = <<~HTML
  <!doctype html>
  <html><head><meta charset="utf-8"><style>
    * { box-sizing: border-box; margin: 0; }
    body { background: transparent; padding: 24px; display: flex; gap: 24px; font-family: -apple-system, "Helvetica Neue", sans-serif; }
    .window { width: 760px; border: 1px solid; border-radius: 10px; overflow: hidden; box-shadow: 0 12px 32px rgba(0,0,0,.28); font-size: 12px; }
    .titlebar { height: 34px; display: flex; align-items: center; padding: 0 12px; border-bottom: 1px solid; }
    .lights { display: flex; gap: 8px; width: 120px; }
    .lights i { width: 12px; height: 12px; border-radius: 50%; display: block; }
    .title { flex: 1; text-align: center; }
    .theme-name { width: 120px; text-align: right; }
    .tabbar { height: 32px; display: flex; border-bottom: 1px solid; }
    .tab { padding: 0 16px; display: flex; align-items: center; border-right: 1px solid; }
    .tab.active { margin-bottom: -1px; }
    .editor { padding: 6px 0; font-family: Menlo, "SF Mono", monospace; font-size: 13px; line-height: 20px; }
    .row { display: flex; white-space: pre; }
    .gutter { width: 44px; padding-right: 12px; text-align: right; flex-shrink: 0; }
    .code { padding-left: 12px; position: relative; }
    .cursor { display: inline-block; width: 2px; height: 18px; vertical-align: -4px; margin-right: -2px; }
    .statusbar { height: 26px; display: flex; gap: 16px; align-items: center; padding: 0 12px; border-top: 1px solid; }
    .statusbar .right { margin-left: auto; }
  </style></head><body>#{panes.join}</body></html>
HTML

abort "Google Chrome not found at #{CHROME}" unless File.exist?(CHROME)

Dir.mktmpdir do |dir|
  page = File.join(dir, "preview.html")
  File.write(page, html)
  width = 24 + (760 + 24) * panes.size
  height = 24 * 2 + 34 + 32 + 12 + lines.size * 20 + 26 + 2
  File.delete(OUTPUT) if File.exist?(OUTPUT)
  # Headless Chrome writes the screenshot but does not always exit, so wait
  # for the file to settle and stop Chrome ourselves.
  pid = spawn(CHROME, "--headless", "--user-data-dir=#{dir}/profile", "--no-first-run", "--disable-gpu",
    "--hide-scrollbars", "--force-device-scale-factor=2", "--default-background-color=00000000",
    "--window-size=#{width},#{height}", "--screenshot=#{OUTPUT}", "file://#{page}", out: File::NULL, err: File::NULL)
  deadline = Time.now + 60
  exited = false
  until exited || Time.now > deadline
    exited = !Process.wait(pid, Process::WNOHANG).nil?
    break if File.size?(OUTPUT)

    sleep 0.5
  end
  sleep 1 unless exited
  unless exited
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
  abort("Chrome did not write #{OUTPUT}") unless File.size?(OUTPUT)
end

puts "Wrote #{OUTPUT}"
