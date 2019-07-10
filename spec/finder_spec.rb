require 'spec_helper'

describe Louisville::Extensions::Finder do

  class FinderUser < ActiveRecord::Base
    self.table_name = :users

    include Louisville::Slugger

    slug :name, :finder => true
  end

  class FindeerUser < FinderUser

  end

  class FinderHistoryUser < ActiveRecord::Base
    self.table_name = :users
    include Louisville::Slugger

    slug :name, :finder => true, :history => true
  end


  it 'should allow a model to be found via its slug' do
    f = FinderUser.new
    f.name = 'harold'
    expect(f.save).to eq(true)

    expect(FinderUser.find('harold')).to eq(f)
  end

  it 'should blow up when nothing can be found' do
    expect{
      FinderUser.find('dajlsflj290rjodsals')
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'should be fine with inhertance' do
    f = FindeerUser.new
    f.name = 'harmon'
    expect(f.save).to eq(true)

    expect(FindeerUser.find('harmon')).to eq(f)
  end

  it 'should raise an error with history enabled' do
    f = FinderHistoryUser.new
    f.name = 'happ'
    expect(f.save).to eq(true)

    f.reload
    f.name = 'happy'
    expect(f.save).to eq(true)

    expect(f.slug).to eq('happy')
    expect(
      Louisville::Slug.where(:sluggable_type => 'FinderHistoryUser', :sluggable_id => f.id).count
    ).to eq(1)

    expect(FinderHistoryUser.find('happ')).to eq(f)
    expect(FinderHistoryUser.find('happy')).to eq(f)

    expect{
      FinderHistoryUser.find('harvey')
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  context "pass-through" do
    let(:user1) { FinderUser.create! name: "Marco" }
    let(:user2) { FinderUser.create! name: "Polo" }

    after { FinderUser.delete_all }

    it "uses the original Rails logic for numerical ids" do
      expect(FinderUser.find(user1.id)).to eq user1
    end

    it "uses the original Rails logic for multiple ids" do
      expect(FinderUser.find(user1.id, user2.id)).to match_array [user1, user2]

      expect { FinderUser.find(user1.id, FinderUser.maximum(:id) + 1) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it "uses the original Rails logic for an array of ids" do
      expect(FinderUser.find([user1.id, user2.id])).to match_array [user1, user2]

      expect { FinderUser.find([user1.id, FinderUser.maximum(:id) + 1]) }
        .to raise_error(ActiveRecord::RecordNotFound)

    end
  end

end
