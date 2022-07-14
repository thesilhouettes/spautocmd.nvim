local M = {}

M.log = function(hl, what)
  vim.cmd(string.format("echohl %s", hl))
  vim.cmd(string.format([[echom "spautocmd: %s"]], what))
  vim.cmd "echohl NONE"
end

M.warn = function(what)
  M.log("WarningMsg", what)
end

M.error = function(what)
  M.log("ErrorMsg", what)
end

return M
