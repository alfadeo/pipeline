require "rubygems"
require "sinatra"
require "haml"


get "/?" do
  redirect "/overview"
end

get "/overview/?" do
  # display overview
  accepted = [".mp3"]
  @records = Dir.entries("public/").select {|f| (!File.directory? f) && (accepted.include? File.extname f)}.sort{ |a,b| File.mtime("public/"+b) <=> File.mtime("public/"+a) }
  haml :overview
end

# upload form
get "/upload/?" do
  haml :upload
end

get "/links/?" do
  haml :links
end

post "/links/?" do
  File.open("public/links.txt", "a+") {|f|
    f << "* <a href="+"#{params[:comment].inspect.gsub("\"", "")}"+">#{params[:comment].inspect}</a><br>"
  }

  redirect "/links"
end

# store file
post "/upload/?" do
  if !params[:file]
    haml :error
  else
    File.open("public/" + params['file'][:filename], "w+") do |f|
      f.write(params['file'][:tempfile].read)
    end
    File.open("public/" + params['file'][:filename].gsub(".mp3", "") + ".txt", "w+") do |d|
      d.write("uploaded: #{Time.now.ctime}\n")
    end

    redirect "/overview"
  end
end

post "/update/favs/:who/?" do
  case params[:who]
  when "c"
    File.open("public/c.txt", "w") {|f|
      f << "#{params[:favC].inspect}"
    }
  when "s"
    File.open("public/s.txt", "w") {|f|
      f << "#{params[:favS].inspect}"
    }
  when "d"
    File.open("public/d.txt", "w") {|f|
      f << "#{params[:favD].inspect}"
    }
  when "n"
    File.open("public/n.txt", "w") {|f|
      f << "#{params[:favN].inspect}"
    }
  end
  redirect "/overview"
end

post "/update/:record/?" do
  if params[:comment] == ""
    haml :error
  else
    File.open("public/#{params[:record]}", "a+") {|f|
      f << "- #{params[:comment].inspect}<br>"
    }
    redirect "/overview"
  end
end

# get single record
get "/download/:record/?" do
  send_file File.join(settings.public_folder, "#{params[:record]}")
end

# delete form
get "/delete/:record" do
  haml :delete, :locals => {:record => params[:record]}
end

# remove from server
get "/remove/:record/?" do
  `rm public/#{params[:record]} && rm public/#{params[:record].gsub(".mp3", ".txt")}`
  redirect "/overview"
end
=begin
get "/style.css" do
  headers "Content-Type" => "text/css; charset=utf-8"
  scss :style
end
=end
