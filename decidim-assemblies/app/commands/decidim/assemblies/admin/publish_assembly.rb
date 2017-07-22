# frozen_string_literal: true

module Decidim
  module Assemblies
    module Admin
      # A command that sets an assembly as published.
      class PublishAssembly < Rectify::Command
        # Public: Initializes the command.
        #
        # assembly - A Assembly that will be published
        def initialize(assembly)
          @assembly = assembly
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the data wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if assembly.nil? || assembly.published?

          assembly.publish!
          broadcast(:ok)
        end

        private

        attr_reader :assembly
      end
    end
  end
end
