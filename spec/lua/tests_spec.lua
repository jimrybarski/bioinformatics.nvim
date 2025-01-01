local bio = require("bioinformatics")

describe('bioinformatics.nvim', function()
       it('should calculate GC content correctly', function()
           -- setup your test
           local result = bio.gc_content("ACGC")
           -- perform assertions
           assert.are.equal(0.75, result)
       end)
   end)
