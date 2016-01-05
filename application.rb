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
end

get "/?" do
  @@user = "?"
  haml :login
end

get "/login/?" do
  haml :login
end

post "/login" do
  session[:admin] = params[:admin]
  session[:pass] = params[:pass]
  session[:user] = params[:user]
  redirect "/overview"
end

get "/overview/?:user?/?:div?" do
  protected!
  @@user = session[:user]
  # display overview
  accepted = [".mp3"]
  @records = Dir.entries("public/").select {|f| (!File.directory? f) && (accepted.include? File.extname f)}.sort{ |a,b| File.mtime("public/"+b) <=> File.mtime("public/"+a) }
  @s = File.readlines(File.join "public", "s.txt").map{ |line| line.split}.flatten
  @c = File.readlines(File.join "public", "c.txt").map{ |line| line.split}.flatten
  @d = File.readlines(File.join "public", "d.txt").map{ |line| line.split}.flatten
  @n = File.readlines(File.join "public", "n.txt").map{ |line| line.split}.flatten
  @@s = @s
  @@c = @c
  @@d = @d
  @@n = @n
  all = @s+@c+@d+@n
  @top = []
  h = Hash.new(0)
  all.each{|name| h[name] += 1}
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
  case params[:who]
  when "s"
    if !@@s.include?(params[:favS])
      File.open("public/s.txt", "a+") {|f|
        f << params[:favS]+"\n"
      }
    else
      `sed -i '/\\b\\(#{params[:favS]}\\)\\b/d' #{File.join ("public/s.txt")}`
    end
    record = params[:favS]
  when "c"
    if !@@c.include?(params[:favC])
      File.open("public/c.txt", "a+") {|f|
        f << params[:favC]+"\n"
      }
    else
      `sed -i '/\\b\\(#{params[:favC]}\\)\\b/d' #{File.join ("public/c.txt")}`
    end
    record = params[:favC]
  when "d"
    if !@@d.include?(params[:favD])
      File.open("public/d.txt", "a+") {|f|
        f << params[:favD]+"\n"
      }
    else
      `sed -i '/\\b\\(#{params[:favD]}\\)\\b/d' #{File.join ("public/d.txt")}`
    end
    record = params[:favD]
  when "n"
    if !@@n.include?(params[:favN])
      File.open("public/n.txt", "a+") {|f|
        f << params[:favN]+"\n"
      }
    else
      `sed -i '/\\b\\(#{params[:favN]}\\)\\b/d' #{File.join ("public/n.txt")}`
    end
    record = params[:favN]
  end

  redirect "/overview?user=#{@@user}/#div_#{record}"
end

post "/update/:record/?" do
  protected!
  if params[:comment] == ""
    haml :error
  else
    File.open("public/#{params[:record]}", "a+") {|f|
      f << "- #{@@user}: #{params[:comment].inspect}<br>"
    }
    redirect "/overview?user=#{@@user}/#div_#{params[:record].gsub(".txt", "")}"
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
  ["c","s","d","n"].each do |u|
    `sed -i '/\\b\\(#{params[:record]}\\)\\b/d' #{File.join ("public/#{u}.txt")}`
  end
  redirect "/overview"
end

