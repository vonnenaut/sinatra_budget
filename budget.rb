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

def get_budget

end

def generate_pie_chart(data_hash)
  chart = PiCharts::Pie.new
  
  data_hash.each_pair do |key, value|
    chart.add_dataset(label: key, data: value)  
  end

  chart.hover
  chart.responsive
  chart.cdn + chart.html(width: 60)
end

get "/" do
  data_hash = get_budget
  # data_hash = { 'food' => 300, 'rent' => 250, 'utilities' => 100, 'student loans' => 200 }
  @chart = generate_pie_chart(data_hash) unless data_hash.nil?

  erb :index, layout: :layout
end

get "/edit" do


  erb :edit, layout: :layout
end