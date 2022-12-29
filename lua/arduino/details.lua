local settings = require 'arduino.settings'
local utility = require 'arduino.utility'
local path = require 'arduino.path'

local M = {
  plugname = '[ArduinoLSP.nvim]',
  configname = 'arduinolsp_config',
  -- Regex for finding the data path from 'arduino-cli config dump' output
  data_regexp_pattern =
  '\\Mdata: \\zs\\[-\\/\\\\.[:alnum:]_~]\\+\\ze\\[[:space:]\\n]'
}

M.config_file = path.concat {
  settings.current.config_dir, M.configname
}

M.on_fqbn_reset = settings.current.on_fqbn_reset

function M.error(msg)
  vim.notify(M.plugname .. ' error: ' .. msg, vim.log.levels.ERROR)
end

function M.warn(msg)
  vim.notify(M.plugname .. ' warning: ' .. msg, vim.log.levels.WARN)
end

---Returns true, if o is executable, false otherwise
---@param o string
---@nodiscard
---@return boolean
function M.is_exe(o)
  assert(type(o) == "string")
  return vim.fn.executable(o) == 1
end

---Returns true, if o is a directory, false otherwise
---@nodiscard
---@param o string
---@return boolean
function M.is_dir(o)
  assert(type(o) == "string")
  return vim.fn.isdirectory(o) == 1
end

function M.get_data_from_config()
  local data, message = utility.read_file(M.config_file)

  if not data then return {} end

  local fqbn_table = {}
  fqbn_table, message = utility.deserialize(data)

  if not fqbn_table then
    M.warn(('%s Config deserialization error: %s')
      :format(M.plugname, message))
    return {}
  end

  return fqbn_table
end

function M.ask_user_for_fqbn()
  local fqbn = settings._default_settings.default_fqbn

  vim.ui.input({
    prompt = ('%s enter the FQBN: '):format(M.plugname),
  },
    function(input)
      if input then fqbn = input end
    end)

  return fqbn
end

function M.get_fqbn(directory)
  local data = M.get_data_from_config()
  local fqbn = data[directory]

  if fqbn then return fqbn end

  fqbn = M.ask_user_for_fqbn()
  data[directory] = fqbn

  utility.write_file(M.config_file, utility.serialize(data))

  return fqbn

end

return M