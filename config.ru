require 'rbbt/entity'
require 'rbbt/entity/genomic_mutation'
require 'rbbt/entity/mutated_isoform'
require 'rbbt/entity/gene'
require 'rbbt/sources/string'
require 'rbbt/sources/pina'
require 'rbbt/sources/go'
require 'rbbt/sources/kegg'
require 'rbbt/sources/InterPro'
require 'rbbt/sources/pfam'
require 'rbbt/sources/tfacts'



require './lib/rbbt/rest/main'
require './lib/rbbt/rest/workflow'
require './lib/rbbt/rest/entity'
require './lib/rbbt/rest/entity/rest'


[MutatedIsoform, GenomicMutation, Gene, Protein, PMID, InterProDomain, KeggPathway, GOTerm, PfamDomain].each do |mod|
  mod.module_eval do
    include Entity::REST
  end
end

Workflow.require_workflow "Sequence"
Workflow.require_workflow "Enrichment"
WorkflowREST.add_workflow Sequence
WorkflowREST.add_workflow Enrichment

use RbbtREST
use WorkflowREST

require 'zurb-foundation'
require 'modular-scale'

RbbtRESTHelpers.add_sass_load_path "#{Gem.loaded_specs['compass'].full_gem_path}/frameworks/compass/stylesheets"
RbbtRESTHelpers.add_sass_load_path "#{Gem.loaded_specs['zurb-foundation'].full_gem_path}/scss/" 
RbbtRESTHelpers.add_sass_load_path "#{Gem.loaded_specs['modular-scale'].full_gem_path}/stylesheets/" 
RbbtRESTHelpers.javascript_resources << Path.setup("#{Gem.loaded_specs['zurb-foundation'].full_gem_path}/vendor/assets/javascripts/foundation")

gene = Gene.setup("SF3B1", "Associated Gene Name", "Hsa")

run EntityREST

