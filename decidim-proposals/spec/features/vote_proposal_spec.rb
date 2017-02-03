# frozen_string_literal: true
require "spec_helper"

describe "Vote Proposal", type: :feature do
  include_context "feature"
  let(:manifest_name) { "proposals" }

  let!(:proposals) { create_list(:proposal, 3, feature: feature) }
  let!(:proposal) { Decidim::Proposals::Proposal.where(feature: feature).first }
  let!(:user) { create :user, :confirmed, organization: organization }

  let!(:feature) do
    create(:proposal_feature,
      manifest: manifest,
      participatory_process: participatory_process)
  end

  context "when votes are not enabled" do
    it "doesn't show the vote proposal button and counts" do
      expect(page).not_to have_css('.card__button', text: "Vote")
      expect(page).not_to have_css('.card__support__data span', text: "0 VOTES")
    end
  end

  context "when votes are enabled" do
    let!(:feature) do
      create(:proposal_feature,
        :with_votes_enabled,
        manifest: manifest,
        participatory_process: participatory_process)
    end

    context "when the user is not logged in" do
      it "should be given the option to sign in" do
        visit_feature

        within ".card__support", match: :first do
          page.find('.card__button').click
        end

        expect(page).to have_css('#loginModal', visible: true)
      end
    end

    context "when the user is logged in" do
      before do
        login_as user, scope: :user
        visit_feature
      end

      context "when the proposal is not voted yet" do
        it "should be able to vote the proposal" do
          within "#proposal-#{proposal.id}-vote-button" do
            page.find('.card__button').click
            expect(page).to have_css('.card__button.success', text: "Already voted")
          end

          within "#proposal-#{proposal.id}-votes-count" do
            expect(page).to have_content("1 VOTE")
          end
        end
      end

      context "when the proposal is already voted" do
        before do
          create(:proposal_vote, proposal: proposal, author: user)
          visit_feature
        end

        it "should not be able to vote it again" do
          within "#proposal-#{proposal.id}-vote-button" do
            expect(page).to have_css('.card__button.success', text: "Already voted")
            page.find('.card__button').click
          end

          within "#proposal-#{proposal.id}-votes-count" do
            expect(page).to have_content("1 VOTE")
          end
        end
      end

      context "when the feature has a vote limit" do
        let(:vote_limit) { 10 }

        let!(:feature) do
          create(:proposal_feature,
            :with_votes_enabled,
            :with_vote_limit,
            vote_limit: vote_limit,
            manifest: manifest,
            participatory_process: participatory_process)
        end

        context "when the proposal is not voted yet" do
          it "should update the remaining votes counter" do
            within "#proposal-#{proposal.id}-vote-button" do
              page.find('.card__button').click
              expect(page).to have_css('.card__button.success')
            end

            expect(page).to have_content("REMAINING 9 VOTES")
          end
        end

        context "when the proposal is already voted" do
          before do
            create(:proposal_vote, proposal: proposal, author: user)
            visit_feature
          end

          it "should be able to undo the vote" do
            within "#proposal-#{proposal.id}-vote-button" do
              expect(page).to have_css('.card__button.success')
              page.find('.card__button').click
            end

            expect(page).to have_content("REMAINING 10 VOTES")
          end
        end

        context "when the user has reached the votes limit" do
          let(:vote_limit) { 1 }

          before do
            create(:proposal_vote, proposal: proposal, author: user)
            visit_feature
          end

          it "should not be able to vote other proposals" do
            expect(page).to have_css('.card__button[disabled]', count: 2)
          end

          context "when votes are blocked" do
            let!(:feature) do
              create(:proposal_feature,
                :with_votes_blocked,
                manifest: manifest,
                participatory_process: participatory_process)
            end

            it "shows the vote count but not the vote button" do
              expect(page).to have_css('.card__support__data', text: "1 VOTE")
              expect(page).to have_content("Voting disabled")
            end
          end
        end
      end
    end
  end
end
