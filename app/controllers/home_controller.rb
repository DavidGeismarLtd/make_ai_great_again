class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index ]
  skip_before_action :set_current_tenant, only: [ :index ]

  def index
  end
end
