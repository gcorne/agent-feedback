if vim.g.loaded_agent_feedback then
  return
end

vim.g.loaded_agent_feedback = true

require("agent_feedback").setup()
