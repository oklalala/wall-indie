# manage Events for admin
class Admin::EventsController < Admin::BaseController
  def index
    @events = Event.all
  end
end
