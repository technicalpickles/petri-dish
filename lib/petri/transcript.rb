# frozen_string_literal: true

module Petri
  class Transcript
    ANSI_REGEX = /\e\[[0-9;]*[a-zA-Z]/

    def initialize(tmux_session)
      @tmux_session = tmux_session
    end

    def capture_pane(visible_only: false)
      flag = visible_only ? "" : "-S -"
      raw = `tmux capture-pane -t #{@tmux_session} -p #{flag} 2>/dev/null`
      strip_ansi(raw)
    end

    def capture_visible
      capture_pane(visible_only: true)
    end

    def save!(output_path)
      content = capture_pane
      File.write(output_path, content)
      log "Transcript saved to #{output_path}"
    end

    private

    def strip_ansi(text)
      text.gsub(ANSI_REGEX, "")
    end

    def log(msg)
      puts "\e[32m[transcript]\e[0m #{msg}"
    end
  end
end
