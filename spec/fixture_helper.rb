module FixtureHelper
  def fixture_file(name)
    File.new(SPEC_DIR + "/fixtures/#{name}")
  end
end

RSpec.configure do |c|
  c.include FixtureHelper
end
