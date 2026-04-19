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
  return comment
end

function M.clear()
  M.comments = {}
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
