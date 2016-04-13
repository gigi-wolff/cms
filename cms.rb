require "pry"
require "redcarpet"
require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
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
  if params[:username] == "admin" && params[:password] == "secret"
    session[:username] = params[:username]
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
  #file = params[:filename]
  #headers["Content-Type"] = "text/plain"
  #@file = File.read("data/#{file}") 
  file_path = File.join(data_path, params[:filename])

  #file_path = root + "/data/" + params[:filename]

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end


# -------- Update -------
# Edit contents of file
get "/:filename/edit" do
  #file_path = root + "/data/" + params[:filename]
  file_path = File.join(data_path, params[:filename])

  @filename = params[:filename]
  #@content = load_file_content(file_path)
  @content = File.read(file_path)
  erb :edit
end

# Update contents of file
post "/:filename" do
  #file_path = root + "/data/" + params[:filename]
  file_path = File.join(data_path, params[:filename])
  
  File.write(file_path, params[:content])
  session[:message] = "#{params[:filename]} has been updated"
  redirect "/"
end


#--------- Create --------
# Render the new list form
get "/new" do
  erb :new, layout: :layout
end

# Create a new document
post "/create" do
  filename = params[:filename]

  if filename.empty?
    session[:message] = "A name is required"
    status 422
    erb :new, layout: :layout
  else
    file_path = File.join(data_path, params[:filename])  
    File.write(file_path, "")
    session[:message] = "The #{filename} has been created."
    redirect "/"
  end
end


# -------- Destroy --------
# Delete a file
post "/:filename/delete" do
  file_path = File.join(data_path, params[:filename])  
  File.delete(file_path)
  session[:success] = "#{params[:filename]} has been deleted."
  redirect "/"
end


