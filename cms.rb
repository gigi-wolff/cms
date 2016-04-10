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

  def load_file_content(file_path)
    ext = File.extname(file_path)
    content = File.read(file_path)
    if ext == ".txt"
      headers["Content-Type"] = "text/plain"
      content
    elsif ext == ".md"
      render_markdown(content)
    end
  end
end

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
    session[:error] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

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




