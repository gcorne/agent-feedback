local commands = require("agent_review.commands")
local config = require("agent_review.config")
local extmarks = require("agent_review.extmarks")
local float = require("agent_review.float")
local storage = require("agent_review.storage")

local M = {}

local augroup = nil

local function current_range(opts)
  if opts and opts.range and opts.range > 0 then
    return math.min(opts.line1, opts.line2), math.max(opts.line1, opts.line2)
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  return line, line
end

local function current_relative_path()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return nil
  end

  return storage.relative_path(path)
end

local function find_comment(path, start_line, end_line)
  local containing = nil
  local overlapping = nil

  for _, comment in ipairs(storage.comments_for_path(path)) do
    if comment.start_line == start_line and comment.end_line == end_line then
      return comment
    end

    if comment.start_line <= start_line and comment.end_line >= end_line then
      containing = containing or comment
    elseif comment.start_line <= end_line and start_line <= comment.end_line then
      overlapping = overlapping or comment
    end
  end

  return containing or overlapping
end

function M.setup(opts)
  config.setup(opts)
  storage.start()
  extmarks.setup()
  commands.setup()

  if augroup then
    vim.api.nvim_del_augroup_by_id(augroup)
  end

  augroup = vim.api.nvim_create_augroup("AgentReview", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    group = augroup,
    callback = function(args)
      if args.event == "BufWritePost" then
        extmarks.sync_buffer(args.buf)
        storage.autosave()
      end

      extmarks.refresh_buffer(args.buf)
    end,
  })
end

function M.feedback(opts)
  local source_buf = vim.api.nvim_get_current_buf()
  local path = current_relative_path()
  if path == nil then
    vim.notify("AgentReview: current buffer has no file path", vim.log.levels.WARN)
    return
  end

  local start_line, end_line = current_range(opts)
  local comment = find_comment(path, start_line, end_line)

  float.open({ end_line = end_line, body = comment and comment.body or "" }, function(body)
    if body == "" and comment == nil then
      return
    end

    if comment then
      storage.update(comment, { body = body })
      vim.notify("AgentReview: comment updated", vim.log.levels.INFO)
    else
      storage.add({
        path = path,
        start_line = start_line,
        end_line = end_line,
        body = body,
      })
      vim.notify("AgentReview: comment added", vim.log.levels.INFO)
    end

    if vim.api.nvim_buf_is_valid(source_buf) then
      extmarks.refresh_buffer(source_buf)
    end
  end)
end

M.add_comment = M.feedback

function M.delete()
  local source_buf = vim.api.nvim_get_current_buf()
  local path = current_relative_path()
  if path == nil then
    vim.notify("AgentReview: current buffer has no file path", vim.log.levels.WARN)
    return
  end

  extmarks.sync_buffer(source_buf)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local comment = find_comment(path, line, line)
  if comment == nil then
    vim.notify("AgentReview: no feedback on current line", vim.log.levels.WARN)
    return
  end

  storage.delete(comment)

  if vim.api.nvim_buf_is_valid(source_buf) then
    extmarks.refresh_buffer(source_buf)
  end

  vim.notify("AgentReview: comment deleted", vim.log.levels.INFO)
end

function M.export()
  extmarks.sync_all_loaded_buffers()
  local file = storage.export()
  vim.notify("AgentReview: exported feedback to " .. file, vim.log.levels.INFO)
end

function M.import()
  local ok, file = storage.import()
  if not ok then
    vim.notify("AgentReview: no feedback file at " .. file, vim.log.levels.WARN)
    return
  end

  extmarks.refresh_all_loaded_buffers()
  vim.notify("AgentReview: imported feedback from " .. file, vim.log.levels.INFO)
end

function M.list()
  local items = {}

  for _, comment in ipairs(storage.comments) do
    local first_line = (comment.body or ""):gsub("\n", " ")
    table.insert(items, {
      filename = storage.absolute_path(comment.path),
      lnum = comment.start_line,
      end_lnum = comment.end_line,
      text = first_line,
    })
  end

  vim.fn.setqflist({}, " ", {
    title = "Agent Review",
    items = items,
  })

  vim.cmd("copen")
end

function M.new()
  storage.new()
  extmarks.refresh_all_loaded_buffers()
  vim.notify("AgentReview: started a new feedback file", vim.log.levels.INFO)
end

M.clear = M.new

M.storage = storage
M.format = require("agent_review.format")

return M
