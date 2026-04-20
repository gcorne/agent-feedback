local M = {}

local function close_window(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

function M.open(opts, on_submit)
  opts = opts or {}

  local source_win = vim.api.nvim_get_current_win()
  local source_buf = vim.api.nvim_get_current_buf()
  local end_line = opts.end_line or vim.api.nvim_win_get_cursor(source_win)[1]
  local last_line = vim.api.nvim_buf_line_count(source_buf)

  end_line = math.max(1, math.min(end_line, last_line))
  vim.api.nvim_win_set_cursor(source_win, { end_line, 0 })

  local width = math.min(80, math.max(30, vim.o.columns - 8))
  local height = opts.height or 5
  local buf = vim.api.nvim_create_buf(false, true)
  local initial_body = (opts.body or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
  local initial_lines = { "" }

  if initial_body ~= "" then
    initial_lines = vim.split(initial_body, "\n", { plain = true })
  end

  vim.api.nvim_buf_set_name(buf, string.format("agent_feedback://feedback/%d", buf))
  vim.api.nvim_buf_set_option(buf, "buftype", "acwrite")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "agent_feedback-comment")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, initial_lines)
  vim.api.nvim_buf_set_option(buf, "modified", false)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " Feedback ",
  })

  local submitted = false

  local function submit()
    if submitted then
      return
    end

    submitted = true
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local body = table.concat(lines, "\n"):gsub("%s+$", "")
    vim.api.nvim_buf_set_option(buf, "modified", false)
    close_window(win)
    if vim.api.nvim_win_is_valid(source_win) then
      vim.api.nvim_set_current_win(source_win)
    end

    if vim.api.nvim_buf_is_valid(source_buf) then
      vim.api.nvim_set_current_buf(source_buf)
    end

    on_submit(body)
  end

  local function cancel()
    submitted = true
    close_window(win)
    if vim.api.nvim_win_is_valid(source_win) then
      vim.api.nvim_set_current_win(source_win)
    end
  end

  vim.keymap.set("n", "<CR>", submit, { buffer = buf, silent = true, nowait = true })
  vim.keymap.set({ "n", "i" }, "<C-s>", submit, { buffer = buf, silent = true, nowait = true })
  vim.keymap.set("n", "q", cancel, { buffer = buf, silent = true, nowait = true })
  vim.keymap.set("n", "<Esc>", cancel, { buffer = buf, silent = true, nowait = true })
  vim.keymap.set("i", "<C-c>", cancel, { buffer = buf, silent = true, nowait = true })

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      submit()
    end,
  })

  vim.cmd("startinsert")
end

return M
