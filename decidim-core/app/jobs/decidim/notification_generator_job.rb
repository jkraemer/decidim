# frozen_string_literal: true

module Decidim
  class NotificationGeneratorJob < ApplicationJob
    queue_as :decidim_events

    def perform(event, followable)
      NotificationGenerator.new(event, followable).generate
    end
  end
end
