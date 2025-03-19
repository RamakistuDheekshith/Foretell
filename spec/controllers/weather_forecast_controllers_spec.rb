require 'rails_helper'
require 'ostruct'

RSpec.describe WeatherForecastController, type: :controller do
  let(:valid_location) { "New York" }
  let(:invalid_location) { "Invalid Address" }
  let(:latitude) { 40.7128 }
  let(:longitude) { -74.0060 }
  let(:forecast_data) do
    {
      "current" => { "temperature_2m" => 22, "windspeed_10m" => 5, "weather_code" => 1 },
      "hourly" => { "temperature_2m" => [22, 21, 20], "windspeed_10m" => [5, 4, 3], "relative_humidity_2m" => [60, 65, 70] },
      "daily" => { "temperature_2m_max" => [24, 23, 22], "temperature_2m_min" => [15, 14, 13], "weather_code" => [1, 2, 3] }
    }
  end
  let(:valid_coordinates) { { lat: latitude, lon: longitude } }

  describe 'GET #forecast' do
    before do
      allow(controller).to receive(:get_weather_forecast).and_return(forecast_data)
      Rails.cache.clear
    end

    context 'when latitude and longitude are provided' do
      it 'returns a successful response' do
        get :forecast, params: { :latitude => latitude, :longitude => longitude }
        expect(response).to have_http_status(:ok)
      end

      it 'uses the correct forecast data' do
        get :forecast, params: { latitude: latitude, longitude: longitude }
        expect(assigns(:forecast_data)).to eq(forecast_data)
      end
    end

    context 'when a location is provided' do
      before do
        allow(controller).to receive(:get_location_details).with(valid_location).and_return(valid_coordinates)
      end

      it 'returns a successful response' do
        get :forecast, params: { location: valid_location }
        expect(response).to have_http_status(:ok)
      end

      it 'uses the correct forecast data' do
        get :forecast, params: { location: valid_location }
        expect(assigns(:forecast_data)).to eq(forecast_data)
      end
    end

    context 'when geocoding fails' do
      before do
        allow(controller).to receive(:get_location_details).with(invalid_location).and_return(nil)
      end

      it 'returns an error response' do
        get :forecast, params: { location: invalid_location }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Invalid address")
      end
    end

    context 'when no location or coordinates are provided' do
      it 'returns an error response for missing parameters' do
        get :forecast, params: {}
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include("Address required")
      end
    end

    context 'when cached data is present' do
      it 'uses the cached data' do
        coordinates = "#{latitude},#{longitude}"
        Rails.cache.write(coordinates, forecast_data, expires_in: 30.minutes)
        get :forecast, params: { latitude: latitude, longitude: longitude }
        expect(assigns(:cached)).to be true
        expect(assigns(:forecast_data)).to eq(forecast_data)
      end
    end

    context 'when cached data is not present' do
      it 'fetches fresh data and caches it' do
        expect(Rails.cache).to receive(:write).with("#{latitude},#{longitude}", forecast_data, expires_in: 30.minutes)
        get :forecast, params: { latitude: latitude, longitude: longitude }
        expect(assigns(:forecast_data)).to eq(forecast_data)
      end
    end
  end

  describe '#get_location_details' do
    context 'when geocoding is successful' do
      it 'returns latitude and longitude' do
        allow(Geocoder).to receive(:search).with(:valid_location).and_return([OpenStruct.new(data: { "lat" => latitude, "lon" => longitude })])
        result = controller.send(:get_location_details, :valid_location)
        expect(result).to eq({ lat: latitude, lon: longitude })
      end
    end

    context 'when geocoding fails' do
      it 'returns nil' do
        allow(Geocoder).to receive(:search).with(invalid_location).and_return([])
        result = controller.send(:get_location_details, invalid_location)
        expect(result).to be_nil
      end
    end
  end

  describe '#get_weather_forecast' do
    before do
      allow(controller).to receive(:get_weather_forecast).and_return(forecast_data)
    end
    it 'returns forecast data' do
      result = controller.send(:get_weather_forecast, latitude, longitude)
      expect(result).to eq(forecast_data)
    end
  end
end
