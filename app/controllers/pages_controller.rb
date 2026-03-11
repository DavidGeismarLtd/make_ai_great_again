# frozen_string_literal: true

# Controller for static pages (privacy, terms, guides, etc.)
class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:privacy, :terms, :guides]
  skip_before_action :set_current_tenant, only: [:privacy, :terms, :guides]

  def privacy
    # Privacy Policy page
  end

  def terms
    # Terms of Service page
  end

  def guides
    # Guides and Documentation page
  end
end

