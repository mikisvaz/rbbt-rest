require 'zurb-foundation'
require 'modular-scale'

require 'sinatra'

require 'rbbt'
require 'rbbt/rest/main'
require 'rbbt/rest/entity'
require 'rbbt/rest/workflow'
require 'rbbt/rest/file_server'
require 'rbbt/rest/helpers'

YAML::ENGINE.yamler = 'syck' if defined? YAML::ENGINE and YAML::ENGINE.respond_to? :yamler

class RbbtRest < Sinatra::Base
  
  #{{{ MODULES AND HELPERS
  register Sinatra::RbbtRESTMain
  register Sinatra::RbbtRESTEntity
  register Sinatra::RbbtRESTWorkflow
  register Sinatra::RbbtRESTFileServer
  helpers Sinatra::RbbtMiscHelpers

  #{{{ DIRECTORIES
  local_var = Rbbt.var.find(:lib)
  set :cache_dir           , local_var.sinatra.cache.find
  set :file_dir            , local_var.sinatra.files.find
  set :favourites_dir      , local_var.sinatra.favourites.find
  set :favourite_lists_dir , local_var.sinatra.favourite_lists

  #{{{ SESSIONS
  use Rack::Session::Cookie, :key => 'rack.session',
    :path => '/',
    :expire_after => 2592000,
    :secret => 'StudyExplorer secret!!'

  #{{{ FOUNDATION RESOURCES
  add_sass_load_path "#{Gem.loaded_specs['compass'].full_gem_path}/frameworks/compass/stylesheets"
  add_sass_load_path "#{Gem.loaded_specs['zurb-foundation'].full_gem_path}/scss/" 
  add_sass_load_path "#{Gem.loaded_specs['modular-scale'].full_gem_path}/stylesheets/" 
  RbbtRESTHelpers.javascript_resources << Path.setup("#{Gem.loaded_specs['zurb-foundation'].full_gem_path}/js/foundation")
  RbbtRESTHelpers.javascript_resources << Path.setup("#{Gem.loaded_specs['zurb-foundation'].full_gem_path}/js/vendor")
end

#{{{ WORKFLOWS

if Rbbt.etc.workflows.find(:lib).exists?
  class RbbtRest
    Rbbt.etc.workflows.find(:lib).read.split("\n").each do |workflow|
      Workflow.require_workflow workflow
      add_workflow Kernel.const_get(workflow), true
    end
  end
end

#{{{ ENTITIES

require 'rbbt/entity'
require 'rbbt/entity/genomic_mutation'
require 'rbbt/entity/snp'
require 'rbbt/entity/mutated_isoform'
require 'rbbt/entity/chromosome_range'
require 'rbbt/entity/study'
require 'rbbt/entity/study/genotypes'
require 'rbbt/entity/study/cnv'
require 'rbbt/entity/study/methylation'

require 'rbbt/sources/string'
require 'rbbt/sources/pina'
require 'rbbt/sources/go'
require 'rbbt/sources/kegg'
require 'rbbt/sources/InterPro'
require 'rbbt/sources/pfam'
require 'rbbt/sources/tfacts'

$annotation_repo = Rbbt.var.find(:lib).cache.annotation_repo.find

Entity.entity_list_cache = Rbbt.var.find(:lib).sinatra.entity_lists

[Study, Sample, MutatedIsoform, GenomicMutation, SNP, ChromosomeRange, CNV, Gene, Protein, PMID, InterProDomain, KeggPathway, GOTerm, PfamDomain, NCINaturePathway, NCIReactomePathway, NCIReactomePathway].each do |mod|
  mod.module_eval do
    include Entity::REST
  end
end

#{{{ FINDER
class RbbtRest
  finder = Finder.new
  if production?
   Thread.new do
    #finder.add_instance(KEGG.pathways, :grep => "^hsa", :fields => ["Pathway Name"], :namespace => "Hsa/jun2011")
    #finder.add_instance(Organism.lexicon("Hsa/jun2011"), :persist => true, :namespace => "Hsa/jun2011", :grep => "^LRG_", :invert_grep => true)
   end
  end
  set :finder, finder
end

#{{{ RUN
$title = "RbbtRest"

use Rack::Deflater
run RbbtRest
