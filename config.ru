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

require 'rbbt/entity/study'
require 'rbbt/entity/study/genotypes'

require 'zurb-foundation'
require 'modular-scale'

Workflow.require_workflow "Sequence"
Workflow.require_workflow "Enrichment"
WorkflowREST.add_workflow Sequence
WorkflowREST.add_workflow Enrichment


RbbtRESTHelpers.add_sass_load_path "#{Gem.loaded_specs['compass'].full_gem_path}/frameworks/compass/stylesheets"
RbbtRESTHelpers.add_sass_load_path "#{Gem.loaded_specs['zurb-foundation'].full_gem_path}/scss/" 
RbbtRESTHelpers.add_sass_load_path "#{Gem.loaded_specs['modular-scale'].full_gem_path}/stylesheets/" 
RbbtRESTHelpers.javascript_resources << Path.setup("#{Gem.loaded_specs['zurb-foundation'].full_gem_path}/vendor/assets/javascripts/foundation")


#{{{ Configure Entities

[Study, MutatedIsoform, GenomicMutation, Gene, Protein, PMID, InterProDomain, KeggPathway, GOTerm, PfamDomain].each do |mod|
  mod.module_eval do
    include Entity::REST
  end
end

$annotation_repo = Rbbt.var.cache.annotation_repo.find
module Study
  %w(affected_genes damaged_genes recurrent_genes all_mutations relevant_mutations damaging_mutations).each do |method|
    persist method.to_sym, :annotations, :annotation_repo => $annotation_repo
  end
end

#{{{ Protect Studies


use Rack::Session::Cookie, :key => 'rack.session',
  :path => '/',
  :expire_after => 2592000,
  :secret => 'StudyExplorer secret!!'

EntityREST.helpers do

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

EntityREST.before do
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

EntityREST.get '/studies' do
  template_render('studies')
end

#{{{ RUN

Study.instance_variable_set("@study_dir", "/home/mvazquezg/tmp/studies_test")

use RbbtREST
use WorkflowREST
run EntityREST

