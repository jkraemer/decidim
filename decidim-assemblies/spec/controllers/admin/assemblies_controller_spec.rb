# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Assemblies
    module Admin
      describe AssembliesController, type: :controller do
        routes { Decidim::Assemblies::AdminEngine.routes }

        let(:organization) { create(:organization) }
        let(:user) { create(:user, :admin, :confirmed, organization: organization) }

        before do
          @request.env["decidim.current_organization"] = organization
          sign_in user, scope: :user
        end

        describe "GET show" do
          context "assembly in another organization" do
            let!(:external_assembly) { create :assembly }

            it "is not visible to the user" do
              expect do
                get :show, params: { id: external_assembly.id }
              end.to raise_error(ActiveRecord::RecordNotFound)
            end
          end
        end
      end
    end
  end
end
