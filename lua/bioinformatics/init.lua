local M = {}

M.data = {}

--- Converts a DNA sequence to RNA.
--- @param dna_seq string The DNA sequence
--- @return string RNA sequence
M.dna_to_rna = function(dna_seq)
    return dna_seq:gsub("T", "U")
end

--- Converts an RNA sequence to DNA.
--- @param rna_seq string The RNA sequence
--- @return string DNA sequence
M.rna_to_dna = function(rna_seq)
    return rna_seq:gsub("U", "T")
end

--- Returns the reverse complement of a DNA sequence.
--- @param dna_seq string DNA sequence
--- @return string Reverse complemented DNA sequence
M.reverse_complement = function(dna_seq)
    local complement = {A = 'T', T = 'A', C = 'G', G = 'C'}
    return dna_seq:reverse():gsub(".", complement)
end

--- Computes the GC content of an RNA/DNA sequence.
--- @param seq string RNA or DNA sequence
--- @return number A float between 0.0 and 1.0, inclusive.
M.gc_content = function(seq)
    local normalized_sequence = seq:upper()
    local gc_count = 0
    local length = #normalized_sequence

    for i = 1, length do
        local nucleotide = normalized_sequence:sub(i, i)
        if nucleotide == 'G' or nucleotide == 'C' then
            gc_count = gc_count + 1
        end
    end

    return (gc_count / length)
end

--- Gets the text of the current visual selection.
--- @return string
M.get_visual_selection = function()
    vim.cmd([[execute "normal! \<esc>"]])
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('gv', true, false, true), 'n', false)

    -- Retrieve positions of visually selected text
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    -- Get the start and end coordinates of the visual selection
    local csrow = start_pos[2] - 1
    local cscol = start_pos[3] - 1
    local cerow = end_pos[2] - 1
    local cecol = end_pos[3] 

    -- Reorder if selection is reversed
    if csrow > cerow or (csrow == cerow and cscol > cecol) then
        csrow, cscol, cerow, cecol = cerow, cecol, csrow, cscol
    end

    -- Retrieve lines within the visual selection
    local buffer = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buffer, csrow, cerow + 1, false)

    -- There was nothing selected - I'm not sure this is possible
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

--- Saves the top sequence for a pairwise alignment
--- @param seq string DNA sequence
M.set_pairwise_query = function(seq) 
    M.data.query_string = seq
end

--- Saves the bottom sequence for a pairwise alignment
--- @param seq string DNA sequence
M.set_pairwise_subject = function(seq) 
    M.data.subject_string = seq
end

--- Runs a pairwise alignment with biotools
--- @param mode string one of "local", "semiglobal" or "global". Default: "semiglobal"
--- @param try_reverse_complement bool align the forward and reverse complement and return the one with the better score. Default: true
--- @param hide_coords bool whether to hide the coordinates of each aligned sequences. Default: false
--- @param gap_open_penalty int the gap open penalty, as a positive integer. Default: 2
--- @param gap_extend_penalty int the gap extension penalty, as a positive integer. Default: 1
--- @return table a list of (usually three) lines with the pairwise alignment text
M.pairwise_align = function(mode, try_reverse_complement, hide_coords, gap_open_penalty, gap_extend_penalty)
    -- set defaults
    local mode = mode or "semiglobal"
    local try_reverse_complement = try_reverse_complement or true
    local hide_coords = hide_coords or false
    local gap_open_penalty = gap_open_penalty or 2
    local gap_extend_penalty = gap_extend_penalty or 1
    try_rc_text = ""
    if try_reverse_complement then
        try_rc_text = "--try-rc"
    end
    local command = string.format('biotools pairwise-%s %s --gap-open %s --gap-extend %s %s %s ', mode, try_rc_text, gap_open_penalty, gap_extend_penalty, M.data.query_string, M.data.subject_string)
    -- Execute the command and capture the output
    output = vim.fn.systemlist(command)

    -- Check for errors
    local ret_code = vim.v.shell_error
    if ret_code ~= 0 then
        vim.api.nvim_err_writeln("Error executing command: " .. table.concat(output, '\n'))
        return
    end
    return output
end

--- Gets the length of a pairwise alignment
--- @param output string the string to measure
M.get_alignment_width = function(output)
    local first_line = output[1]
    return string.len(first_line)
end

--- Initiate a search for a string
--- @param needle string the string to search for
M.search_string = function(needle)
    local search_pattern = vim.fn.escape(needle, '\\')
    vim.fn.feedkeys('/' .. search_pattern .. '\r', 'n')
end

--- Displays a pairwise alignment in a popup. The text can be manipulated like any other buffer. Pressing 'q' closes
--- the popup.
--- @param alignment_text table lines of a pairwise alignment (usually produced by pairwise_align())
M.display_alignment = function(alignment_text)
    if not M.pairwise_buf or not vim.api.nvim_buf_is_valid(M.pairwise_buf) then
        -- Create a new buffer for displaying the alignment
        M.pairwise_buf = vim.api.nvim_create_buf(false, true)
    end
    -- Put the alignment text into the buffer
    vim.api.nvim_buf_set_lines(M.pairwise_buf, 0, -1, false, alignment_text)

    -- Define the size and position of the popup window
    local width = M.get_string_width(alignment_text)
    --- Currently hardcoded to 3, which is sufficient for short alignments. We need to handle alignments with breaks.
    local height = 3
    --- Distance from the left of the window to place the popup
    local left_margin = 3
    --- Try to put the popup slightly below the cursor, but don't put it past the end of the window.
    local cursor_r, cursor_c = unpack(vim.api.nvim_win_get_cursor(0))
    local current_window = vim.api.nvim_get_current_win()
    local winheight = vim.api.nvim_win_get_height(current_window)
    --- I think this hard-coded 9 is specific to my scrolloff value, we need to figure this out dynamically
    local win_height = math.min(winheight - 9, cursor_r + 1)

    -- Create the popup
    local win = vim.api.nvim_open_win(M.pairwise_buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = win_height,
        col = left_margin,
        border = 'rounded',
        style = 'minimal',
    })
    -- Map 'q' to close the window
    vim.api.nvim_buf_set_keymap(M.pairwise_buf, 'n', 'q', '<Cmd>bd!<CR>', { noremap = true, silent = true })
end

return M
