if vim.g.loaded_agent_feedback == 1 then
  return
end

vim.g.loaded_agent_feedback = 1

require("agent_feedback").setup()
