require "pry"
require "redcarpet"
require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"
require "yaml"
require "bcrypt"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    # __FILE__ is cms.rb
    # find path of cms.rb and add /data to it
    File.expand_path("../data", __FILE__)
  end
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/users.yml", __FILE__)
  else
    File.expand_path("../users.yml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

def valid_credentials?(username, password)
  credentials = load_user_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.create(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

def duplicate_file_name(filename)
  version = '1' #default if first copy
  last_char = filename[filename.index('.')-1]

  #if last_char of filename an int then increment version number of filename
  version = (last_char.to_i + 1).to_s unless /^\d+$/.match(last_char).nil? 

  filename.gsub(last_char,version)
end

# root = "/Users/Gigi/cms"
#root = File.expand_path("..", __FILE__)

helpers do
  def render_markdown(text)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(text)
  end

  def load_file_content(path)
    content = File.read(path)
    case File.extname(path)
    when ".txt"
      headers["Content-Type"] = "text/plain"
      content
    when ".md"
      erb render_markdown(content)
    end
  end
end

#------- Signin --------
#display sign in page
get "/users/signin" do
  erb :signin
end

#grab input from sign in page
post "/users/signin" do
  credentials = load_user_credentials
  puts "credentials= #{credentials}"
  username = params[:username]

  if valid_credentials?(username, params[:password])
    session[:username] = username
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid credentials"
    status 422
    erb :signin
  end
end

#------ Sign Out -------
post "/users/signout" do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect "/"
end

#-------- Show ---------
get "/" do
  "Getting Started"
  #Dir.glob("data/*") ===> ["data/about.txt", "data/changes.txt", "data/history.txt"] 
  #File.basename(file) ===> about.txt" 
  #@files = Dir.glob("data/*").map {|file| File.basename(file) }

  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end

  erb :index
end


# -------- Read --------
#Show contents of file
get "/:filename" do
  file_path = File.join(data_path, params[:filename])

  #file_path = root + "/data/" + params[:filename]

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end


# -------- Edit/Update -------
# Edit contents of file
get "/:filename/edit" do
  file_path = File.join(data_path, params[:filename])  

  @filename = params[:filename]
  @content = File.read(file_path)

  erb :edit
end

# Update contents of file
post "/:filename" do
  file_path = File.join(data_path, params[:filename])  

  File.write(file_path, params[:content])

  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end


#--------- Create --------
# Render the new list form
get "/new" do
  erb :new
end

# Create a new document
post "/create" do
  filename = params[:filename].to_s

  if filename.size == 0
    session[:message] = "A name is required."
    status 422
    erb :new
  else
    file_path = File.join(data_path, filename)

    File.write(file_path, "")
    session[:message] = "#{params[:filename]} has been created."

    redirect "/"
  end
end
# -------- Duplicate --------
post "/:filename/duplicate" do
  #require_signed_in_user
  file_path_src = File.join(data_path, params[:filename])
  file_path_dest = File.join(data_path, duplicate_file_name(params[:filename]))
  
  FileUtils.copy_file(file_path_src, file_path_dest)

  session[:message] = "Duplicate created."
  redirect "/"
end

# -------- Destroy --------
# Delete a file
post "/:filename/delete" do
  file_path = File.join(data_path, params[:filename])  
  File.delete(file_path)
  session[:message] = "#{params[:filename]} has been deleted."
  redirect "/"
end


