local M = {}

local header_pattern = "^@@%s+(.+):(%d+),(%d+)%s+@@%s*$"

local function trim_trailing_blank_lines(lines)
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines)
  end
end

local function add_body_lines(out, body)
  if body == nil or body == "" then
    return
  end

  local normalized = body:gsub("\r\n", "\n"):gsub("\r", "\n")
  for line in (normalized .. "\n"):gmatch("(.-)\n") do
    table.insert(out, line)
  end
end

function M.parse(text)
  local comments = {}
  local current = nil
  local body_lines = {}

  local function finish_current()
    if current == nil then
      return
    end

    trim_trailing_blank_lines(body_lines)
    current.body = table.concat(body_lines, "\n")
    current.range_len = current.end_line - current.start_line
    table.insert(comments, current)
    current = nil
    body_lines = {}
  end

  local normalized = (text or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
  for line in (normalized .. "\n"):gmatch("(.-)\n") do
    local path, start_line, end_line = line:match(header_pattern)

    if path then
      finish_current()

      start_line = tonumber(start_line)
      end_line = tonumber(end_line)

      if end_line < start_line then
        error(string.format("invalid range for %s: %d,%d", path, start_line, end_line))
      end

      current = {
        path = path,
        start_line = start_line,
        end_line = end_line,
        body = "",
      }
    elseif current then
      table.insert(body_lines, line)
    elseif line:match("%S") then
      error("unexpected content before first feedback header: " .. line)
    end
  end

  finish_current()
  return comments
end

function M.serialize(comments)
  local lines = {}

  for index, comment in ipairs(comments or {}) do
    table.insert(
      lines,
      string.format("@@ %s:%d,%d @@", comment.path, comment.start_line, comment.end_line)
    )
    add_body_lines(lines, comment.body)

    if index < #comments then
      table.insert(lines, "")
    end
  end

  if #lines == 0 then
    return ""
  end

  return table.concat(lines, "\n") .. "\n"
end

return M
