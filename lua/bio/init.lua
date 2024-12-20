local M = {}

M.data = {}

--- Transcribes a DNA sequence to RNA by replacing thymine (T) with uracil (U).
-- @param dna_seq The DNA sequence as a string
-- @return RNA sequence as a string
M.dna_to_rna = function(dna_seq)
    return dna_seq:gsub("T", "U")
end

--- Returns the reverse complement of a DNA sequence.
-- @param dna_seq The DNA sequence as a string
-- @return Reverse complemented DNA sequence as a string
M.reverse_complement = function(dna_seq)
    local complement = {A = 'T', T = 'A', C = 'G', G = 'C'}
    return dna_seq:reverse():gsub(".", complement)
end


M.get_visually_selected_text = function()
  vim.cmd([[execute "normal! \<esc>"]])
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('gv', true, false, true), 'n', false)

  local bufnr = vim.api.nvim_get_current_buf()

  -- Retrieve positions of visually selected text
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local csrow = start_pos[2] - 1
  local cscol = start_pos[3] - 1
  local cerow = end_pos[2] - 1
  local cecol = end_pos[3] 

  -- Reorder if selection is reversed
  if csrow > cerow or (csrow == cerow and cscol > cecol) then
    csrow, cscol, cerow, cecol = cerow, cecol, csrow, cscol
  end

  -- Retrieve lines within the visual selection
  local lines = vim.api.nvim_buf_get_lines(bufnr, csrow, cerow + 1, false)

  -- Check and handle special case if no lines were retrieved
  if #lines == 0 then
    return ""
  end

  -- Handle single-line selection
  if #lines == 1 then
    lines[1] = string.sub(lines[1], cscol + 1, cecol)
  else
    -- Adjust the first and last lines for multi-line selection
    lines[1] = string.sub(lines[1], cscol + 1)
    lines[#lines] = string.sub(lines[#lines], 1, cecol)
  end

  -- Join the lines into a single string
  return table.concat(lines, "\n")
end

M.set_query_string = function() 
    local s = M.get_visually_selected_text()
    M.data.query_string = s
    vim.notify("Set query string to " .. s, "info", {timeout=0.5})
end

M.set_subject_string = function() 
    local s = M.get_visually_selected_text()
    M.data.subject_string = s
    vim.notify("Set subject string to " .. s, "info", {timeout=0.5})
end

M.pairwise_alignment = function()
    local command = string.format('biotools pairwise-semiglobal --try-rc %s %s', M.data.query_string, M.data.subject_string)
    -- Execute the command and capture the output
    local output = vim.fn.systemlist(command)

    -- Check for errors
    local ret_code = vim.v.shell_error
    if ret_code ~= 0 then
        vim.api.nvim_err_writeln("Error executing command: " .. table.concat(output, '\n'))
        return
    end
    -- vim.notify(output, "info")
    M.show_popup(output)
end

M.show_popup = function(output)
  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)  -- No listed buffer, scratch buffer

  -- Set the buffer lines to the command output
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)

  -- Define the size and position of the window
  local width = math.max(10, math.floor(vim.o.columns * 0.8))
  local height = math.max(10, math.floor(vim.o.lines * 0.8))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create a new floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal'
  })

  -- Map 'q' to close the window
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<Cmd>bd!<CR>', { noremap = true, silent = true })
end

return M
