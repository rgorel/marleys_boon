require 'net/http'
require 'json'

class ContentfulAPI
  BASE_URL = 'https://cdn.contentful.com/spaces/%<space>s/environments/%<environment>s'.freeze

  Response = Struct.new(:code, :body) do
    def success?
      code.start_with?('2')
    end
  end

  def initialize(space_id:, environment_id:, access_token:, logger: Logger.new(IO::NULL))
    @space_id = space_id
    @base_url = format(BASE_URL, space: space_id, environment: environment_id)
    @environment_id = environment_id
    @access_token = access_token
    @logger = logger
  end

  def get(path, params)
    request(Net::HTTP::Get, url, params)
  end

  private

  attr_reader :base_url, :access_token, :logger

  def request(klass, path, params)
    uri = URI("#{base_url}/#{path}")
    uri.query = URI.encode_www_form(params)

    request_object = klass.new(uri)
    request_object['Authorization'] = "Bearer #{access_token}"

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request_object)
    end

    parsed_body = JSON.parse(response.body) if response.body

    Response.new(response.code, parsed_body).freeze
  end
end
