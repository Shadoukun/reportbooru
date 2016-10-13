module Reports
  class PostChanges < Base
    def version
      1
    end

    def min_changes
      400
    end

    def folder_id
      "0B1OwQUUumteucE0wTVJSWnhRSG8"
    end

    def html_template
      return <<-EOS
%html
  %head
    %title Post Change Report
    %style
      :css
        #{pure_css_tables}
  %body
    %table{:class => "pure-table pure-table-bordered pure-table-striped"}
      %caption Post changes in the past thirty days (minimum count is #{min_changes})
      %thead
        %tr
          %th User
          %th Total
          %th Rat
          %th Src
          %th Add
          %th Rem
          %th Art
          %th Char
          %th Copy
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:total]
            %td= datum[:rating]
            %td= datum[:source]
            %td= datum[:added]
            %td= datum[:removed]
            %td= datum[:artist]
            %td= datum[:character]
            %td= datum[:copyright]
EOS
    end

    def generate
      htmlf = Tempfile.new("#{file_name}_html")
      jsonf = Tempfile.new("#{file_name}_json")

      begin
        data = []

        candidates.each do |user_id|
          data << calculate_data(user_id)
        end

        data = data.sort_by {|x| -x[:total].to_i}

        engine = Haml::Engine.new(html_template)
        htmlf.write(engine.render(Object.new, data: data))

        jsonf.write("[")
        jsonf.write(data.map {|x| x.to_json}.join(","))
        jsonf.write("]")

        htmlf.rewind
        jsonf.rewind

        upload(htmlf, "#{file_name}.html", "text/html")
        upload(jsonf, "#{file_name}.json", "application/json")
      ensure
        jsonf.close
        htmlf.close
      end
    end

    def calculate_data(user_id)
      tda = date_window.strftime("%F %H:%M")
      name = DanbooruRo::User.find(user_id).name
      client = BigQuery::PostVersion.new
      total = client.count_changes(user_id, tda)
      rating = client.count_rating_changed(user_id, tda)
      source = client.count_source_changed(user_id, tda)
      added = client.count_added(user_id, tda)
      removed = client.count_removed(user_id, tda)
      artist = client.count_artist_added(user_id, tda)
      character = client.count_character_added(user_id, tda)
      copyright = client.count_copyright_added(user_id, tda)

      return {
        id: user_id,
        name: name,
        total: total,
        rating: rating,
        source: source,
        added: added,
        removed: removed,
        artist: artist,
        character: character,
        copyright: copyright
      }
    end

    def candidates
      DanbooruRo::PostVersion.where("updated_at > ?", date_window).group("updater_id").having("count(*) > ?", min_changes).pluck(:updater_id)
    end
  end
end
