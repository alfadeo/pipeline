require "rubygems"
require "sinatra"
require "sinatra/reloader"
require "haml"
require "json"
require 'mongoid'
require File.join "./auth.rb"
require File.join "./helper.rb"

enable :sessions
enable :reloader
also_reload File.join "./helper.rb"
#use Rack::Auth::Basic, "Tell me" do |username, password|
#  [username, password] == [$user, $pass]
#end

#set :raise_errors, false
#set :show_exceptions, false

configure :development do
  $logger = Logger.new(STDOUT)
end

error do
  redirect to('/')
end

get "/?" do
  haml :login
end

get "/login/?" do
  haml :login
end

post "/login" do
  ["admin", "pass", "user"].each do |key|
    session[key.to_sym] = params[key.to_sym]
  end
  redirect "/overview"
end

get "/overview/?:user?/?:div?" do
  protected!
  # display overview
  #accepted = [".mp3", ".wav"]
  #accepted = [".mp3"]
  #@records = Dir.entries("public/").select {|f| (!File.directory? f) && (accepted.include? File.extname f)}.sort{ |a,b| File.mtime("public/"+b) <=> File.mtime("public/"+a) }
  #all = []
  #$users.each do |user|
  #  all << userfile(user)
  #end
  #@top = []
  #h = Hash.new(0)
  #all.flatten.each{|name| h[name] += 1}
  #h.each{|name,count| @top << name if count >= 3}
  @records = get_tracks
  puts @records
  @top = get_favorites
  haml :overview
end

# upload form
get "/upload/?" do
  protected!
  haml :upload
end

get "/links/?" do
  protected!
  haml :links
end

$users.each do |path|
  get "/#{path}/?" do
    protected!
    @records = []
    get_user_favs(path).each{|r| @records << r}
    haml path.to_sym
  end
end

post "/links/?" do
  protected!
  File.open("public/links.txt", "a+") {|f|
    f << "<a href=\"#{params[:comment]}\">"+(params[:title] ? params[:title] : params[:comment])+"</a>"+"\n"
  }

  redirect "/links"
end

# store file
post "/upload/?" do
  protected!
  if !params[:file]
    haml :error
  else
    if params['file'][:filename] =~ /$.wav/
      params['file'].to_mp3
    end
    File.open("public/" + params['file'][:filename].gsub(/\s+/, "_"), "w+") do |f|
      f.write(params['file'][:tempfile].read)
    end
    
    redirect "/overview"
  end
end

get "/favs/:who/:track?" do
  protected!
  if params[:who]
    user = params[:who]
    track = params[:track]
    favs = get_user_favs(user)
    if !favs.include?(params["track"])
      return "true"
    else
      return "false"
    end
  end
end

post "/update/favs/:who/?" do
  protected!
  if params[:who]
    user = params[:who]
    favs = get_user_favs(user)
    if !favs.include?(params["fav"])
      add_user_favs(user, params["fav"])
      add_track_like(params["fav"])
    else
      delete_user_favs(user, (params["fav"]))
      delete_track_like(params["fav"])
    end
  end
end

post "/update/:record/?" do
  protected!
  if !params[:comment] && !params[:rmcomment]
    haml :error
  else
    if params[:comment]
      track = Pipeline::Track.find_by(:name => params[:record].gsub(/\.txt/,""))
      track.comments[Time.now.to_i] = session[:user]+"#"+params[:comment]
      track.save
    end
    if params[:rmcomment]
      track = Pipeline::Track.find_by(:name => params[:record].gsub(/\.txt/,""))
      track.comments.delete(params[:comment_id])
      track.save
    end
    
    redirect "/overview?user=#{session[:user]}/#div_#{params[:record].gsub(".txt", "")}"
  end
end

# get single record
get "/download/:record/?" do
  protected!
  send_file File.join(settings.public_folder, "#{params[:record]}.mp3"), :type => :mp3, :filename => "#{params[:record]}.mp3"
end

# delete form
get "/delete/:record" do
  protected!
  haml :delete, :locals => {:record => params[:record]}
end

get "/delete/link/:link" do
  protected!
  `sed -i '#{params[:link].to_i}d' #{File.join("public/links.txt")}`
  
  redirect "/links"
end

# remove from server
get "/remove/:record/?" do
  protected!
  delete_track(params[:record])
  
  redirect "/overview"
end
