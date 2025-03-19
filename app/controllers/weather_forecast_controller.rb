require "open_meteo"
require "pry"

class WeatherForecastController < ApplicationController
  def forecast
    unless params[:latitude] && params[:longitude]
      return render json: { error: "Address required" }, status: :bad_request unless params[:location].present?
      latitude, longitude = get_location_details(params[:location])&.values_at(:lat, :lon)
      return render json: { error: "Invalid address" }, status: :unprocessable_entity unless latitude && longitude
    else params[:latitude] && params[:longitude]
      latitude = params[:latitude]
      longitude = params[:longitude]
    end
    coordinates = "#{latitude},#{longitude}"
    cached_data = Rails.cache.read(coordinates)
    @cached = !!cached_data
    @forecast_data = @cached? cached_data : get_weather_forecast(latitude, longitude)

    Rails.cache.write(coordinates, @forecast_data, expires_in: 30.minutes) unless @cached

    render :show, status: :ok
  end

  def show
  end

  private

  def get_location_details(address)
    location_co_ordinates = Geocoder.search(address).first
    return { lat: location_co_ordinates&.data["lat"], lon: location_co_ordinates&.data["lon"] } if location_co_ordinates.present?

    Rails.logger.error "Geocoder failed for address: #{address}"
    nil
  end

  def get_weather_forecast(latitude, longitude)
    location = OpenMeteo::Entities::Location.new(latitude: latitude.to_d, longitude: longitude.to_d)

    # below variables are differnt factors consider for temporal forecasting
    variables = { current: %i[temperature_2m windspeed_10m weather_code], hourly: %i[temperature_2m windspeed_10m relative_humidity_2m], daily: %i[temperature_2m_max, temperature_2m_min weather_code] }
    forecast_data = OpenMeteo::Forecast.new.get(location: location, variables: variables)
  end
end
