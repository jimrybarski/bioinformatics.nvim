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


M.get_visual_selection = function()
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

M.set_pairwise_query = function(seq) 
    M.data.query_string = seq
end

M.set_pairwise_subject = function(seq) 
    M.data.subject_string = seq
end

M.pairwise_align = function(mode, try_reverse_complement, gap_open_penalty, gap_extend_penalty)
    -- set defaults
    local mode = mode or "semiglobal"
    local try_reverse_complement = try_reverse_complement or true
    local gap_open_penalty = gap_open_penalty or 2
    local gap_extend_penalty = gap_extend_penalty or 1
    try_rc_text = ""
    if try_reverse_complement then
        try_rc_text = "--try-rc"
    end
    local command = string.format('biotools pairwise-%s %s --gap-open %s --gap-extend %s %s %s ', mode, try_rc_text, gap_open_penalty, gap_extend_penalty, M.data.query_string, M.data.subject_string)
    -- Execute the command and capture the output
    local output = vim.fn.systemlist(command)

    -- Check for errors
    local ret_code = vim.v.shell_error
    if ret_code ~= 0 then
        vim.api.nvim_err_writeln("Error executing command: " .. table.concat(output, '\n'))
        return
    end
    M.show_popup(output)
end

M.get_string_width = function(output)
    local first_line = output[1]
    return string.len(first_line)
end

M.show_popup = function(output)
  if not M.pairwise_buf or not vim.api.nvim_buf_is_valid(M.pairwise_buf) then
    M.pairwise_buf = vim.api.nvim_create_buf(false, true)
  else
    -- Clear previous contents
    vim.api.nvim_buf_set_lines(M.pairwise_buf, 0, -1, false, {})
  end
  -- Set the buffer lines to the command output
  vim.api.nvim_buf_set_lines(M.pairwise_buf, 0, -1, false, output)
  -- Define the size and position of the window
  local width = M.get_string_width(output)
  local height = 3
  local row = 3
  local col = 3
  local cursor_r, cursor_c = unpack(vim.api.nvim_win_get_cursor(0))
  local current_window = vim.api.nvim_get_current_win()
  local winheight = vim.api.nvim_win_get_height(current_window)
  local win_height = math.min(winheight - 9, cursor_r + 1)

  -- Create a new floating window
  local win = vim.api.nvim_open_win(M.pairwise_buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = win_height,
    col = col,
    border = 'rounded',
    style = 'minimal',
  })

  -- Map 'q' to close the window
  vim.api.nvim_buf_set_keymap(M.pairwise_buf, 'n', 'q', '<Cmd>bd!<CR>', { noremap = true, silent = true })
end

return M
