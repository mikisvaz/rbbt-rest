require 'rbbt/entity'
require 'rbbt/entity/genomic_mutation'
require 'rbbt/entity/mutated_isoform'
require 'rbbt/entity/gene'
require 'rbbt/sources/string'


require 'sinatra'

require './lib/rbbt/rest/main'
require './lib/rbbt/rest/workflow'
require './lib/rbbt/rest/entity'
require './lib/rbbt/rest/entity/rest'


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

run RbbtREST

