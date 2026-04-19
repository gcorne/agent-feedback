local config = require("agent_review.config")
local storage = require("agent_review.storage")

local M = {}

M.ns = vim.api.nvim_create_namespace("agent_review")

function M.setup()
  vim.cmd("highlight default link AgentReviewSign DiagnosticInfo")
  vim.cmd("highlight default link AgentReviewVirtualText Comment")
end

local function buffer_path(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return nil
  end

  return storage.relative_path(name)
end

function M.refresh_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end

  local path = buffer_path(bufnr)
  if path == nil then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)

  for _, comment in ipairs(storage.comments_for_path(path)) do
    comment.extmarks = comment.extmarks or {}
    comment.extmarks[bufnr] = {}

    local last_line = vim.api.nvim_buf_line_count(bufnr)
    local start_line = math.max(1, math.min(comment.start_line, last_line))
    local end_line = math.max(start_line, math.min(comment.end_line, last_line))

    for line = start_line, end_line do
      local opts = {
        right_gravity = false,
        sign_text = config.options.sign_text,
        sign_hl_group = "AgentReviewSign",
      }

      if config.options.line_hl_group then
        opts.line_hl_group = config.options.line_hl_group
      end

      if line == end_line then
        opts.virt_text = { { config.options.virtual_text, "AgentReviewVirtualText" } }
        opts.virt_text_pos = "eol"
      end

      local id = vim.api.nvim_buf_set_extmark(bufnr, M.ns, line - 1, 0, opts)
      table.insert(comment.extmarks[bufnr], id)
    end
  end
end

function M.refresh_all_loaded_buffers()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      M.refresh_buffer(bufnr)
    end
  end
end

function M.sync_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  for _, comment in ipairs(storage.comments) do
    local ids = comment.extmarks and comment.extmarks[bufnr]
    local anchor = ids and ids[1]

    if anchor then
      local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, M.ns, anchor, {})
      if pos and pos[1] then
        comment.start_line = pos[1] + 1
        comment.end_line = comment.start_line + (comment.range_len or 0)
      end
    end
  end
end

function M.sync_all_loaded_buffers()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      M.sync_buffer(bufnr)
    end
  end
end

return M
