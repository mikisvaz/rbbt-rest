require 'rbbt/entity'
require 'rbbt/entity/genomic_mutation'
require 'rbbt/entity/mutated_isoform'
require 'rbbt/entity/gene'
require 'rbbt/sources/string'


require 'sinatra'

require './lib/rbbt/rest/main'
require './lib/rbbt/rest/workflow'
require './lib/rbbt/rest/entity'
require 'rbbt/workflow/rest/entity'


[MutatedIsoform, GenomicMutation, Gene].each do |mod|
  mod.module_eval do
    include Entity::REST
  end
end

Workflow.require_workflow "Sequence"
WorkflowREST.add_workflow Sequence
use WorkflowREST

use EntityREST

gene = Gene.setup("SF3B1", "Associated Gene Name", "Hsa")

Entity::REST.save_list("Gene", "SF3B1 interactors", gene.string_interactors)
run RbbtREST

