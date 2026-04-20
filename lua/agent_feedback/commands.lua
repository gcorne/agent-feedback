local M = {}

function M.setup()
  vim.api.nvim_create_user_command("AgentFeedback", function(opts)
    require("agent_feedback").feedback(opts)
  end, {
    desc = "Add or edit feedback for the current line or range",
    force = true,
    range = true,
  })

  vim.api.nvim_create_user_command("AgentFeedbackExport", function()
    require("agent_feedback").export()
  end, {
    desc = "Export feedback comments",
    force = true,
  })

  vim.api.nvim_create_user_command("AgentFeedbackImport", function()
    require("agent_feedback").import()
  end, {
    desc = "Import feedback comments",
    force = true,
  })

  vim.api.nvim_create_user_command("AgentFeedbackList", function()
    require("agent_feedback").list()
  end, {
    desc = "List feedback comments",
    force = true,
  })

  vim.api.nvim_create_user_command("AgentFeedbackDelete", function()
    require("agent_feedback").delete()
  end, {
    desc = "Delete feedback for the current line",
    force = true,
  })

  vim.api.nvim_create_user_command("AgentFeedbackNew", function()
    require("agent_feedback").new()
  end, {
    desc = "Start a new feedback file",
    force = true,
  })
end

return M
