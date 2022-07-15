local logger = require "utils.log"
local M = {
  -- we remember which group is triggered
  -- and which ones are not
  enabled_triggers = {},
}

-- for example, c will change *.c
-- don't do anything if the filetype is wildcard *
local function get_filter(filetype)
  local filter = "*"
  if filetype ~= "*" then
    filter = "*." .. filetype
  end
  return filter
end

-- this function checks if t is a table, if not output error
local function is_table(t, name, msg)
  if type(t) ~= "table" then
    logger.error(msg or string.format("%s is not a table!", name))
    return false
  end
  return true
end

-- this creates an augroup
-- however if only_text is true, it will not be run with vim.cmd
-- return the augroup string if only_text is true
local function create_group(name, lines, only_text)
  -- the group name is just arbitrary, hopefully it will not crash with other
  -- plugins
  local text = string.format(
    [[
augroup __spautocmd_%s
autocmd!
%s
augroup END
]],
    name,
    lines
  )
  if only_text then
    return text
  else
    vim.cmd(text)
  end
end

-- create autocmd <filetype> <event> <action> lines
-- and return all lines as a single string
local function create_lines(arr, event, filetype)
  local acc = ""
  for _, cmd in ipairs(arr) do
    acc = acc
      .. string.format("autocmd %s %s %s\n", event, get_filter(filetype), cmd)
  end
  return acc
end

-- this creates a "trigger object"
-- later it will be use in registeration of triggers
-- see README about the options of trigger
local function process_trigger(filetype, event, trigger)
  -- warn user if there is no key to start their auto commands
  if trigger.key == nil then
    logger.warn(
      string.format("trigger key is missing for %s %s", filetype, event)
    )
  end
  local trigger_object = {
    key = trigger.key,
    options = trigger.options,
    -- this is just an arbitrary name that hopefully will not crash with other
    -- plugins
    name = filetype .. "_" .. event,
  }
  -- we loop through the trigger table to find the commands
  local trigger_commands = create_lines(trigger, event, filetype)
  -- trigger_object.augroup will hold the augroup string
  -- it will only be applied if the user triggers it with keybindings
  trigger_object.augroup =
    create_group(trigger_object.name, trigger_commands, true)
  return trigger_object
end

-- this will process everything under a filetype
-- for example if lua has BufRead, BufWrite it will process
-- all of those
local function process_event_handler(filetype, events)
  if not is_table(events, "filetype") then
    return false
  end

  -- everything that has to be put into the auto command group
  local all_commands = ""
  local triggers = {}

  -- this loops through events like BufWritePre, BufRead ...
  for event_name, cmds in pairs(events) do
    if not is_table(cmds, "cmds") then
      return false
    end

    -- we first add the startup commands
    all_commands = all_commands
      .. "\n"
      .. create_lines(cmds, event_name, filetype)

    -- check if our event has trigger commands
    if cmds.trigger ~= nil then
      -- if yes, then add triggers
      triggers[event_name] = process_trigger(filetype, event_name, cmds.trigger)
    end
  end

  -- finally register startup auto commands
  create_group(filetype, all_commands)
  return triggers
end

-- this adds the key for adding the augruop and removing it
local function register_trigger(filetype, trigger)
  -- it will ignore the trigger if no key is set
  for event_name, args in pairs(trigger) do
    -- why is <leader> and <localleader> not evaluated??
    local key, _ = string.gsub(args.key, "<leader>", vim.g.leader)
    key, _ = string.gsub(key, "<localleader>", vim.g.localleader)
    -- fellow neovim exports, please help me
    vim.keymap.set("n", key, function()
      if not M.enabled_triggers[args.name] then
        vim.cmd(args.augroup)
        logger.log(
          "Bold",
          string.format("enabling %s %s", filetype, event_name)
        )
        M.enabled_triggers[args.name] = true
      else
        -- disable the group
        logger.log(
          "Bold",
          string.format("disabling %s %s", filetype, event_name)
        )
        create_group(args.name, "", false)
        M.enabled_triggers[args.name] = false
      end
    end, args.options)
  end
end

-- users will call this function to set up the autocmds
M.setup = function(opts)
  -- setup some bold colours
  vim.cmd "highlight Bold cterm=Bold gui=Bold"

  if type(opts) ~= "table" then
    logger.warn "received an empty configuration! No autocmds will be applied."
    return false
  end

  -- read cmds
  if type(opts.cmds) ~= "table" then
    logger.error "The cmds key is not a table. I do not know how to process it."
    return false
  end

  -- all_handlers are basically useless, but may be useful
  -- it will be returned at the end of this setup function
  local all_handlers = {}
  -- process_event_handler only handles one filetype at a time
  -- we loop through all filetypes and pass it to the function
  for filetype, events in pairs(opts.cmds) do
    local s = process_event_handler(filetype, events)
    if not s then
      logger.error(
        string.format("There is something wrong in %s filetype", filetype)
      )
    else
      all_handlers[filetype] = s
      -- check if s is {}, if not register the triggers
      -- {} means no triggers
      if next(s) ~= nil then
        register_trigger(filetype, s)
      end
    end
  end
  return all_handlers
end

return M
