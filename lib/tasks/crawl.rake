namespace :crawl do

  # 爬 the wall
  task the_wall: :environment do
    agent = Mechanize.new
    url = 'https://thewall.tw/shows'
    page = agent.get(url)

    page.search('.show-item').each do |item|
      photo = item.search('.poster img').attr("src").value

      date = "2018/" + item.search('.date').text[0..4]

      week = item.search('.date').text[6]

      name = item.search('.title').text

      info = item.search('tbody tr')
      if info[0].text[0..1] == "演出"
        artists = info[0].text[2..-1].split(', ')
        n = 0
      else
        artists = "Need to Check"
        n = 1
      end

      price = info[1-n].text[2..-1]

      place = "The Wall-" + info[2-n].text[2..-1]
      place_data = { "name" => place,
                     "address" => "臺北市羅斯福路四段200號B1" }

      begin
        time = info[3-n].text[2..-1]
      rescue NoMethodError
        time = "Need to Check"
      end

      save_data(artists, place_data, name, photo, date, week, price, time)
    end
    puts "Finish the wall crawling"
  end

  # 爬 revolver
  task revolver: :environment do
    url = "https://static.wixstatic.com/sites/0be0c0_923df9bbdeb29ce7fe02259a492bf69f_1066.json.z?v=3"
    response = RestClient.get(url)
    data = JSON.parse(response.body)
    need_data = data["data"]["document_data"]["dataItem-ilaglyp1"]["text"]
    page = Nokogiri::HTML(need_data)

    page.text.split("\n \n\n").each do |item|
      info = item.split("\n\n")

      photo = "https://static.wixstatic.com/media/0be0c0_6d67fb8e88ba4c8ca2949b70a42fb483.png/v1/fill/w_191,h_143,al_c,usm_0.66_1.00_0.01/0be0c0_6d67fb8e88ba4c8ca2949b70a42fb483.png"

      date = "2018/" + info[0][0..4]

      week_convert_hash = { "Sun" => "日",
                            "Mon" => "一",
                            "Tue" => "二",
                            "Wed" => "三",
                            "Thu" => "四",
                            "Fri" => "五",
                            "Sat" => "六" }
      week = week_convert_hash[/\(.*\./.match(info[0])[0][1..-2]]

      begin
        name = /\[.*\]/.match(info[1])[0][1..-2]
      rescue NoMethodError
        name = "Need to Check"
      end

      artists = info[2].split(" + ")

      n = 0
      time = info[3]
      if !/start/.match(time)
        n = 1
        time = info[3+n]
      end

      price = info[4+n]

      place_data = { "name" => "Revolver",
                     "address" => "臺北市羅斯福路一段一之一號" }

      save_data(artists, place_data, name, photo, date, week, price, time)
    end
    puts "Finish Revolver crawling"
  end

  # 爬 witchhouse
  task witchhouse: :environment do
    agent = Mechanize.new
    url = "http://www.witchhouse.org/"
    page = agent.get(url)

    page.search('.w-dyn-item').each do |item|
      begin
        photo = item.search('.event-img img').attr("src").value
      rescue NoMethodError
        photo = "https://uploads-ssl.webflow.com/5766db8ec26632fe60967e7a/5766df00b2250fc97eb60be0_logo.png" if !photo
      end

      date = "2018.0" + item.search('.event-title-group').text[0..3]

      week = week_convert(item.search('.event-title-group').text[4..6])

      time = item.search('.event-title-group').text[7..-1]

      name = item.search('.event-name').text

      begin
        price = /本場次票價：.*?。/.match(item.search('.event-desc').text)[0][6..-2]
      rescue NoMethodError
        price = ""
      end

      place_data = { "name" => "女巫店",
                     "address" => "臺北市新生南路三段56巷7號" }

      artists = []
      item.search('.event-desc strong').each do |strong|
        if name.include?(strong.text)
          artists << strong.text
        end
      end
      artists = "Need to Check" if artists == []
      artists = artists.uniq if artists != "Need to Check"

      save_data(artists, place_data, name, photo, date, week, price, time)
    end
  end

  task indievox: :environment do
    agent = Mechanize.new
    url = "https://www.indievox.com/event/"
    page = agent.get(url)

    page.links.each {|link| pp link}
  end


end


private

def save_data(artists, place_data, name, photo, date, week, price, time)
  # 存 Artist
  if artists != "Need to Check"
    artists.each do |artist|
      if !Artist.find_by_name(artist)
        Artist.create(name: artist)
        puts "Create artist #{artist}"
      end
    end
  end

  # 存 Place
  if !Place.find_by_name(place_data["name"])
    Place.create(name: place_data["name"],
                 address: place_data["address"] )
    puts "Create place #{place_data["name"]}"
  end

  # 存 Event
  if !Event.find_by_name(name)
    Event.create( name: name,
                  remote_photo_url: photo,
                  date: date,
                  week: week,
                  price: price,
                  time: time )
    puts "Create event #{name}"

    # Event有建再存 Cession
    Cession.create( event_id: Event.find_by_name(name).id,
                    place_id: Place.find_by_name(place_data["name"]).id )
    puts "Create cession!"

    # Event有建再存 Show
    if artists != "Need to Check"
      artists.each do |artist|
        Show.create( event_id: Event.find_by_name(name).id,
                     artist_id: Artist.find_by_name(artist).id )
        puts "Create shows!"
      end
    end
  end
end

def week_convert(week)
  week_convert_hash = { "Sun" => "日",
                        "Mon" => "一",
                        "Tue" => "二",
                        "Wed" => "三",
                        "Thu" => "四",
                        "Fri" => "五",
                        "Sat" => "六" }
  week_convert_hash[week]
end
