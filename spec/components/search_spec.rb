# frozen_string_literal: true

require 'rails_helper'

describe Search do

  fab!(:user) { Fabricate(:user) }
  fab!(:staff_user) { Fabricate(:admin) }
  fab!(:tag) { Fabricate(:tag, name: "deal-is-closed") }
  fab!(:tag1) { Fabricate(:tag, name: "deal-is-open") }
  fab!(:tag2) { Fabricate(:tag, name: "deal-is-everygreen") }

  before do
    SearchIndexer.enable
    SiteSetting.tagging_enabled = true
    SiteSetting.tag_group_action_enabled = true
  end

  context 'Advanced search' do
    fab!(:tag_group) { Fabricate(:tag_group, tags: [tag, tag1, tag2], name: 'Deal Status') }
    let(:post) { Fabricate(:post) }
    let(:post1) { Fabricate(:post) }
    let(:post2) { Fabricate(:post) }
    let(:topic) { post.topic }
    let(:topic1) { post1.topic }
    let(:topic2) { post2.topic }

    it 'can find by notInTagGroup' do
      topic.tags = [tag, tag1, tag2]
      topic1.tags = [tag1, tag2]
      topic2.tags = []

      expect(Search.execute('notInTagGroup:Deal_Status', guardian: Guardian.new(staff_user)).posts.length).to eq(1)

      topic.tags = []

      expect(Search.execute('notInTagGroup:Deal_Status', guardian: Guardian.new(staff_user)).posts.length).to eq(2)
    end

    it 'logic is not applied if tagging_enabled is false' do
      SiteSetting.tagging_enabled = false

      topic.tags = [tag, tag1, tag2]
      topic1.tags = [tag1, tag2]
      topic2.tags = []

      expect(Search.execute('notInTagGroup:Deal_Status', guardian: Guardian.new(staff_user)).posts.length).to eq(3)
    end

    it 'logic is not applied if tag_group_name is wrong' do
      topic.tags = [tag, tag1, tag2]
      topic1.tags = [tag1, tag2]
      topic2.tags = []

      expect(Search.execute('notInTagGroup:No_Deal_Status', guardian: Guardian.new(staff_user)).posts.length).to eq(3)
    end
  end
end
