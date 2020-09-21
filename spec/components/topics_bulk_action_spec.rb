# frozen_string_literal: true

require 'rails_helper'

describe TopicsBulkAction do
  fab!(:tag) { Fabricate(:tag, name: "deal-is-closed") }
  fab!(:tag1) { Fabricate(:tag, name: "deal-is-open") }
  fab!(:tag2) { Fabricate(:tag, name: "deal-is-everygreen") }
  fab!(:tag_group) { Fabricate(:tag_group, tags: [tag, tag1, tag2], name: 'Deal Status') }
  fab!(:post) { Fabricate(:post) }
  fab!(:post1) { Fabricate(:post) }
  fab!(:post2) { Fabricate(:post) }
  let(:topic) { post.topic }
  let(:topic1) { post1.topic }
  let(:topic2) { post2.topic }
  let(:user) { Fabricate(:admin) }

  before do
    SiteSetting.tagging_enabled = true
    SiteSetting.tag_group_action_enabled = true
  end

  describe "closeDeal" do
    it "adds tag from site setting tga_bulk_action_tag_group_name to topics" do
      SiteSetting.tga_bulk_action_tag_group_name = "Deal Status"
      SiteSetting.tga_bulk_action_replace_tag_name = "deal-is-closed"

      topic.tags = [Fabricate(:tag, name: "super"), tag1]
      topic1.tags = [Fabricate(:tag, name: "hello"), tag1]

      TopicsBulkAction.new(user, [topic.id, topic1.id], { type: 'closeDeal' }).perform!

      topic.reload
      topic1.reload

      expect(topic.tags.map { |t| t.name }).to match_array(["super", SiteSetting.tga_bulk_action_replace_tag_name])
      expect(topic1.tags.map { |t| t.name }).to match_array(["hello", SiteSetting.tga_bulk_action_replace_tag_name])
    end

    it "wont perform action if tag specified in SiteSetting does not exists" do
      SiteSetting.tga_bulk_action_replace_tag_name = "not-allowed"
      SiteSetting.tga_bulk_action_tag_group_name = "Deal Status"

      topic.tags = [Fabricate(:tag, name: "super"), tag1]
      topic1.tags = [Fabricate(:tag, name: "hello"), tag1]

      TopicsBulkAction.new(user, [topic.id, topic1.id], { type: 'closeDeal' }).perform!

      topic.reload
      topic1.reload

      expect(topic.tags.map { |t| t.name }).to match_array(["super", tag1.name])
      expect(topic1.tags.map { |t| t.name }).to match_array(["hello", tag1.name])
    end

    it "wont perform action if tag_group specified in SiteSetting does not exists" do
      SiteSetting.tga_bulk_action_replace_tag_name = "deal-is-closed"
      SiteSetting.tga_bulk_action_tag_group_name = "Not Allowed"

      topic.tags = [Fabricate(:tag, name: "super"), tag1]
      topic1.tags = [Fabricate(:tag, name: "hello"), tag1]

      TopicsBulkAction.new(user, [topic.id, topic1.id], { type: 'closeDeal' }).perform!

      topic.reload
      topic1.reload

      expect(topic.tags.map { |t| t.name }).to match_array(["super", tag1.name])
      expect(topic1.tags.map { |t| t.name }).to match_array(["hello", tag1.name])
    end

    it "wont perform bulk-action if tagging is disabled" do
      SiteSetting.tga_bulk_action_replace_tag_name = "deal-is-closed"
      SiteSetting.tga_bulk_action_tag_group_name = "Not Allowed"
      SiteSetting.tagging_enabled = true

      topic.tags = [Fabricate(:tag, name: "super"), tag1]
      topic1.tags = [Fabricate(:tag, name: "hello"), tag1]

      TopicsBulkAction.new(user, [topic.id, topic1.id], { type: 'closeDeal' }).perform!

      topic.reload
      topic1.reload

      expect(topic.tags.map { |t| t.name }).to match_array(["super", tag1.name])
      expect(topic1.tags.map { |t| t.name }).to match_array(["hello", tag1.name])
    end
  end
end
