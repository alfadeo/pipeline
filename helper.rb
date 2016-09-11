Mongoid.load_configuration({
  :clients => {
    :default => {
      :database => "pipeline",
      :hosts => ["localhost:27017"],
    }
  }
})
Mongoid.raise_not_found_error = false # return nil if no document is found
$mongo = Mongo::Client.new("mongodb://127.0.0.1:27017/pipeline")
$gridfs = $mongo.database.fs

CLASSES = ["Track","User"]

module Pipeline
  CLASSES.each do |klass|
    c = Class.new do
      include Pipeline
      include Mongoid::Document
      include Mongoid::Timestamps
      store_in collection: klass.downcase.pluralize
      if klass == "User"
        field :name, type: String
        field :favs, type: Array, default: []
      else
        field :name,  type: String
        field :owner,  type: String
        field :comments, type: Hash, default: {}
        field :likes, type: Integer, default: 0
      end
    end
    Pipeline.const_set klass,c
  end
end

def get_user_favs(user)
  who = Pipeline::User.find_by(:name => user)
  favs = who.favs
end

def add_user_favs(user, track)
  who = Pipeline::User.find_by(:name => user)
  who.favs << track
  who.save
end

def delete_user_favs(user, track)
  who = Pipeline::User.find_by(:name => user)
  who.favs.delete(track)
  who.save
end

def add_track(track)
  t = Pipeline::Track.new
  t.name = track
  t.save
end

def add_track_like(track)
  track = Pipeline::Track.find_by(:name => track)
  track.likes += 1
  track.save
end

def delete_track_like(track)
  track = Pipeline::Track.find_by(:name => track)
  track.likes -= 1 unless track.likes == 0
  track.save
end

def get_favorites
  tracks = Pipeline::Track.all
  out = []
  tracks.each{|t| (out << t) if t.likes >= 3}
  out
end

def get_track_name(id)
  track = Pipeline::Track.find_by(:id => id)
  track.name
end

def get_track_id(name)
  track = Pipeline::Track.find_by(:name => name)
  track.id
end

def get_tracks
  out = []
  tracks = Pipeline::Track.all
  tracks.each{|t| out << t.name}
  out
end

def get_track(name)
  File.join("public/#{name}.mp3")
end

def delete_track(track)
  # delete from Tracks collection
  track = Pipeline::Track.find_by(:name => name)
  track.delete
  # delete from each user favs
  $users.each do |u|
    user = Pipeline::User.find_by(:name => u)
    user.favorites.delete(track)
    user.save
  end
  # delete from public dir
  `rm pubic/#{track}.mp3`
  `rm pubic/#{track}.wav`
end 

def admin?
  session[:admin] ||= nil
end

def pass?
  session[:pass] ||= nil
end

def protected!
  redirect "/login" unless admin? == $user && pass? == $pass
end

def links
  File.readlines(File.join "public/links.txt").map{ |line| line.gsub("\n","")}.compact
end

def timelink(time, id)
  str = "<a href=\"javascript:void(null);\" rel=\"like{{#{id}}}\" data-para1=\"#{time}\" data-para2=\"#{id}\">#{time}</a>"
end

def wavepeaks(track)
  file = File.read(File.join "public", track+".json")
  data_hash = JSON.parse(file)
  data_hash["data"]
end

def to_mp3(track)
  i = File.join "public", track
  o = File.join "public", track.gsub(".wav", ".mp3")
  `lame -h -b 256 #{i} #{o}`
end
