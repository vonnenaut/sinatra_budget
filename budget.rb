# budget.rb
# A budgeting app.

require "sinatra"
require "sinatra/reloader" if development?
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
  session[:spend_items] ||= { 'rent' => 250, 'utilities' => 100, 'education' => 200 }
  session[:income_items] ||= { 'basket-weaving' => 500, 'software development' => 100, 'busking' => 200 }
end

def generate_pie_chart(items)
  chart = PiCharts::Pie.new
  
  session[:items].each_pair do |key, value|
    chart.add_dataset(label: key, data: value)  
  end

  chart.hover
  chart.responsive
  chart.cdn + chart.html(width: 60)
end

def sum_amounts(items)
  items.values.reduce(&:+)
end

get "/" do
  redirect "/spending"
end

get "/spending" do
  @items = session[:spend_items]
  @total = sum_amounts(@items)
  @chart = generate_pie_chart(@items) unless @items.nil?

  erb :spending, layout: :layout
end

get "/income" do
  @items = session[:income_items]
  @total = sum_amounts(@items)
  @chart = generate_pie_chart(@items) unless @items.nil?

  erb :income, layout: :layout
end

get "/combined" do
  @spending_items = session[:spend_items]
  @income_items = session[:income_items]
  @total = sum_amounts(@spending_items.merge(@income_items))
  @chart_spending = generate_pie_chart(@spending_items) unless @spending_items.nil?
  @chart_income = generate_pie_chart(@income_items) unless @income_items.nil?

  erb :combined, layout: :layout
end


get "/:mode" do
  @mode = params[:mode]

  case @mode
  when 'income' then redirect "/income"
  when 'combined' then redirect "/combined"
  else redirect "/spending"
  end
end
 
# handle radio button submissions for mode change
post "/" do
  @radio = params[:radio]

  case @radio
  when 'spending' then redirect "/spending"
  when 'income' then redirect "/income"
  when 'combined' then redirect "/combined"
  end
end

get "/tools" do
  erb :tools, layout: :layout
end

# Render the new budget item form
get "/new" do
  erb :new_item, layout: :layout
end

# create a new budget item (or add to an existing category)
post "/new" do
  # To-Do: validate input
  category = params[:category].strip
  amount = params[:amount].to_i

  session[:items][category] = amount
  session[:message] = "New item added."

  redirect "/"
end

# edit existing budget items
get "/edit/:category" do
  @category = params[:category]
  @amount = session[:items][@category]
  erb :edit, layout: :layout
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