require_relative 'contentful_api'
require_relative 'result'

class RecipeFetcher
  FetchFailedError = Class.new(StandardError)

  NotFoundFailure = Result.Failure(:not_found)

  CollectionResult = Result.Success(:total, :skip, :limit, :recipes, :photos)
  SingleResult = Result.Success(:recipe, :photo, :tags, :chef)

  Recipe = Result.Model(:id, :title, :description)
  Photo = Result.Model(:title, :url)
  Tag = Result.Model(:name)
  Chef = Result.Model(:name)

  def initialize(logger: Logger.new(IO::NULL), contentful_config:)
    @contentful_api = ContentfulAPI.new(logger: logger, **contentful_config)
  end

  def recipes(skip: 0, limit: 1000)
    result = get_entries(
      limit: limit,
      skip: skip,
      content_type: 'recipe',
      include: 2,
      select: 'fields.title,fields.photo,sys.id'
    )

    recipes = result.body.fetch('items').map do |row|
      Recipe.new(
        id: row['sys'].fetch('id'),
        title: row['fields'].fetch('title')
      )
    end

    photos = result.body['includes'].fetch('Asset').map { |row| decorate_photo(row) }

    CollectionResult.new(
      total: result.body.fetch('total'),
      skip: result.body.fetch('skip'),
      limit: result.body.fetch('limit'),
      recipes: recipes,
      photos: photos
    )
  end

  def recipe(id)
    result = get_entries(
      'sys.id' => id,
      include: 2,
      select: 'fields.title,fields.photo,fields.description,fields.tags,fields.chef'
    )

    recipe = result.body.fetch('items').first&.then do |row|
      Recipe.new(
        id:  id,
        title: raw_recipe['fields'].fetch('title'),
        description: raw_recipe['fields'].fetch('description'),
      )
    end

    unless recipe
      return NotFoundFailure
    end

    photo = result.body.fetch('includes').fetch('Asset', []).first&.then do |row|
      decorate_photo(row)
    end

    entries = result.body.fetch('includes').fetch('Entry', [])

    tags = select_entries(entries, 'tag').map do |row|
      Tag.new(name: row['fields'].fetch('name'))
    end

    chef = select_entries(entries, 'chef').first&.then do |row|
      Chef.new(name: raw_chef['fields'].fetch('name'))
    end

    SingleResult.new(
      recipe: recipe,
      photo: photo,
      tags: tags,
      chef: chef
    )
  end

  private

  attr_reader :contentful_api

  def decorate_photo(row)
    Photo.new(
      title: row['fields'].fetch('title'),
      url: row.dig('fields', 'file').fetch('url')
    )
  end

  def select_entries(entries, content_type)
    entries.select do |row|
      row.dig('sys', 'contentType', 'sys').fetch('id') == content_type
    end
  end

  def get_entries(params)
    result = contentful_api.get('/entries', params)

    unless result.code.start_with?('2')
      raise FetchFailedError
    end

    result
  end
end
