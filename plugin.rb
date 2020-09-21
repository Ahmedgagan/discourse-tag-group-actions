# frozen_string_literal: true

# name: Discourse Tag Group Actions
# about: adds new bulk-action and search-advance option
# version: 0.1
# authors: Ahmed Gagan
# url: https://github.com/Ahmedgagan/discourse-tag-group-actions

enabled_site_setting :tag_group_action_enabled

after_initialize do
  register_search_advanced_filter(/notInTagGroup:(.+)$/) do |posts, match|
    if SiteSetting.tagging_enabled && @guardian.is_staff?
      matchNew = match.gsub("_", " ")

      if tag_group = TagGroup.find_by_name(matchNew)
        posts.where("topics.id NOT IN (
          SELECT DISTINCT tt.topic_id
          FROM topic_tags tt
          INNER JOIN tag_group_memberships tgm
          ON tt.tag_id=tgm.tag_id
          WHERE tgm.tag_group_id=#{tag_group.id}
          OR tt.tag_id=#{tag_group.parent_tag_id || "null"}
        )")
      end
    end
  end

  TopicsBulkAction.register_operation("closeDeal") do
    if SiteSetting.tagging_enabled &&
       SiteSetting.tga_bulk_action_tag_group_name.present? &&
       SiteSetting.tga_bulk_action_replace_tag_name.present?

      tag = Tag.find_by_name(SiteSetting.tga_bulk_action_replace_tag_name)
      tag_group = TagGroup.find_by_name(SiteSetting.tga_bulk_action_tag_group_name)

      if tag && tag_group
        topics.each do |t|
          guardian.can_edit?(t)

          t.topic_tags.where("
            topic_tags.tag_id IN (
              SELECT DISTINCT tags.id
              FROM tag_groups tg
              INNER JOIN tag_group_memberships tgm
              ON tgm.tag_group_id=tg.id
              INNER JOIN tags
              ON tags.id=tgm.tag_id
              OR tags.id=tg.parent_tag_id
              WHERE tg.name=?
            )", tag_group.name).destroy_all

          TopicTag.new(tag_id: tag.id, topic_id: t.id).save
        end
      end
    end
  end
end
