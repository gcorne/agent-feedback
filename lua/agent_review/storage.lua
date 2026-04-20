local config = require("agent_review.config")
local format = require("agent_review.format")

local M = {}

M.comments = {}

local function normalize_path(path)
  return (path or ""):gsub("\\", "/")
end

local function is_absolute(path)
  return path:sub(1, 1) == "/"
end

function M.project_root()
  local git_root = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and git_root[1] and git_root[1] ~= "" then
    return normalize_path(git_root[1])
  end

  return normalize_path(vim.fn.getcwd())
end

function M.feedback_file()
  local path = config.options.feedback_path
  if is_absolute(path) then
    return normalize_path(path)
  end

  return normalize_path(M.project_root() .. "/" .. path)
end

function M.history_dir()
  local path = config.options.history_path
  if is_absolute(path) then
    return normalize_path(path)
  end

  return normalize_path(M.project_root() .. "/" .. path)
end

function M.relative_path(path)
  local full_path = normalize_path(vim.fn.fnamemodify(path, ":p"))
  local root = normalize_path(vim.fn.fnamemodify(M.project_root(), ":p")):gsub("/$", "")
  local prefix = root .. "/"

  if full_path:sub(1, #prefix) == prefix then
    return full_path:sub(#prefix + 1)
  end

  return normalize_path(vim.fn.fnamemodify(path, ":."))
end

function M.absolute_path(path)
  if is_absolute(path) then
    return normalize_path(path)
  end

  return normalize_path(M.project_root() .. "/" .. path)
end

local function next_id()
  return string.format("%d-%d", os.time(), #M.comments + 1)
end

function M.add(comment)
  comment.id = comment.id or next_id()
  comment.range_len = comment.end_line - comment.start_line
  table.insert(M.comments, comment)
  M.autosave()
  return comment
end

function M.update(comment, attrs)
  if attrs.body ~= nil then
    comment.body = attrs.body
  end

  if attrs.start_line ~= nil then
    comment.start_line = attrs.start_line
  end

  if attrs.end_line ~= nil then
    comment.end_line = attrs.end_line
  end

  comment.range_len = comment.end_line - comment.start_line
  M.autosave()
  return comment
end

function M.delete(comment)
  for index, existing in ipairs(M.comments) do
    if existing == comment or (comment.id ~= nil and existing.id == comment.id) then
      table.remove(M.comments, index)
      M.autosave()
      return true
    end
  end

  return false
end

function M.set_comments(comments)
  M.comments = comments or {}
  for _, comment in ipairs(M.comments) do
    comment.range_len = comment.end_line - comment.start_line
  end
end

function M.comments_for_path(path)
  local normalized = normalize_path(path)
  local out = {}

  for _, comment in ipairs(M.comments) do
    if normalize_path(comment.path) == normalized then
      table.insert(out, comment)
    end
  end

  return out
end

local function read_file_text(file)
  if vim.fn.filereadable(file) == 0 then
    return nil
  end

  local lines = vim.fn.readfile(file)
  if #lines == 0 then
    return ""
  end

  return table.concat(lines, "\n") .. "\n"
end

local function timestamp_for_file(file)
  local updated_at = vim.fn.getftime(file)
  if updated_at <= 0 then
    updated_at = os.time()
  end

  return os.date("%Y%m%d-%H%M%S", updated_at)
end

local function unique_history_file(dir, timestamp)
  local base = normalize_path(dir .. "/feedback-" .. timestamp .. ".md")
  local candidate = base
  local index = 1

  while vim.fn.filereadable(candidate) == 1 do
    candidate = normalize_path(string.format("%s/feedback-%s-%d.md", dir, timestamp, index))
    index = index + 1
  end

  return candidate
end

local function archive_feedback(file, existing_text)
  if existing_text == nil or not existing_text:match("%S") then
    return nil
  end

  local dir = M.history_dir()
  vim.fn.mkdir(dir, "p")

  local history_file = unique_history_file(dir, timestamp_for_file(file))
  if vim.fn.rename(file, history_file) ~= 0 then
    vim.fn.writefile(vim.split(existing_text:gsub("\n$", ""), "\n", { plain = true }), history_file)
    vim.fn.delete(file)
  end

  return history_file
end

function M.export()
  local file = M.feedback_file()
  local dir = vim.fn.fnamemodify(file, ":h")
  vim.fn.mkdir(dir, "p")

  local text = format.serialize(M.comments)
  local lines = {}

  if text ~= "" then
    lines = vim.split(text:gsub("\n$", ""), "\n", { plain = true })
  end

  vim.fn.writefile(lines, file)
  return file
end

function M.start()
  local file = M.feedback_file()
  local existing_text = read_file_text(file)

  M.comments = {}

  if existing_text == nil or not existing_text:match("%S") then
    return nil
  end

  archive_feedback(file, existing_text)
  return file
end

function M.new()
  local file = M.feedback_file()
  archive_feedback(file, read_file_text(file))

  M.comments = {}
  return file
end

M.clear = M.new

function M.autosave()
  if not config.options.autosave then
    return nil
  end

  return M.export()
end

function M.import()
  local file = M.feedback_file()
  if vim.fn.filereadable(file) == 0 then
    return false, file
  end

  local text = table.concat(vim.fn.readfile(file), "\n")
  M.set_comments(format.parse(text))
  return true, file
end

return M
