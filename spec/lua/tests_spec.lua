local bio = require("bioinformatics")

describe('bioinformatics.nvim', function()
    describe('dna_to_rna', function()
        it('converts DNA sequence to RNA correctly', function()
            assert.are.equal("AUCG", bio.dna_to_rna("ATCG"))
        end)

        it('handles empty string', function()
            assert.are.equal("", bio.dna_to_rna(""))
        end)

        it('converts only T to U', function()
            assert.are.equal("AAUCGGU", bio.dna_to_rna("AATCGGT"))
        end)
    end)

    describe('rna_to_dna', function()
        it('converts RNA sequence to DNA correctly', function()
            assert.are.equal("ATCG", bio.rna_to_dna("AUCG"))
        end)

        it('handles empty string', function()
            assert.are.equal("", bio.rna_to_dna(""))
        end)

        it('converts only U to T', function()
            assert.are.equal("AATCGGT", bio.rna_to_dna("AAUCGGU"))
        end)
    end)

    describe('length', function()
        it('calculates length of simple sequence', function()
            assert.are.equal(4, bio.length("ATCG"))
        end)

        it('ignores whitespace and dashes', function()
            assert.are.equal(4, bio.length("AT CG"))
            assert.are.equal(4, bio.length("AT-CG"))
            assert.are.equal(4, bio.length("A T-C G"))
        end)

        it('handles empty string', function()
            assert.are.equal(0, bio.length(""))
        end)

        it('handles string with only whitespace and dashes', function()
            assert.are.equal(0, bio.length(" - - "))
        end)
    end)

    describe('reverse_complement', function()
        it('calculates reverse complement correctly', function()
            assert.are.equal("CGAT", bio.reverse_complement("ATCG"))
        end)

        it('handles all nucleotides', function()
            assert.are.equal("TACG", bio.reverse_complement("CGTA"))
        end)

        it('handles empty string', function()
            assert.are.equal("", bio.reverse_complement(""))
        end)

        it('handles single nucleotide', function()
            assert.are.equal("T", bio.reverse_complement("A"))
            assert.are.equal("A", bio.reverse_complement("T"))
            assert.are.equal("G", bio.reverse_complement("C"))
            assert.are.equal("C", bio.reverse_complement("G"))
        end)
    end)

    describe('gc_content', function()
        it('calculates GC content correctly', function()
            assert.are.equal(0.75, bio.gc_content("ACGC"))
        end)

        it('handles 100% GC content', function()
            assert.are.equal(1.0, bio.gc_content("GCGC"))
        end)

        it('handles 0% GC content', function()
            assert.are.equal(0.0, bio.gc_content("ATAT"))
        end)

        it('handles mixed case', function()
            assert.are.equal(0.5, bio.gc_content("atgc"))
            assert.are.equal(0.5, bio.gc_content("AtGc"))
        end)

        it('ignores whitespace and dashes', function()
            assert.are.equal(0.5, bio.gc_content("AT GC"))
            assert.are.equal(0.5, bio.gc_content("AT-GC"))
        end)

        it('handles empty string', function()
            assert.are.equal(0, bio.gc_content(""))
        end)

        it('handles string with only whitespace and dashes', function()
            assert.are.equal(0, bio.gc_content(" - - "))
        end)

        it('works with RNA sequences', function()
            assert.are.equal(0.5, bio.gc_content("AUGC"))
        end)
    end)
end)
