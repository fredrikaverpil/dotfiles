M.api_key = nil

local function get_api_key()
  if M.api_key then
    return M.api_key
  end

  local cmd = "gcloud auth application-default print-access-token"
  local handle = io.popen(cmd)
  if handle then
    local result = handle:read("*a")
    handle:close()
    local api_key = result:gsub("%s+", "") -- Remove any trailing newline or spaces
    M.api_key = api_key
    return api_key
  end
  return nil
end

local function get_endpoint()
  -- The full URL used should be:
  -- https://{region}-aiplatform.googleapis.com/v1/projects/{project_id}/locations/{region}/publishers/google/models/gemini-2.0-flash-001:streamGenerateContent

  local project_id = os.getenv("GOOGLE_CLOUD_PROJECT")
  local region = os.getenv("GOOGLE_CLOUD_LOCATION")
  local url = string.format(
    "https://%s-aiplatform.googleapis.com/v1/projects/%s/locations/%s/publishers/google/models",
    region,
    project_id,
    region
  )

  return url
end

return {
  {
    -- NOTE: Vertex support requires adding header in minuet's backends/gemini.lua:
    -- ['Authorization'] = 'Bearer ' .. utils.get_api_key(options.api_key),

    "milanglacier/minuet-ai.nvim",
    lazy = true,
    opts = {

      virtualtext = {
        auto_trigger_ft = {},
        keymap = {
          -- accept whole completion
          accept = "<A-L>",
          -- accept one line
          accept_line = "<A-l>",
          -- accept n lines (prompts for number)
          -- e.g. "A-z 2 CR" will accept 2 lines
          accept_n_lines = "<A-z>",
          -- Cycle to prev completion item, or manually invoke completion
          prev = "<A-[>",
          -- Cycle to next completion item, or manually invoke completion
          next = "<A-]>",
          dismiss = "<A-e>",
        },
      },

      provider = "gemini",
      provider_options = {
        gemini = {
          model = "gemini-2.0-flash",
          -- system = "see [Prompt] section for the default value",
          -- few_shots = "see [Prompt] section for the default value",
          -- chat_input = "See [Prompt Section for default value]",
          stream = true,
          -- api_key = "GEMINI_API_KEY",
          api_key = get_api_key,
          -- end_point = "https://generativelanguage.googleapis.com/v1beta/models",
          end_point = get_endpoint(),
          optional = {},
        },
      },
    },
    config = function(_, opts)
      require("minuet").setup(opts)
    end,
    cmd = { "Minuet" },
  },
}
