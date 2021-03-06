# frozen_string_literal: true

module Decidim
  # This controller allows users to create and destroy their authorizations. It
  # shouldn't be necessary to expand it to add new authorization schemes.
  class AuthorizationsController < Decidim::ApplicationController
    helper_method :handler, :handlers, :stored_location
    before_action :valid_handler, only: [:new, :create]

    include Decidim::UserProfile
    helper Decidim::DecidimFormHelper
    helper Decidim::AuthorizationFormHelper

    layout "layouts/decidim/user_profile", only: [:index]
    skip_before_action :store_current_location

    def new; end

    def index
      @authorizations = current_user.authorizations
    end

    def first_login
      if handlers.length == 1
        redirect_to(
          action: :new,
          handler: handlers.first.handler_name,
          redirect_url: account_path
        )
      end
    end

    def create
      AuthorizeUser.call(handler) do
        on(:ok) do
          flash[:notice] = t("authorizations.create.success", scope: "decidim")
          redirect_to params[:redirect_url] || stored_location_for(current_user) || authorizations_path
        end

        on(:invalid) do
          flash[:alert] = t("authorizations.create.error", scope: "decidim")
          render action: :new
        end
      end
    end

    protected

    def handler
      @handler ||= AuthorizationHandler.handler_for(handler_name, handler_params)
    end

    def stored_location
      location = stored_location_for(current_user)
      store_location_for(current_user, location)
      location
    end

    def handler_params
      (params[:authorization_handler] || {}).merge(user: current_user)
    end

    def handler_name
      params[:handler] || params.dig(:authorization_handler, :handler_name)
    end

    def valid_handler
      return true if handler

      logger.warn "Invalid authorization handler given: #{handler_name} doesn't"\
        "exist or you haven't added it to `Decidim.authorization_handlers`"

      redirect_to(authorizations_path) && (return false)
    end

    def handlers
      @handlers ||= available_authorization_handlers.reject do |handler|
        authorized_handlers.include?(handler.handler_name)
      end
    end

    def authorized_handlers
      current_user.authorizations.map(&:name)
    end
  end
end
