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
`reverse_complement(dna_seq)` reverse complements a DNA sequence.
`gc_content(seq)` compute the GC content.
`set_pairwise_query(seq)` saves a sequence to be used as the top sequence in a pairwise alignment.
`set_pairwise_subject(seq)` saves a sequence to be used as the bottom sequence in a pairwise alignment.
`pairwise_align(mode, try_reverse_complement, hide_coords, gap_open_penalty, gap_extend_penalty)` performs a pairwise alignment and returns the aligned sequences with their alignment string
`display_alignment(alignment)` opens a popup with a pairwise alignment

## Generic functions

`get_visual_selection()` gets the text of the current visual selection.
`search_string(needle)` initiates a search for the string `needle`

## Example usage

```lua
bio = require("bioinformatics")

function set_query_visual() 
    local seq = bio.get_visual_selection()
    bio.set_pairwise_query(seq) 
end

function set_subject_visual() 
    local seq = bio.get_visual_selection()
    bio.set_pairwise_subject(seq)
end

function set_query_current_word()
    local seq = vim.fn.expand("<cword>")
    bio.set_pairwise_query(seq) 
end

function set_subject_current_word()
    local seq = vim.fn.expand("<cword>")
    bio.set_pairwise_subject(seq) 
end

function set_subject_current_word_and_align()
    local seq = vim.fn.expand("<cword>")
    bio.set_pairwise_subject(seq) 
    local alignment = bio.pairwise_align()
    bio.display_alignment(alignment)
end

vim.keymap.set('v', '<leader>bva', set_query_visual, { noremap = true, silent = true })
vim.keymap.set('v', '<leader>bvb', set_subject_visual, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>ba', set_query_current_word, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>bb', set_subject_current_word_and_align, { noremap = true, silent = true })
vim.keymap.set({"n", "v"}, '<leader>bp', bio.pairwise_align, { noremap = true, silent = true })
```

## License

[MIT](LICENSE)
