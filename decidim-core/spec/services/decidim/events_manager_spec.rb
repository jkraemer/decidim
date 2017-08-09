# frozen_string_literal: true

require "spec_helper"

describe Decidim::EventsManager do
  describe "#publish" do
    let(:event) { "my.event" }
    let(:event_class) { Decidim::BaseEvent }
    let(:followable) { double }

    it "delegates the params to ActiveSupport::Notifications" do
      expect(ActiveSupport::Notifications)
        .to receive(:publish)
        .with(event, event_class: "decidim/base_event", followable: followable)

      described_class.publish(event: event, event_class: event_class, followable: followable)
    end
  end

  describe "#subscribe" do
    let(:event) { "my.event" }
    let(:block) { proc { "Hello world" } }

    it "delegates the params to ActiveSupport::Notifications" do
      expect(ActiveSupport::Notifications)
        .to receive(:subscribe)
        .with(event, &block)

      described_class.subscribe(event, &block)
    end
  end
end
