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
  session[:spending_items] ||= { 'rent' => 500, 'utilities' => 50, 'food' => 150, 'transport' => 100}
  session[:income_items] ||= { 'software development' => 300, 'busking' => 200 }
end

## Begin Helper methods ###################

def generate_pie_chart(items)
  chart = PiCharts::Pie.new
  
  items.each_pair do |key, value|
    chart.add_dataset(label: key, data: value)  
  end

  chart.hover
  chart.responsive
  chart.cdn + chart.html(width: 100)
end

def generate_bar_chart(spending_total, income_total)
  chart = PiCharts::Bar.new

  chart.add_dataset(label: 'spending', data: spending_total, color: 'red')
  chart.add_dataset(label: 'income', data: income_total, color: 'green')

  chart.hover
  chart.responsive
  chart.cdn + chart.html(width: 100)
end

def sum_amounts(values)
  values.reduce(&:+)
end

def make_key(mode)
  case mode
  when 'spending' then :spending_items
  when 'income' then :income_items
  end
end

def valid_input?(input)
  !input.nil? && input.length > 0
end

def validate(category, mode, combined=false)
  if combined
    unless valid_input?(category)
      string = "/combined/#{mode}/new"
    end
  else
    unless valid_input?(category)
      string = "/#{mode}/new"
    end
  end
  
  session[:message] = "Must enter a category name."
  redirect "#{string}"
end
## Begin Routes #########################

get "/" do
  redirect "/spending"
end

get "/spending" do
  @spending_items = session[:spending_items]
  @total = sum_amounts(@spending_items.values)
  @chart = generate_pie_chart(@spending_items) unless @spending_items.nil?

  erb :spending, layout: :layout
end

get "/income" do
  @income_items = session[:income_items]
  @total = sum_amounts(@income_items.values)
  @chart = generate_pie_chart(@income_items) unless @income_items.nil?

  erb :income, layout: :layout
end

get "/combined" do
  @spending_items = session[:spending_items]
  @income_items = session[:income_items]
  @spending_total = sum_amounts(@spending_items.values)
  @income_total = sum_amounts(@income_items.values)
  @net_total = sum_amounts(@income_items.values) - sum_amounts(@spending_items.values)
  @chart = generate_bar_chart(@spending_total, @income_total)

  erb :combined, layout: :layout
end

# Render the new budget item form in combined mode
get "/combined/:mode/new" do
  @mode = params[:mode]

  erb :combined_new_item, layout: :layout
end

# Create a new budget item (or add to an existing category) in combined mode
post "/combined/:mode/new" do
  mode = params[:mode]
  
  key = make_key(mode)

  category = params[:category].strip
  amount = params[:amount].to_i

  validate(category, mode, true)

  session[key][category] = amount
  session[:message] = "New #{mode} item added."

  redirect "/combined"
end

# edit existing spending or income budget item in combined mode
get "/combined/:mode/edit/:category" do
  @mode = params[:mode]
  @category = params[:category]

  key = make_key(@mode)

  @amount = session[key][@category]

  erb :combined_edit, layout: :layout
end

# post changes to spending or income budget item in combined mode
post "/combined/:mode/edit/:category" do
  @mode = params[:mode]
  @category = params[:category]

  key = make_key(@mode)

  session[key][@category] = params[:amount].to_i
  session[:message] = "#{@mode} item updated."

  redirect "/combined"
end

# delete a spending or income category in combined mode
post "/combined/:mode/delete/:category" do
  mode = params[:mode]
  key = make_key(mode)

  session[key].reject! { |item| item == params[:category] }
  session[:message] = "#{mode} category has been deleted."
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/combined"
  else
    redirect "/combined"
  end
end

# Render the new budget item form in spending or income mode
get "/:mode/new" do
  @mode = params[:mode]

  erb :new_item, layout: :layout
end

# create a new budget item (or add to an existing category) in spending or income mode
post "/:mode/new" do
  mode = params[:mode]
  
  key = make_key(mode)

  category = params[:category].strip
  amount = params[:amount].to_i

  validate(category, mode)

  session[key][category] = amount
  session[:message] = "New #{mode} item added."

  redirect "/#{mode}"
end

# edit existing spending or income budget item in spending or income mode
get "/:mode/edit/:category" do
  @mode = params[:mode]

  key = make_key(@mode)

  @category = params[:category]
  @amount = session[key][@category]

  erb :edit, layout: :layout
end

# post changes to spending or income budget item in spending or income mode
post "/:mode/edit/:category" do
  @mode = params[:mode]
  @category = params[:category]

  key = make_key(@mode)

  session[key][@category] = params[:amount].to_i
  session[:message] = "#{@mode} item updated."

  redirect "/#{@mode}"
end

# delete a spending category in spending mode
post "/:mode/delete/:category" do
  mode = params[:mode]
  key = make_key(mode)

  session[key].reject! { |item| item == params[:category] }
  session[:message] = "#{mode} category has been deleted."
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/#{mode}"
  else
    redirect "/#{mode}"
  end
end