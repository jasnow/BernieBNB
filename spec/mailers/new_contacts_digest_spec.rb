# coding: utf-8
require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'New Contacts Digest' do
    include EmailSpec::Helpers
    include EmailSpec::Matchers
    include Rails.application.routes.url_helpers
  end

  before(:each) do
    Geocoder.configure(:lookup => :test)

    Geocoder::Lookup::Test.add_stub(
      "11211", [{'latitude' => 40.7093358, 'longitude' => -73.9565551}]
    )

    @host = FactoryGirl.create(:user, email: 'joe@gmail.com', first_name: "Joe", phone: "6541537596")

    @visitor = FactoryGirl.create(:user, email: "bart@yahoo.com", first_name: "Bart", phone: "666-874-9632")

    start_date = '02-03-2956'
    end_date = '02-06-2956'

    @visit = Visit.create!(start_date: start_date, end_date: end_date, zipcode: '11211', num_travelers: 1, user_id: @visitor.id)

    @hosting = Hosting.create!(zipcode: @visit.zipcode, max_guests: @visit.num_travelers, host_id: @host.id)
    @host_data = [{ hosting: @hosting, host: @host}]

    @email = UserMailer.new_contacts_digest(@visit, @visitor, @host_data).deliver_now
  end

  it 'should deliver to the correct email address' do
    expect(@email).to deliver_to('joe@gmail.com')
  end

  it 'should have the correct subject' do
    expect(@email).to have_subject(/#{t('general.bernie').capitalize} BNB - You've been contacted!/)
  end

  it 'should mention the correct host' do
    expect(@email).to have_body_text(/Hi #{@host.first_name}/)
  end

  it 'should mention the correct visit information' do
    expect(@email).to have_body_text(/You’ve been contacted by a traveler!/)
    expect(@email).to have_body_text(/#{@visitor.first_name}/)
    expect(@email).to have_body_text(/#{@visitor.phone}/)
    expect(@email).to have_body_text(/#{@visitor.email}/)
    expect(@email).to have_body_text(/#{@visit.start_and_end_dates}/)
    expect(@email).to have_body_text(/Group of #{@visit.num_travelers}/)
  end

  it 'should contain the correct link' do
    link = ActionController::Base.helpers.link_to(t('general.bernie').capitalize + " BNB - Host", edit_hosting_url(@hosting))
    expect(@email).to have_body_text(/#{link}/)
  end
end
