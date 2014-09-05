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

    if (file = dir[entity_type].find).exists?
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

    if (file = dir[entity_type].find).exists?
      lists = Open.read(file.find).split("\n")
      lists << list
      Open.write(file, lists.uniq * "\n")
    else
      lists = [list]
      Open.write(file, lists * "\n")
    end
  end

  def remove_favourite_entity_list(entity_type, list)
    raise "You need to login to have favourites" unless authorized?

    dir = Path.setup(File.join(settings.favourite_lists_dir, user))

    if (file = dir[entity_type].find).exists?
      lists = Open.read(file).split("\n")
      lists -= [list]
      if lists.any?
        Open.write(file, lists * "\n")
      else
        FileUtils.rm file
      end
    end
  end

  #{{{ Entity Maps

  def favourite_entity_maps
    raise "You need to login to have favourites" unless authorized?

    dir = Path.setup(File.join(settings.favourite_maps_dir, user))
    favourites = {}
    dir.find.glob('*').each do |type_dir|
      type = File.basename(type_dir)
      Path.setup(type_dir).glob('*').each do |file|
        column = File.basename(file).gsub('--', '/')
        maps = Open.read(file).split("\n")
        favourites[type] ||= {}
        favourites[type][column] = maps
      end
    end
    favourites
  end

  def add_favourite_entity_map(entity_type, column, map)
    raise "You need to login to have favourites" unless authorized?

    column = column.gsub('/', '--')
    dir = Path.setup(File.join(settings.favourite_maps_dir, user))

    if (file = dir[entity_type][column]).exists?
      maps = Open.read(file).split("\n")
      maps << map
      maps.uniq!
      Open.write(file, maps.uniq * "\n")
    else
      maps = [map]
      Open.write(file, maps * "\n")
    end
  end

  def remove_favourite_entity_map(entity_type, column, map)
    raise "You need to login to have favourites" unless authorized?

    column = column.gsub('/', '--')

    dir = Path.setup(File.join(settings.favourite_maps_dir, user))

    if (file = dir[entity_type][column]).exists?
      maps = Open.read(file).split("\n")
      maps -= [map]
      if maps.any?
        Open.write(file, maps * "\n")
      else
        FileUtils.rm file
      end
    end
  end


end
