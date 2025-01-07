---@class PromptModule
local M = {}

---@class Prompt
---@field description string
---@field prompt string
---@field system_prompt string
---@field user_prompt string

---@type table<string, Prompt>
M.prompts = {
  ["Code review"] = {
    description = "Review the provided code",
    prompt = "Review the provided code and suggest improvements.",
    system_prompt = [[Analyze the code for:
### CODE QUALITY
* Function and variable naming (clarity and consistency)
* Code organization and structure
* Documentation and comments
* Consistent formatting and style

### RELIABILITY
* Error handling and edge cases
* Resource management
* Input validation

### MAINTAINABILITY
* Code duplication (but don't overdo it with DRY, some duplication is fine)
* Single responsibility principle
* Modularity and dependencies
* API design and interfaces
* Configuration management

### PERFORMANCE
* Algorithmic efficiency
* Resource usage
* Caching opportunities
* Memory management

### SECURITY
* Input sanitization
* Authentication/authorization
* Data validation
* Known vulnerability patterns

### TESTING
* Unit test coverage
* Integration test needs
* Edge case testing
* Error scenario coverage

### POSITIVE HIGHLIGHTS
* Note any well-implemented patterns
* Highlight good practices found
* Commend effective solutions

Format findings as markdown and with:
- Issue: [description]
- Impact: [specific impact]
- Suggestion: [concrete improvement with code example/suggestion]
    ]],
    user_prompt = "Please review this code and provide specific, actionable feedback:",
  },

  ["Explain code"] = {
    description = "Explain how the code works",
    prompt = "Please explain how this code works in detail.",
    system_prompt = "You are an expert programmer skilled at explaining complex code in a clear and concise manner. Break down the explanation into logical components and highlight key concepts.",
    user_prompt = "Please explain how the following code works:",
  },
}

---@return table
function M.to_codecompanion()
  local result = {}
  for key, prompt in pairs(M.prompts) do
    result[key] = {
      strategy = "chat",
      description = prompt.description,
      prompts = {
        {
          role = "system",
          content = prompt.system_prompt,
        },
        {
          role = "user",
          content = prompt.user_prompt .. "\n ",
        },
      },
    }
  end
  return result
end

---@return table
function M.to_copilot()
  local result = {}
  for key, prompt in pairs(M.prompts) do
    result[key] = {
      prompt = prompt.prompt,
      system_prompt = prompt.system_prompt,
      -- mapping = "<leader>ccmc",
      description = prompt.description,
    }
  end
  return result
end

return M
