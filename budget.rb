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
  session[:spending_items] ||= { 'rent' => 250, 'utilities' => 100, 'education' => 200 }
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
  chart.cdn + chart.html(width: 60)
end

def sum_amounts(values)
  values.reduce(&:+)
end

def make_key(type)
  case type
  when 'spending' then :spending_items
  when 'income' then :income_items
  end
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

  erb :combined, layout: :layout
end
 
# handle radio button submissions for mode change
# post "/" do
#   @radio = params[:radio]

#   case @radio
#   when 'spending' then redirect "/spending"
#   when 'income' then redirect "/income"
#   when 'combined' then redirect "/combined"
#   end
# end

get "/tools" do
  erb :tools, layout: :layout
end

# Render the new budget item form in spending or income mode
get "/:mode/new" do
  @mode = params[:mode]

  erb :new_item, layout: :layout
end

# Render the new budget item form in combined mode
get "/combined/:mode/new" do
  @mode = params[:mode]

  erb :new_item, layout: :layout
end

# create a new budget item (or add to an existing category) in spending or income mode
post "/:mode/new" do
  type = params[:mode]
  
  key = make_key(type)

  category = params[:category].strip
  amount = params[:amount].to_i

  session[key][category] = amount
  session[:message] = "New #{type} item added."

  redirect "/#{type}"
end

# Create a new budget item (or add to an existing category) in combined mode
post "/combined/:mode/new" do
  
end


# edit existing spending or income budget item in spending or income mode
get "/:mode/edit/:category" do
  @mode = params[:mode]

  key = make_key(@mode)

  @category = params[:category]
  @amount = session[key][@category]

  erb :edit, layout: :layout
end

# edit existing spending or income budget item in combined mode
get "/combined/:mode/edit/:category" do
  @mode = params[:mode]
  @category = params[:category]

  key = make_key(@mode)

  @amount = session[key][@category]

  erb :combined_edit, layout: :layout
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

# post changes to spending or income budget item in combined mode
post "/combined/:mode/edit/:category" do
  @mode = params[:mode]
  @category = params[:category]

  key = make_key(@mode)

  session[key][@category] = params[:amount].to_i
  session[:message] = "#{@mode} item updated."

  redirect "/combined"
end

# delete a spending category in spending mode
post "/spending/delete/:category" do
  session[:spending_items].reject! { |item| item == params[:category] }
  session[:message] = "The spending category has been deleted."
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/spending"
  else
    redirect "/spending"
  end
end

# delete an income category in income mode
post "/income/delete/:category" do
  session[:income_items].reject! { |item| item == params[:category] }
  session[:message] = "The income category has been deleted."
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/income"
  else
    redirect "/income"
  end
end

# delete a spending or income category in combined mode
