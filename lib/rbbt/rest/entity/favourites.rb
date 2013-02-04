module EntityRESTHelpers

  #{{{ Entities 

  def favourite_entities
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

  def add_favourite_entity(entity)
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

  def remove_favourite_entity(entity)
    raise "You need to login to have favourites" unless authorized?

    entity_type = entity.base_type
    dir = Path.setup(File.join(settings.favourites_dir, user))

    if (file = dir[entity_type]).exists?
      entities = Annotated.load_tsv(TSV.open(file))
      entities -= [entity]
      if entities.any?
        Open.write(file, Annotated.tsv(entities.uniq, :all).to_s)
      else
        FileUtils.rm file
      end
    end
  end

  #{{{ Entity Lists

  def favourite_entity_lists
    raise "You need to login to have favourites" unless authorized?

    dir = Path.setup(File.join(settings.favourite_lists_dir, user))
    favourites = {}
    dir.glob('**').each do |file|
      type = File.basename(file)
      lists = Open.read(file).split("\n")
      favourites[type] = lists
    end
    favourites
  end

  def add_favourite_entity_list(entity_type, list)
    raise "You need to login to have favourites" unless authorized?

    dir = Path.setup(File.join(settings.favourite_lists_dir, user))

    if (file = dir[entity_type]).exists?
      lists = Open.read(file).split("\n")
      lists << list
      Open.write(file, lists * "\n")
    else
      lists = [list]
      Open.write(file, lists * "\n")
    end
  end

  def remove_favourite_entity_list(entity_type, list)
    raise "You need to login to have favourites" unless authorized?

    dir = Path.setup(File.join(settings.favourite_lists_dir, user))

    if (file = dir[entity_type]).exists?
      lists = Open.read(file).split("\n")
      lists -= [list]
      if lists.any?
        Open.write(file, lists * "\n")
      else
        FileUtils.rm file
      end
    end
  end

end
