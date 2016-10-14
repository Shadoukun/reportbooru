=begin
from brokeneagle98:

Total: total versions/user
Creates: no prior version
Edits: body changed
Moves: x,y changes
Resizes: width,height changes
Deletes: isactive "True" -> "False"
Undeletes: isactive "True" -> "False"
=end

module Reports
	class Notes < Base
		def version
			1
		end

		def min_changes
			100
		end

		def folder_id
			"0B1OwQUUumteuaXl6VFpwcHM2WGs"
		end
		
		def html_template
      return <<-EOS
%html
  %head
    %title Note Report
    %style
      :css
        #{pure_css_tables}
    %meta{:name => "viewport", :content => "width=device-width, initial-scale=1"}
  %body
    %table{:class => "pure-table pure-table-bordered pure-table-striped"}
      %caption Note changes (over past thirty days, minimum changes is #{min_changes})
      %thead
        %tr
          %th User
          %th Contrib
          %th Creates
          %th Edits
          %th Moves
          %th Resizes
          %th Deletes
          %th Undeletes
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:contrib]
            %td= datum[:creates]
            %td= datum[:edits]
            %td= datum[:moves]
            %td= datum[:resizes]
            %td= datum[:deletes]
            %td= datum[:undeletes]
EOS
		end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      tda = date_window.strftime("%F %H:%M")
      client = BigQuery::NoteVersion.new
      contrib = user.can_upload_free? ? "Y" : nil

      return {
        id: user.id,
        name: user.name,
        creates: client.count_creates(user_id, tda),
        contrib: contrib,
        edits: client.count_edits(user_id, tda),
        moves: client.count_moves(user_id, tda),
        resizes: client.count_resizes(user_id, tda),
        deletes: client.count_deletes(user_id, tda),
        undeletes: client.count_undeletes(user_id, tda)
      }
    end


    def generate
      htmlf = Tempfile.new("#{file_name}_html")
      jsonf = Tempfile.new("#{file_name}_json")

      begin
        data = []

        candidates.each do |user_id|
          data << calculate_data(user_id)
        end

        data = data.sort_by {|x| -x[:creates].to_i}

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

		def candidates
			DanbooruRo::NoteVersion.where("updated_at > ?", date_window).group("updater_id").having("count(*) > ?", min_changes).pluck(:updater_id)
		end
	end
end
