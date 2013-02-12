module Sinatra
  module RbbtMiscHelpers
    def OR_matrices(m1, m2)
      samples = m1.fields
      new = TSV.setup({}, :key_field => "Ensembl Gene ID", :fields => samples)

      m1.each do |gene, values|
        new[gene] = values
      end

      m2.each do |gene, values|
        if new.include? gene
          new[gene] = new[gene].zip(values).collect do |old, new|
            case
            when old == new
              old
            else
              "TRUE"
            end
          end
        else
          new[gene] = values
        end
      end

      new
    end
  end
end
