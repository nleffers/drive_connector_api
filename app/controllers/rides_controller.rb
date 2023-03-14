# Controller for Rides
class RidesController < ApplicationController
  include RideScoreHelper

  # Returns a list of rides sorted by their scores in relation to the current Driver
  def search_open_rides
    # Get open rides
    rides = Ride.open_rides

    # Get each ride's score
    ride_scores = get_ride_scores(rides)

    # Sort results by score, best to worst
    ride_scores.sort! { |a, b| b[:score] <=> a[:score] }

    render json: ride_scores, status: :ok
  rescue OpenRouteServiceApi::RouteSearchError, ActiveRecord::RecordNotFound
    head :bad_request
  end

  private

  # Get ride score from either Redis or API call
  def get_ride_scores(rides)
    rides.map do |ride|
      {
        id: ride.id,
        score: ride_score(ride)
      }
    end
  end

  # Get Ride's score for given driver either from Redis cache or a calculation
  def ride_score(ride)
    Rails.cache.read("driver_#{driver_params[:driver_id]}_ride_#{ride.id}") || calculate_and_cache_score(ride)
  end

  def driver_params
    params.permit(:driver_id)
  end
end
