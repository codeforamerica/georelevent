require 'app/services/channels'

module Citygram
  module Routes
    class Subscriptions < Grape::API
      version 'v1', using: :header, vendor: 'citygram'
      format :json

      rescue_from Sequel::NoMatchingRow do
        Rack::Response.new({error: 'not found'}.to_json, 404)
      end

      desc 'Retrieve a subscription'

      params do
        requires :id, type: Integer
      end

      get '/subscriptions/:id' do
        Subscription.first!(id: params[:id])
      end

      desc 'Create a new subscription'

      params do
        requires :subscription, type: Hash do
          requires :publisher_id, type: Integer
          requires :channel, type: String, values: Citygram::Services::Channels.available.map(&:to_s)
          requires :geom, type: String
          optional :phone_number, type: String
          optional :email_address, type: String
          optional :webhook_url, type: String
          mutually_exclusive :phone_number, :email_address, :webhook_url
        end
      end

      post '/subscriptions' do
        Subscription.create!(params[:subscription]).tap do |subscription|
          Citygram::Workers::SubscriptionConfirmation.perform_async(subscription.id)
        end
      end
    end
  end
end
