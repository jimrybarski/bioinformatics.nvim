# bioinformatics.nvim

A collection of bioinformatics-related utilities for Neovim.

## Installation

Requires [biotools](https://github.com/jimrybarski/biotools) (install with `cargo install biotools`) for many functions.

With Lazy, add:

```
{ 'jimrybarski/bioinformatics.nvim' }
```

There are no configurable options and thus no setup is required.

## Bioinformatics functions

`dna_to_rna(dna_seq)` converts a DNA sequence to RNA.  
`rna_to_dna(rna_seq)` converts an RNA sequence to DNA.  
`length_biotools(seq)` computes the length of a sequence, ignoring dashes and spaces.  
`reverse_complement(dna_seq)` reverse complements a DNA sequence.  
`reverse_complement_biotools(dna_seq)` reverse complements a DNA sequence using biotools (which permits spaces and dashes).  
`gc_content(seq)` computes the GC content.  
`gc_content_biotools(seq)` computes the GC content, ignoring spaces and dashes.  
`set_pairwise_query(seq)` saves a sequence to be used as the top sequence in a pairwise alignment.  
`set_pairwise_subject(seq)` saves a sequence to be used as the bottom sequence in a pairwise alignment.  
`pairwise_align(mode, try_reverse_complement, hide_coords, gap_open_penalty, gap_extend_penalty)` performs a pairwise alignment with biotools and returns the aligned sequences with their alignment string.  

## Generic functions

`get_visual_selection()` gets the text of the current visual selection.  
`search_for_string(needle)` initiates a search for the string `needle`.  
`display_text(text)` opens a popup with a pairwise alignment or sequence statistics. Close with 'q' or by leaving the popup.

## Examples

Generating, pasting and searching for a reverse complement:
![Generating, pasting and searching for a reverse complement](casts/rc.gif)  

Performing pairwise alignments:
![Performing pairwise alignments](casts/pairwise.gif)  

Length and GC content:
![Computing length and GC content](casts/stats.gif)  

## Example config

bioinformatics.nvim is just a library of functions, with no keymaps set out of the box. You'll need to string these
functions together and define your own keymaps to make use of it. Below is the config I find useful in my own workflow. 
Note that this requires [rcarriga/nvim-notify](https://github.com/rcarriga/nvim-notify).

```lua
bio = require("bioinformatics")

-- save the current visual selection as the top sequence in a pairwise alignment, to be performed later
function set_query_visual()
    local seq = bio.get_visual_selection()
    bio.set_pairwise_query(seq)
end

-- save the current visual selection as the bottom sequence in a pairwise alignment, then perform the alignment
function set_subject_visual_and_align()
    local seq = bio.get_visual_selection()
    bio.set_pairwise_subject(seq)
    local alignment = bio.pairwise_align()
    bio.display_text(alignment)
end

-- save the text under the cursor as the top sequence in a pairwise alignment, to be performed later
function set_query_current_word()
    local seq = vim.fn.expand("<cword>")
    bio.set_pairwise_query(seq)
end

-- save the text under the cursor as the bottom sequence in a pairwise alignment, to be performed later
function set_subject_current_word()
    local seq = vim.fn.expand("<cword>")
    bio.set_pairwise_subject(seq)
end

-- save the current visual selection as the bottom sequence in a pairwise alignment, then perform the alignment
function set_subject_current_word_and_align()
    local seq = vim.fn.expand("<cword>")
    bio.set_pairwise_subject(seq)
    local alignment = bio.pairwise_align()
    bio.display_text(alignment)
end

-- show the length and GC content of the current visual selection
function popup_stats()
    local seq = bio.get_visual_selection()
    local gc_content = bio.gc_content_biotools(seq)
    local length = bio.length_biotools(seq)
    local text = string.format("GC: %.6f\nLen: %d bp", gc_content, length)
    vim.notify(text)
end

-- show the length and GC content of the text under the cursor
function popup_stats_current_word()
    local seq = vim.fn.expand("<cword>")
    local gc_content = bio.gc_content_biotools(seq)
    local length = bio.length_biotools(seq)
    local text = string.format("GC: %.6f\nLen: %d bp", gc_content, length)
    vim.notify(text)
end

-- search for the reverse complement of the text under the cursor
function search_for_rc_current_word()
    local seq = vim.fn.expand("<cword>")
    local revcomp = bio.reverse_complement_biotools(seq)
    bio.search_for_string(revcomp)
end

-- search for the text under the cursor
-- this is distinct from `*` as it will find the text even if it's a substring
-- frankly I don't understand why this isn't something provided out of the box by neovim
function search_for_current_word()
    local seq = vim.fn.expand("<cword>")
    bio.search_for_string(seq)
end

-- compute the reverse complement of the text under the cursor and store it in the clipboard register
function put_rc_in_register()
    local seq = vim.fn.expand("<cword>")
    local revcomp = bio.reverse_complement_biotools(seq)
    vim.fn.setreg('+', revcomp, "l")
end

-- To perform pairwise alignments, put the cursor over the first sequence you want to align (or visually select it)
-- and press `ba`. Then put the cursor over the other sequence you want to align (or visually select it) and press `bb`.
-- The alignment will immediately pop up. You can close the popup with `q`, or you can manipulate it like regular text 
-- for use elsewhere. Subsequent uses of `bb` will align other sequences to the first one that was selected with `ba`.
vim.keymap.set('n', '<leader>ba', set_query_current_word, { noremap = true, silent = true })
vim.keymap.set('v', '<leader>ba', set_query_visual, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>bb', set_subject_current_word_and_align, { noremap = true, silent = true })
vim.keymap.set('v', '<leader>bb', set_subject_visual_and_align, { noremap = true, silent = true })

-- Show the GC content and length of the current word or visual selection
vim.keymap.set('n', '<leader>bs', popup_stats_current_word, { noremap = true, silent = true })
vim.keymap.set('v', '<leader>bs', popup_stats, { noremap = true, silent = true })

-- Search for the reverse complement of the word under the cursor
vim.keymap.set('n', '<leader>brs', search_for_rc_current_word, { noremap = true, silent = true })

-- Copy the reverse complement of the current word to the clipboard register
vim.keymap.set('n', '<leader>bry', put_rc_in_register, { noremap = true, silent = true })
```

## License

[MIT](LICENSE)
