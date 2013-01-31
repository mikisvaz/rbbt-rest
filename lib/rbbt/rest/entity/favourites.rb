module EntityRESTHelpers

  def favourites
    raise "You need to login to have favourites" unless authorized?

    dir = Path.setup(File.join(settings.favourites_dir, user))
    favourites = {}
    dir.glob('**').each do |file|
      type = File.basename(file)
      entities = Annotated.load_tsv(TSV.open(file))
      favourites[type] = entities
    end
    favourites
  end

  def add_favourite(entity)
    raise "You need to login to have favourites" unless authorized?

    entity_type = entity.base_type
    dir = Path.setup(File.join(settings.favourites_dir, user))

    if (file = dir[entity_type]).exists?
      entities = Annotated.load_tsv(TSV.open(file))
      entities << entity
      Open.write(file, Annotated.tsv(entities.uniq, :all).to_s)
    else
      entities = [entity]
      Open.write(file, Annotated.tsv(entities, :all).to_s)
    end
  end
end
