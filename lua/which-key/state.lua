local Buf = require("which-key.buf")
local UI = require("which-key.ui")
local Util = require("which-key.util")

local M = {}

---@class wk.State
---@field buf? number
---@field path? wk.Path
---@field debug? string
M.state = {}

function M.setup()
  local group = vim.api.nvim_create_augroup("wk", { clear = true })

  local in_op = false
  vim.on_key(function(_, key)
    if not key then
      return
    end
    if in_op and key:find("\27") then
      in_op = false
      M.set()
    end
  end)

  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    callback = function(ev)
      local buf = Buf.attach(ev.buf)
      if buf and buf:valid() then
        local mode = buf:update()
        if mode then
          if mode.mode:find("[xo]") then
            M.set({ node = mode.tree.root, keys = {} }, "mode_1")
            local char = vim.fn.getcharstr()
            M.set(mode.tree:find(char), "mode_2")
            in_op = true
            vim.api.nvim_feedkeys(char, "mit", false)
            return
          end
        end
      end
      M.set()
    end,
  })

  vim.api.nvim_create_autocmd({ "BufReadPost", "LspAttach" }, {
    group = group,
    callback = function(ev)
      local buf = Buf.attach(ev.buf)
      if buf and buf:valid() then
        buf:update()
      end
    end,
  })

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    Buf.attach(buf)
  end
end

---@param path? wk.Path
---@param debug? string
function M.set(path, debug)
  if not path then
    M.state = {}
    require("which-key.ui").hide()
    return
  end
  M.state.buf = vim.api.nvim_get_current_buf()
  M.state.path = path
  M.state.debug = debug
  require("which-key.ui").show()
end

---@return wk.State?
function M.get()
  if M.state.buf and M.state.buf == vim.api.nvim_get_current_buf() then
    return M.state
  end
  M.state = {}
end

return M