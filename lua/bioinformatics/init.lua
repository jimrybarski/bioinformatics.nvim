local M = {}

M.data = {}

--- Converts a DNA sequence to RNA.
--- @param dna_seq string The DNA sequence
--- @return string RNA sequence
M.dna_to_rna = function(dna_seq)
    return (dna_seq:gsub("T", "U"))
end

--- Converts an RNA sequence to DNA.
--- @param rna_seq string The RNA sequence
--- @return string DNA sequence
M.rna_to_dna = function(rna_seq)
    return (rna_seq:gsub("U", "T"))
end

--- Returns the length of a DNA sequence, ignoring whitespace and dashes.
--- @param seq string DNA sequence
--- @return number Length of the sequence
M.length = function(seq)
    local normalized_sequence = seq:gsub("[%s%-]", "")
    return #normalized_sequence
end

--- Returns the reverse complement of a DNA sequence.
--- @param dna_seq string DNA sequence
--- @return string Reverse complemented DNA sequence
M.reverse_complement = function(dna_seq)
    local complement = { A = 'T', T = 'A', C = 'G', G = 'C' }
    return (dna_seq:reverse():gsub(".", complement))
end

--- Computes the GC content of an RNA/DNA sequence.
--- @param seq string RNA or DNA sequence
--- @return number A float between 0.0 and 1.0, inclusive.
M.gc_content = function(seq)
    local normalized_sequence = seq:upper():gsub("[%s%-]", "")
    local length = #normalized_sequence
    
    if length == 0 then
        return 0
    end

    local gc_count = 0
    for i = 1, length do
        local nucleotide = normalized_sequence:sub(i, i)
        if nucleotide == 'G' or nucleotide == 'C' then
            gc_count = gc_count + 1
        end
    end

    return gc_count / length
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
    return table.concat(lines, "")
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
--- @param opts table|nil Optional parameters table with keys:
---   - mode: string one of "local", "semiglobal" or "global". Default: "semiglobal"
---   - try_reverse_complement: boolean align the forward and reverse complement and return the one with the better score. Default: true
---   - hide_coords: boolean whether to hide the coordinates of each aligned sequences. Default: false
---   - gap_open_penalty: integer the gap open penalty, as a positive integer. Default: 2
---   - gap_extend_penalty: integer the gap extension penalty, as a positive integer. Default: 1
---   - line_width: integer the number of characters in an alignment before a line wrap. Default: 60
---   - use_0_based_coords: boolean use 0-based coordinates. Default: false
--- @return table|nil a list of (usually three) lines with the pairwise alignment text. nil is returned when there's an error running biotools.
M.pairwise_align = function(opts)
    opts = opts or {}
    -- set defaults
    local mode = opts.mode or "semiglobal"
    local try_reverse_complement = opts.try_reverse_complement ~= false  -- default true, but allow explicit false
    local hide_coords = opts.hide_coords or false
    local gap_open_penalty = opts.gap_open_penalty or 2
    local gap_extend_penalty = opts.gap_extend_penalty or 1
    local line_width = opts.line_width or 60
    local use_0_based_coords = opts.use_0_based_coords or false
    local try_rc_text = ""
    if try_reverse_complement then
        try_rc_text = "--try-rc"
    end
    local hide_coords_text = ""
    if hide_coords then
        hide_coords_text = "--hide-coords"
    end

    local use_0_based_coords_text = ""
    if use_0_based_coords then
        use_0_based_coords_text = "--use-0-based-coords"
    end
    -- run biotools
    local command = string.format(
        'biotools pairwise-%s %s %s --gap-open %s --gap-extend %s --line-width %s %s %s %s ', mode,
        try_rc_text,
        hide_coords_text,
        gap_open_penalty, gap_extend_penalty, line_width, use_0_based_coords_text, M.data.query_string,
        M.data.subject_string)
    local output = vim.fn.systemlist(command)

    if M._check_for_command_error() then
        return
    end
    return output
end

M._check_for_command_error = function()
    local ret_code = vim.v.shell_error
    if ret_code ~= 0 then
        return true
    end
    return false
end

--- Gets the length of a pairwise alignment
--- @param output table a table containing strings we want to measure. Assumes all strings are the same length.
M._get_alignment_width = function(output)
    local first_line = output[1]
    return string.len(first_line)
end

--- Initiate a search for a string
--- @param needle string the string to search for
M.search_for_string = function(needle)
    local search_pattern = vim.fn.escape(needle, '\\')
    vim.fn.feedkeys('/' .. search_pattern .. '\r', 'n')
end

--- Displays a pairwise alignment in a popup. The text can be manipulated like any other buffer. Pressing 'q' or leaving the window closes the popup.
--- @param text table
M.display_text = function(text)
    if not M.display_buf or not vim.api.nvim_buf_is_valid(M.display_buf) then
        -- Create a new buffer for displaying the alignment
        M.display_buf = vim.api.nvim_create_buf(false, true)
    end
    -- Put the alignment text into the buffer
    vim.api.nvim_buf_set_lines(M.display_buf, 0, -1, false, text)

    -- Define the size and position of the popup window
    local width = M._get_alignment_width(text)
    local height = #text
    --- Distance from the left of the window to place the popup
    local left_margin = 3
    --- Try to put the popup slightly below the cursor, but don't put it past the end of the window.
    local cursor_r, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local current_window = vim.api.nvim_get_current_win()
    local winheight = vim.api.nvim_win_get_height(current_window)
    -- Calculate available space below cursor, accounting for scrolloff and status line
    local scrolloff = vim.o.scrolloff
    local win_height = math.min(winheight - scrolloff - 1, cursor_r + 1)

    -- Create the popup
    M.display_win = vim.api.nvim_open_win(M.display_buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = win_height,
        col = left_margin,
        border = 'rounded',
        style = 'minimal',
    })

    -- Pressing q or leaving the popup will close it
    vim.api.nvim_buf_set_keymap(M.display_buf, 'n', 'q', '<Cmd>bd!<CR>', { noremap = true, silent = true })
    vim.api.nvim_create_autocmd({ "WinLeave" }, {
        buffer = M.display_buf,
        callback = function()
            local win = M.display_win
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end
        end
    })
end

return M
