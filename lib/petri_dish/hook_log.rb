# frozen_string_literal: true

require "json"
require "time"

module PetriDish
  ToolEvent = Data.define(
    :session_id,
    :tool_use_id,
    :tool_name,
    :tool_input,     # raw tool_input hash from the hook payload
    :input_summary,  # one-line string summary of tool_input, per tool_name
    :prompted,
    :permission_suggestions,
    :outcome,        # :success, :denied
    :response,       # hash with stdout/stderr from PostToolUse, or nil
    :pre_ts,         # Time
    :post_ts,        # Time or nil
    :permission_ts   # Time or nil
  )

  class HookLog
    SUMMARY_TRUNCATE = 40

    def initialize(path)
      @path = path
      @raw_events = parse_events
    end

    def tool_events
      pair_events
    end

    private

    def parse_events
      return [] unless File.exist?(@path)

      File.readlines(@path).filter_map do |line|
        line = line.strip
        next if line.empty?
        JSON.parse(line)
      end
    end

    def pair_events
      pre_events = {}
      post_events = {}
      permission_events = []

      @raw_events.each do |event|
        payload = event["payload"]
        hook_name = payload["hook_event_name"]

        case hook_name
        when "PreToolUse"
          pre_events[payload["tool_use_id"]] = event
        when "PostToolUse"
          post_events[payload["tool_use_id"]] = event
        when "PermissionRequest"
          permission_events << event
        end
      end

      # Build ToolEvents from Pre events, correlating Post and PermissionRequest
      pre_events.map do |tool_use_id, pre_event|
        post_event = post_events[tool_use_id]
        permission = find_permission(pre_event, post_event, permission_events)

        build_tool_event(pre_event, post_event, permission)
      end
    end

    # Match a PermissionRequest to a Pre/Post pair.
    #
    # A PermissionRequest belongs to a pair when:
    # 1. Its timestamp falls between pre_ts and post_ts (or after pre_ts if no Post)
    # 2. Its tool_name matches
    # 3. Its tool_input matches
    def find_permission(pre_event, post_event, permission_events)
      pre_ts = Time.parse(pre_event["ts"])
      post_ts = post_event ? Time.parse(post_event["ts"]) : nil
      pre_payload = pre_event["payload"]

      permission_events.find do |perm|
        perm_ts = Time.parse(perm["ts"])
        perm_payload = perm["payload"]

        # Timestamp must be after pre
        next false unless perm_ts > pre_ts
        # If there's a post, timestamp must be before it
        next false if post_ts && perm_ts > post_ts

        # tool_name and tool_input must match
        perm_payload["tool_name"] == pre_payload["tool_name"] &&
          perm_payload["tool_input"] == pre_payload["tool_input"]
      end
    end

    def build_tool_event(pre_event, post_event, permission_event)
      pre_payload = pre_event["payload"]
      tool_input = pre_payload["tool_input"]

      prompted = !permission_event.nil?
      has_post = !post_event.nil?
      outcome = has_post ? :success : :denied

      response = if post_event
        post_event.dig("payload", "tool_response")
      end

      permission_suggestions = if permission_event
        permission_event.dig("payload", "permission_suggestions")
      end

      permission_ts = if permission_event
        Time.parse(permission_event["ts"])
      end

      ToolEvent.new(
        session_id: pre_payload["session_id"],
        tool_use_id: pre_payload["tool_use_id"],
        tool_name: pre_payload["tool_name"],
        tool_input: tool_input,
        input_summary: summarize(pre_payload["tool_name"], tool_input),
        prompted: prompted,
        permission_suggestions: permission_suggestions,
        outcome: outcome,
        response: response,
        pre_ts: Time.parse(pre_event["ts"]),
        post_ts: post_event ? Time.parse(post_event["ts"]) : nil,
        permission_ts: permission_ts
      )
    end

    # One-line description of tool_input, per tool. Used for the results.md
    # "Summary" column and for any caller that wants a human-readable label.
    # LSP is included because Claude Code exposes an LSP tool (operations:
    # definition, hover, references, etc.) and probe runs need it.
    def summarize(tool_name, tool_input)
      return "" if tool_input.nil?

      case tool_name
      when "Bash"
        tool_input["command"].to_s
      when "Write"
        bytes = tool_input["content"]&.length
        "#{tool_input['file_path']}#{" (#{bytes} bytes)" if bytes}"
      when "Read"
        path = tool_input["file_path"]
        offset = tool_input["offset"]
        limit = tool_input["limit"]
        suffix =
          if offset && limit then ":#{offset}+#{limit}"
          elsif offset then ":#{offset}"
          end
        "#{path}#{suffix}"
      when "Edit"
        old_s = truncate(tool_input["old_string"].to_s)
        new_s = truncate(tool_input["new_string"].to_s)
        "#{tool_input['file_path']}: #{old_s} -> #{new_s}"
      when "LSP"
        target = tool_input["symbol"] || tool_input["uri"] || tool_input["query"]
        "#{tool_input['operation']}#{" #{target}" if target}".strip
      else
        tool_input.to_json[0, 80]
      end
    end

    def truncate(str)
      str.length > SUMMARY_TRUNCATE ? "#{str[0, SUMMARY_TRUNCATE]}..." : str
    end
  end
end
