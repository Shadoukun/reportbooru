module BigQuery
  class PostVersion < Base
    TRANSLATOR_TAGS = %w(translated check_translation partially_translated translation_request commentary check_commentary commentary_request)

    def find_removed(tag)
      tag = escape(tag)
      query("select id, post_id, updated_at, updater_id, updater_ip_addr, tags, added_tags, removed_tags, parent_id, rating, source from [danbooru_#{Rails.env}.post_versions] where regexp_match(removed_tags, \"(?:^| )#{tag}(?:$| )\") order by updated_at desc limit 1000")
    end

    def find_added(tag)
      tag = escape(tag)
      query("select id, post_id, updated_at, updater_id, updater_ip_addr, tags, added_tags, removed_tags, parent_id, rating, source from [danbooru_#{Rails.env}.post_versions] where regexp_match(added_tags, \"(?:^| )#{tag}(?:$| )\") order by updated_at desc limit 1000")
    end

    def count_changes(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where updater_id = #{user_id} and updated_at >= '#{min_date}'")
    end

    def count_added(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where updater_id = #{user_id} and added_tag is not null and updated_at >= '#{min_date}'")
    end

    def count_removed(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where updater_id = #{user_id} and removed_tag is not null and updated_at >= '#{min_date}'")
    end

    def count_artist_added(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] as pvf join [danbooru_#{Rails.env}.tags] as t on pvf.added_tag = t.name where pvf.updater_id = #{user_id} and pvf.added_tag is not null and t.category = 1 and pvf.updated_at >= '#{min_date}'")
    end

    def count_artist_added_v1(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] as pvf join [danbooru_#{Rails.env}.tags] as t on pvf.added_tag = t.name where pvf.updater_id = #{user_id} and pvf.added_tag is not null and t.category = 1 and pvf.version = 1 and pvf.updated_at >= '#{min_date}'")
    end

    def count_character_added(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] as pvf join [danbooru_#{Rails.env}.tags] as t on pvf.added_tag = t.name where pvf.updater_id = #{user_id} and pvf.added_tag is not null and t.category = 4 and pvf.updated_at >= '#{min_date}'")
    end

    def count_character_added_v1(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] as pvf join [danbooru_#{Rails.env}.tags] as t on pvf.added_tag = t.name where pvf.updater_id = #{user_id} and pvf.added_tag is not null and t.category = 4 and pvf.version = 1 and pvf.updated_at >= '#{min_date}'")
    end

    def count_copyright_added(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] as pvf join [danbooru_#{Rails.env}.tags] as t on pvf.added_tag = t.name where pvf.updater_id = #{user_id} and pvf.added_tag is not null and t.category = 3 and pvf.updated_at >= '#{min_date}'")
    end

    def count_copyright_added_v1(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] as pvf join [danbooru_#{Rails.env}.tags] as t on pvf.added_tag = t.name where pvf.updater_id = #{user_id} and pvf.added_tag is not null and t.category = 3 and pvf.version = 1 and pvf.updated_at >= '#{min_date}'")
    end

    def count_general_added(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] as pvf join [danbooru_#{Rails.env}.tags] as t on pvf.added_tag = t.name where pvf.updater_id = #{user_id} and pvf.added_tag is not null and t.category = 0 and pvf.updated_at >= '#{min_date}'")
    end

    def count_general_added_v1(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] as pvf join [danbooru_#{Rails.env}.tags] as t on pvf.added_tag = t.name where pvf.updater_id = #{user_id} and pvf.added_tag is not null and t.category = 0 and pvf.version = 1 and pvf.updated_at >= '#{min_date}'")
    end

    def count_any_added_v1(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] as pvf where pvf.updater_id = #{user_id} and pvf.added_tag is not null and pvf.version = 1 and pvf.updated_at >= '#{min_date}'")
    end

    def count_rating_changed(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where updater_id = #{user_id} and regexp_match(removed_tag, r'^rating:') and updated_at >= '#{min_date}'")
    end

    def count_source_changed(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where updater_id = #{user_id} and regexp_match(removed_tag, r'^source:') and updated_at >= '#{min_date}'")
    end

    def translator_tag_candidates(min_date, min_changes)
      tag_subquery = TRANSLATOR_TAGS.map {|x| "'#{x}'"}.join(", ")
      resp = query("select updater_id from [danbooru_#{Rails.env}.post_versions_flat] where added_tag in (#{tag_subquery}) or removed_tag in (#{tag_subquery}) and updated_at >= '#{min_date}' group by updater_id having count(*) > #{min_changes}")

      if resp["rows"]
        resp["rows"].map {|x| x["f"][0]["v"]}
      else
        []
      end
    end

    def count_tag_added(user_id, tag, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where updater_id = #{user_id} and added_tag = '#{tag}' and updated_at >= '#{min_date}'")
    end

    def count_tag_removed(user_id, tag, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where updater_id = #{user_id} and removed_tag = '#{tag}' and updated_at >= '#{min_date}'")
    end
  end
end
