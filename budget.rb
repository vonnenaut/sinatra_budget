# budget.rb
# A budgeting app.

require "sinatra"
require "sinatra/reloader"
require "sinatra/contrib"
require "tilt/erubis"
require "redcarpet"
require "yaml"
require "bcrypt"
require "pi_charts"

configure do
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(20) }
end

before do
  session[:items] ||= { 'rent' => 250, 'utilities' => 100, 'education' => 200 }
end

def generate_pie_chart
  chart = PiCharts::Pie.new
  
  session[:items].each_pair do |key, value|
    chart.add_dataset(label: key, data: value)  
  end

  chart.hover
  chart.responsive
  chart.cdn + chart.html(width: 60)
end

get "/" do
  @items = session[:items]
  @chart = generate_pie_chart unless @items.nil?
  erb :index, layout: :layout
end

get "/tools" do
  erb :tools, layout: :layout
end

# Render the new budget item form
get "/new" do
  erb :new_item, layout: :layout
end

# edit existing budget items
get "/edit/:category" do
  @category = params[:category]
  @amount = session[:items][@category]
  erb :edit, layout: :layout
end

# create a new budget item (or add to an existing category)
post "/" do
  # To-Do: validate input
  category = params[:category].strip
  amount = params[:amount].to_i

  session[:items][category] = amount
  session[:message] = "New item added."

  redirect "/"
end

# delete a category
post "/delete/:category" do
  session[:items].reject! { |item| item == params[:category] }
  session[:message] = "The category has been deleted."
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/"
  else
    redirect "/"
  end
end