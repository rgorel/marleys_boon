require 'sinatra/base'
require 'sinatra/custom_logger'
require 'logger'
require 'erb'

require_relative 'lib/recipe_fetcher'

class MarleysBoonApp < Sinatra::Application
  helpers Sinatra::CustomLogger

  set :contentful_config, {
    space_id: ENV.fetch('MB_CONTENTFUL_SPACE_ID'),
    environment_id: ENV.fetch('MB_CONTENTFUL_ENVIRONMENT_ID'),
    access_token: ENV.fetch('MB_CONTENTFUL_ACCESS_TOKEN'),
  }

  set :recipes_per_page, 5

  set :logger, Logger.new(STDOUT, Logger::DEBUG)

  not_found { erb :not_found }
  error { erb :server_error }

  def self.recipe_fetcher
    @recipe_fetcher ||= RecipeFetcher.new(
      logger: logger,
      contentful_config: contentful_config
    )
  end

  get '/' do
    skip = params['skip'] || 1
    result = self.class.recipe_fetcher.recipes(skip: skip, limit: settings.recipes_per_page)
    erb :index, locals: { result: result }
  end

  get '/:id' do
    result = self.class.recipe_fetcher.recipe(params['id'])

    if result.failure? && result.error == :not_found
      not_found
    else
      erb :show, locals: { result: result }
    end
  end
end