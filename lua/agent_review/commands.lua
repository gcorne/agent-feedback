local M = {}

function M.setup()
  vim.api.nvim_create_user_command("AgentReviewAdd", function(opts)
    require("agent_review").add_comment(opts)
  end, {
    desc = "Add an agent review comment for the current line or range",
    force = true,
    range = true,
  })

  vim.api.nvim_create_user_command("AgentReviewExport", function()
    require("agent_review").export()
  end, {
    desc = "Export agent review comments",
    force = true,
  })

  vim.api.nvim_create_user_command("AgentReviewImport", function()
    require("agent_review").import()
  end, {
    desc = "Import agent review comments",
    force = true,
  })

  vim.api.nvim_create_user_command("AgentReviewList", function()
    require("agent_review").list()
  end, {
    desc = "List agent review comments",
    force = true,
  })

  vim.api.nvim_create_user_command("AgentReviewClear", function()
    require("agent_review").clear()
  end, {
    desc = "Clear agent review comments from memory",
    force = true,
  })
end

return M
