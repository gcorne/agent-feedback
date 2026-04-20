local M = {}

M.defaults = {
  feedback_path = ".agent-feedback/feedback.md",
  history_path = ".agent-feedback/history",
  autosave = true,
  sign_text = ">>",
  virtual_text = "review",
  line_hl_group = nil,
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
