require 'sinatra'
require 'haml'
require 'geocoder'
require 'rest-client'
require 'JSON'
require 'pry'
require 'mongo'
#require 'bson_ext'

#include Mongo

#configure do
#  conn = Mongo::Client.new(['127.0.0.1:27017'], database: 'test')
#  set :mongo_connection, conn
  #set :mongo_db, conn.db('test')
#end

WEATHER_TYPES = ['Clear','Rain', 'Clouds', 'Snow']
EVENT_TYPES= {"picnic" => 'Clear',
               "bowling" => 'Rain',
               "skiing" => 'Snow'}



get '/' do
  haml :index
end

post '/form' do
  binding.pry
  full_address = "#{params[:street_address]} #{params[:city]} #{params[:state]} #{params["country"]}"
  Geocoder.configure(:timeout => 5)
  latitude, longitude = Geocoder.coordinates(full_address)
  response = RestClient.get("api.openweathermap.org/data/2.5/forecast/daily?lat=#{latitude}&lon=#{longitude}&cnt=14&mode=json")
  @parsed_response = JSON.parse(response)

  @parsed_response['list'].each do |date|
    if Time.at(date['dt'].to_i).strftime("%Y-%m-%d") == params[:date]
      @weather_detailed =  date['weather'][0]['description']
      @weather =  date['weather'][0]['main']
      @temp = (date['temp']['day'] - 273).to_f*1.8+32
      @event_type = params[:event_type]
      @date = params[:date]
    end
  end
  #file = File.read('weather_reporter.json')
#  event_weather = EVENT_TYPES[@event_type]
#  alternative_location = find_random_city_based_on_weather(event_weather)
#  @alternative_city = alternative_location['city']['name']
#  @alternative_country = alternative_location['city']['country']

#  @alternative_place_img = get_random_city_picture_url(@alternative_city, @alternative_country)

  haml :weather_report
end





def find_random_city_based_on_weather(weather)
  random = random_number
  place = settings.mongo_db['example'].find({"data.weather.main" => weather}, :fields => %w[city.name city.country]).limit(-1).skip(random).next()
  if place.nil?
    random = random_number / 2
    place = settings.mongo_db['example'].find({"data.weather.main" => weather}, :fields => %w[city.name city.country]).limit(-1).skip(random).next()
  end

  place
end

def random_number
  max = settings.mongo_db['example'].count() - 1000
  Random.new.rand(0..max)
end

def get_random_city_picture_url(city, country)
  url_base = "https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q="
  search = "#{city}, #{country}"
  url = url_base + search
  response = RestClient.get(URI.escape(url))
  parsed_response = JSON.parse(response)
  parsed_response['responseData']['results'][0]['unescapedUrl']
end
