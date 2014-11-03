require "rubygems"
require "sinatra"
require "haml"


get "/?" do
  redirect "/overview"
end

get "/overview/?" do
  # display overview
  accepted = [".mp3"]
  @records = Dir.entries("public/").select {|f| (!File.directory? f) && (accepted.include? File.extname f)}
  haml :overview
end

# upload form
get "/upload/?" do
  haml :upload
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

post "/update/:record/?" do
  if params[:comment] == ""
    haml :error
  else
    File.open("public/#{params[:record]}", "a+") {|f|
      f << "---> #{Time.now.ctime} #{params[:comment].inspect}"
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

get "/style.css" do
  headers "Content-Type" => "text/css; charset=utf-8"
  scss :style
end
