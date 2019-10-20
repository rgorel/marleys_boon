require 'lib/recipe_fetcher'

describe RecipeFetcher do
  let(:contentful_config) do
    {
      space_id: 'somespace',
      environment_id: 'master',
      access_token: 'verysecrettoken'
    }
  end

  let(:headers) { { 'Authorization' => "Bearer #{contentful_config[:access_token]}" } }

  let(:base_url) do
    "https://cdn.contentful.com/spaces/#{contentful_config[:space_id]}/environments/#{contentful_config[:environment_id]}"
  end

  subject(:fetcher) do
    described_class.new(contentful_config: contentful_config)
  end

  before do
    stub_request(:get, base_url + url_path)
      .with(headers: headers)
      .to_return(body: response_body, status: response_status)
  end

  let(:response_status) { 200 }
  let(:response_body) { nil }

  describe '#recipes' do
    subject { fetcher.recipes }
    let(:response_body) { fixture_file('get_entries.json') }
    let(:url_path) { '/entries?limit=1000&skip=0&content_type=recipe&include=2&select=fields.title%2Cfields.photo%2Csys.id' }

    context 'with default params' do

      it 'fetches recipes' do
        expect(subject).to be_success
        expect(subject.total).to eq 4
        expect(subject.recipes).to all be_a(RecipeFetcher::Recipe)
        expect(subject.photo_for(subject.recipes.first).id).to eq subject.recipes.first.photo_id
        expect(subject.recipes.map(&:title)).to contain_exactly(
          "Grilled Steak & Vegetables with Cilantro-Jalapeño Dressing",
          "Crispy Chicken and Rice\twith Peas & Arugula Salad",
          "White Cheddar Grilled Cheese with Cherry Preserves & Basil",
          "Tofu Saag Paneer with Buttery Toasted Pita"
        )
      end
    end

    context 'with custom params' do
      subject { fetcher.recipes(limit: 8, skip: 2) }
      let(:url_path) { '/entries?limit=8&skip=2&content_type=recipe&include=2&select=fields.title%2Cfields.photo%2Csys.id' }
      it { is_expected.to be_success }
    end

    context 'when request has failed' do
      let(:response_status) { 502 }
      let(:response_body) { nil }

      it 'raises error' do
        expect { subject }.to raise_error(RecipeFetcher::FetchFailedError)
      end
    end
  end

  describe '#recipe' do
    let(:id) { '437eO3ORCME46i02SeCW46' }
    subject { fetcher.recipe(id) }

    let(:url_path) { "/entries?sys.id=#{id}&include=2&content_type=recipe&select=fields.title%2Cfields.photo%2Cfields.description%2Cfields.tags%2Cfields.chef" }
    let(:response_body) { fixture_file('get_entry.json') }

    it 'fetches single recipe' do
      expect(subject).to be_success
      expect(subject.recipe.title).to eq "Crispy Chicken and Rice\twith Peas & Arugula Salad"
      expect(subject.photo).to be_a RecipeFetcher::Photo
      expect(subject.chef.name).to eq 'Jony Chives'
      expect(subject.tags.map(&:name)).to contain_exactly('gluten free', 'healthy')
    end

    context 'when recipe was not found' do
      let(:response_body) { fixture_file('get_entry_empty.json') }

      it 'responds with failure' do
        expect(subject).to be_failure
        expect(subject.error).to eq :not_found
      end
    end
  end
end
