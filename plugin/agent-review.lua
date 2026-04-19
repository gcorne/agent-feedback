if vim.g.loaded_agent_review == 1 then
  return
end

vim.g.loaded_agent_review = 1

require("agent_review").setup()
