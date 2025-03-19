
# Foretell - Weather Forecast Application

This application provides weather forecasts for a given location. It supports looking up forecasts using city names or full addresses (e.g., "New York", "1600 Amphitheatre Parkway, Mountain View, CA").

## Features

* **Location Flexibility:** Get weather forecasts by specifying a city name or a detailed address.
* **Accurate Data:** Fetches weather data from the reliable [Open-Meteo API](https://open-meteo.com/) using the [open_meteo](https://github.com/ropes/open_meteo) Ruby gem.
* **Geocoding:** Uses the [Geocoder](https://github.com/alexreisner/geocoder) gem to convert provided addresses into latitude and longitude coordinates.
* **Comprehensive Weather Information:** Retrieves various weather factors, including current conditions, hourly forecasts, and daily summaries (temperature, wind speed, humidity, weather conditions, etc.).
* **Performance Optimization:** Implements caching of weather forecast data using Redis. Results are stored for 30 minutes to reduce API calls and improve response times for frequently requested locations.

## Technologies Used

* **Geocoder:** For geocoding addresses into coordinates.
* **open_meteo Ruby Gem:** A client library for interacting with the Open-Meteo API.
* **Redis:** An in-memory data structure store used for caching.

## Prerequisites

* **Redis:** Ensure Redis server is installed and running. You can usually install it via your system's package manager (e.g., `apt-get install redis-server` on Debian/Ubuntu, `brew install redis` on macOS).
* **Geocoder Configuration (Optional):** Geocoder can use various geocoding services. Depending on your needs and usage volume, you might need to configure an API key for a specific service (e.g., Google Maps Geocoding API). Refer to the [Geocoder documentation](https://github.com/alexreisner/geocoder) for configuration details.

## Setup

1.  **Installation:**
    ```bash
    bundle install
    ```

3.  **Configure Redis (if not default):**
    If your Redis server is running on a non-default host or port, update the Redis configuration in your Rails application. You can usually find this in `config/environments/development.rb`, `config/environments/test.rb`, and potentially create a `config/environments/production.rb` if needed. Look for lines related to `config.cache_store` and adjust the Redis URL if necessary.

    Example:
    ```ruby
    # config/environments/development.rb
    config.cache_store = :redis_cache_store, { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
    ```
    You might need to set the `REDIS_URL` environment variable or directly modify the URL.

4.  **Database Setup (this doesnt need any database setup):**

5.  **Run the development server:**
    ```bash
    rails server
    ```

    The application should now be accessible at `http://localhost:3000` (or the port specified in your Rails configuration).

## Usage

To get a weather forecast, navigate to Hompage . You will likely have a form or an endpoint that accepts either a `location` parameter (for city names or addresses) or separate `latitude` and `longitude` parameters.

The application will then:

1.  Parse the provided location information.
2.  Use Geocoder to get the latitude and longitude if a city name or address is provided.
3.  Check the Redis cache for a recent forecast for those coordinates.
4.  If a cached forecast exists and is not older than 30 minutes, it will be returned.
5.  Otherwise, it will query the Open-Meteo API using the `open_meteo` gem.
6.  The retrieved weather data will be displayed.
7.  The new forecast data will be stored in the Redis cache with a 30-minute expiration.

## Running Tests

```bash
bundle exec rspec

