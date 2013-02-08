require 'rbbt/mutation/oncodriveFM'
require 'rbbt/entity/study'
require 'rbbt/entity/study/genotypes'

module GenomeScout
  extend Workflow
  input :genes, :array, "Ensembl Gene ID"
  input :dataset, :string, "GEO dataset or series code"
  input :condition, :string, "Condition to color", nil
  input :organism, :string, "Organism code", "Hsa"
  task :geo_expression => :tsv do |genes,dataset,condition,organism|
    dataset_info = GEO[dataset]["info.yaml"].yaml

    platform = dataset_info[:platform]

    codes = GEO[platform].codes.tsv :type => :double
    platform_probe_id = codes.key_field

    if Organism.known_ids(organism).include? platform_probe_id
      genes2probes = Organism.identifiers(organism).tsv :key_field => genes.format, :fields => [platform_probe_id], :persist => true, :type => :flat
    else
      genes2probes = TSV.setup(genes, :key_field => genes.format, :fields => [], :namespace => genes.organism, :type => :double)
      genes2probes.identifiers = Organism.identifiers(organism).find
      genes2probes.attach codes, :fields => [:key]
    end

    expression_data = GEO[dataset].values.tsv :type => :list, :cast => :to_f, :namespace => organism

    gene_expression_values = Misc.process_to_hash(genes.name){|names| genes.collect{|gene| Misc.zip_fields(expression_data.values_at(*(genes2probes[gene] || []).flatten).compact ).collect{|value_lists| Misc.mean value_lists }} }

    gene_expression_values.delete_if{|gene, values| (values || []).flatten.compact.empty?}
    TSV.setup(gene_expression_values, :key_field => "Probe ID", :fields => expression_data.fields, :type => :list, :cast => :to_f)

    if dataset_info.include?(:subsets)
      if condition and not condition.empty?
        subsets = dataset_info[:subsets]
        value_lists = subsets[condition]

        sample_features = expression_data.fields.collect do |field| 
          value_lists.select{|value,list| list.include?(field)}.first.first
        end

        colors, leyend = Misc.colors_for(sample_features)
        set_info :colors, 'c(' + colors.collect{|c| "\"#{c}\"" } * ", " + ")"
        set_info :leyend, leyend
      end
    else 
      sample_info = dataset_info[:sample_info]

      gene_expression_values.fields = gene_expression_values.fields.collect{|field| sample_info[field][:title] + " (#{ field })"}

      set_info :add_to_height, gene_expression_values.fields.collect{|f| f.length}.max
    end

    gene_expression_values
  end


  input :study, :string, "Study code"
  task :oncodriveFM => :tsv do |study|
    Study.setup(study)
    tsv, input, config = OncodriveFM.process_cohort(study.cohort, true)
    Open.write(file("input"), input)
    Open.write(file("config"), config)
    tsv.namespace = study.metadata[:organism]
    tsv
  end
end
