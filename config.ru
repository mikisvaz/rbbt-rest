$LOAD_PATH.unshift(File.join(ENV['HOME'], 'git/rbbt-util/lib'))
$LOAD_PATH.unshift(File.join(ENV['HOME'], 'git/rbbt-text/lib'))
$LOAD_PATH.unshift(File.join(ENV['HOME'], 'git/rbbt-sources/lib'))
$LOAD_PATH.unshift(File.join(ENV['HOME'], 'git/rbbt-phgx/lib'))
$LOAD_PATH.unshift(File.join(ENV['HOME'], 'git/rbbt-GE/lib'))
$LOAD_PATH.unshift(File.join(ENV['HOME'], 'git/rbbt-views/lib'))
$LOAD_PATH.unshift(File.join(ENV['HOME'], 'git/rbbt-entities/lib'))
$LOAD_PATH.unshift(File.join(ENV['HOME'], 'git/rbbt-study/lib'))
$LOAD_PATH.unshift(File.join(ENV['HOME'], 'git/rbbt-rest/lib'))

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

require 'zurb-foundation'
require 'modular-scale'

require './lib/rbbt/rest/main'
require './lib/rbbt/rest/entity'
require './lib/rbbt/rest/workflow'
require './lib/rbbt/rest/file_server'
require './lib/rbbt/rest/helpers'

Workflow.require_workflow "Sequence"
Workflow.require_workflow "Enrichment"
#Workflow.require_workflow "./workflow.rb"

class MyApps < Sinatra::Base
  register Sinatra::RbbtRESTMain
  register Sinatra::RbbtRESTEntity
  register Sinatra::RbbtRESTWorkflow
  register Sinatra::RbbtRESTFileServer

  helpers Sinatra::RbbtMiscHelpers

  local_var = Rbbt.var.find(:lib)
  set :cache_dir, local_var.sinatra.cache.find 
  set :file_dir, local_var.sinatra.files.find 
  set :favourites_dir, local_var.sinatra.favourites.find 
  set :favourite_lists_dir, local_var.sinatra.favourite_lists

  finder = Finder.new
  Thread.new do
    if false and production?
      finder.add_instance(KEGG.pathways, :grep => "^hsa", :fields => ["Pathway Name"], :namespace => "Hsa/jun2011")
      finder.add_instance(Organism.lexicon("Hsa/jun2011"), :persist => true, :namespace => "Hsa/jun2011", :grep => "^LRG_", :invert_grep => true)
    end
  end

  set :finder, finder

  add_workflow Sequence
  add_workflow Enrichment

  add_sass_load_path "#{Gem.loaded_specs['compass'].full_gem_path}/frameworks/compass/stylesheets"
  add_sass_load_path "#{Gem.loaded_specs['zurb-foundation'].full_gem_path}/scss/" 
  add_sass_load_path "#{Gem.loaded_specs['modular-scale'].full_gem_path}/stylesheets/" 

  RbbtRESTHelpers.javascript_resources << Path.setup("#{Gem.loaded_specs['zurb-foundation'].full_gem_path}/vendor/assets/javascripts/foundation")

  use Rack::Session::Cookie, :key => 'rack.session',
    :path => '/',
    :expire_after => 2592000,
    :secret => 'StudyExplorer secret!!'

  helpers do

    def user_studies
      if $user_studies.nil?
        $user_studies = {}
        groups = Rbbt.etc.web_user_groups.exists? ? (Rbbt.etc.web_user_groups.yaml || {}) : {}
        Study.studies.each do |study|
          next if study.metadata.nil? or study.metadata[:hide]
          users = study.users.collect{|user| groups.include?(user)? groups[user] : user}.flatten.uniq
          users.each do |user|
            $user_studies[user.to_sym] ||= []
            $user_studies[user.to_sym] << study
          end
        end
        $user_studies.extend IndiferentHash
      end
      $user_studies
    end

  end

  before do
    parts = request.path_info.split "/"
    parts.shift
    case
    when parts[0..1] == %w(entity Study)
      study = parts[2]
    when parts[0..1] == %w(entity_action Study)
      study = parts[3]
    else
      study = nil
    end

    authorize! if study

    if study and ( not user_studies.include? user or not user_studies[user].include? study )
      halt 401, "We are sorry, but it seems that you do not have credentials to explore this study: #{ study }"
    end
  end

  get '/studies' do
    template_render('studies')
  end
end

#{{{ Configure Entities

require 'rbbt/entity/study'
require 'rbbt/entity/study/genotypes'
require 'rbbt/entity/study/cnv'

Entity.entity_list_cache = Rbbt.var.find(:lib).sinatra.entity_lists

[Study, Sample, MutatedIsoform, GenomicMutation, CNV, Gene, Protein, PMID, InterProDomain, KeggPathway, GOTerm, PfamDomain, NCINaturePathway, NCIReactomePathway, NCIReactomePathway].each do |mod|
  mod.module_eval do
    include Entity::REST
  end
end

$annotation_repo = Rbbt.var.find(:lib).cache.annotation_repo.find
module Study
  %w(affected_genes damaged_genes recurrent_genes all_mutations relevant_mutations damaging_mutations).each do |method|
    persist method.to_sym, :annotations, :annotation_repo => $annotation_repo
  end

  persist :gene_sample_matrix, :tsv

  persist :samples_with_gene_affected, :marshal
end

#Study.instance_variable_set("@study_dir", "/home/mvazquezg/tmp/studies_test")


#{{{ RUN

$title = "Genome Scout"
use Rack::Deflater
run MyApps
