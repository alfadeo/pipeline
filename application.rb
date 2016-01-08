require "rubygems"
require "sinatra"
require "haml"
require File.join "./auth.rb"

enable :sessions

#use Rack::Auth::Basic, "Tell me" do |username, password|
#  [username, password] == [$user, $pass]
#end

set :raise_errors, false
set :show_exceptions, false

error do
  redirect to('/')
end

helpers do
  def admin?
    session[:admin] ||= nil
  end

  def pass?
    session[:pass] ||= nil
  end

  def protected!
    redirect "/login" unless admin? == $user && pass? == $pass
  end

  def userfile(user)
    File.readlines(File.join "public", user+".txt").map{ |line| line.split}.flatten
  end

  def comments(track)
    File.readlines(File.join "public", track+".txt").map{ |line| line}.compact
  end

  def timelink(time, id)
    str = "<a href=\"javascript:void(null);\" rel=\"like{{#{id}}}\" data-para1=\"#{time}\" data-para2=\"#{id}\">#{time}</a>"
  end
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
  accepted = [".mp3"]
  @records = Dir.entries("public/").select {|f| (!File.directory? f) && (accepted.include? File.extname f)}.sort{ |a,b| File.mtime("public/"+b) <=> File.mtime("public/"+a) }
  all = []
  $users.each do |user|
    all << userfile(user)
  end
  @top = []
  h = Hash.new(0)
  all.flatten.each{|name| h[name] += 1}
  h.each{|name,count| @top << name if count >= 3}

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

post "/links/?" do
  protected!
  File.open("public/links.txt", "a+") {|f|
    f << "* <a href="+"#{params[:comment].inspect.gsub("\"", "")}"+">#{params[:comment].inspect}</a><br>"
  }

  redirect "/links"
end

# store file
post "/upload/?" do
  protected!
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
  protected!
  if params[:who]
    user = params[:who]
    file = userfile user
    fav = "fav"+user.capitalize
    if !file.include?(params[fav.to_sym])
      File.open("public/"+user+".txt", "a+") {|f|
        f << params[fav.to_sym]+"\n"
      }
    else
      `sed -i '/\\b\\(#{params[fav.to_sym]}\\)\\b/d' #{File.join ("public/"+user+".txt")}`
    end
    record = params[fav.to_sym]
  end
  redirect "/overview?user=#{session[:user]}/#div_#{record}"
end

post "/update/:record/?" do
  protected!
  if !params[:comment] && !params[:rmcomment]
    haml :error
  else
    if params[:comment]
      File.open("public/#{params[:record]}", "a+") {|f|
        f << session[:user]+"# "+params[:comment].gsub(/\r\n?/, "")+"\n"
      }
    end
    if params[:rmcomment]
      `sed -i '/\\b\\(#{params[:rmcomment]}\\)\\b/d' #{File.join("public/#{params[:record]}")}`
    end
    redirect "/overview?user=#{session[:user]}/#div_#{params[:record].gsub(".txt", "")}"
  end
end

# get single record
get "/download/:record/?" do
  protected!
  send_file File.join(settings.public_folder, "#{params[:record]}")
end

# delete form
get "/delete/:record" do
  protected!
  haml :delete, :locals => {:record => params[:record]}
end

# remove from server
get "/remove/:record/?" do
  protected!
  # remove audio file and comments file
  `rm public/#{params[:record]} && rm public/#{params[:record].gsub(".mp3", ".txt")}`
  # remove from users favs file
  $users.each do |user|
    `sed -i '/\\b\\(#{params[:record].sub(".mp3", "")}\\)\\b/d' #{File.join("public/"+user+".txt")}`
  end
  redirect "/overview"
end

