require 'spec_helper'
require 'controller_spec_helper'
require 'transaction_search_spec_helper'

describe FacilityStatementsController do
  render_views
  def create_order_details
    @order_detail1 = place_and_complete_item_order(@user, @authable, @account)
    @order_detail2 = place_and_complete_item_order(@user, @authable, @account)
  
    @account2=Factory.create(:credit_card_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']], :facility_id => @authable.id)
    @authable_account2 = @authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @order_detail3 = place_and_complete_item_order(@user, @authable, @account2)
    
    [@order_detail1, @order_detail3].each do |od|
      od.reviewed_at = 1.day.ago
      od.save!
    end
  
  end
  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @user=Factory.create(:user)
    UserRole.grant(@user, UserRole::ADMINISTRATOR)
    @account=Factory.create(:credit_card_account, :account_users_attributes => [Hash[:user => @owner, :created_by => @user, :user_role => 'Owner']], :facility_id => @authable.id)
    @statement=Factory.create(:statement, :facility_id => @authable.id, :created_by => @admin.id, :account => @account)
    @params={ :facility_id => @authable.url_name }
  end


  context 'index' do

    before :each do
      @method=:get
      @action=:index
    end

    it_should_allow_managers_only do
      assigns(:statements).size.should == 1
      assigns(:statements)[0].should == @statement
      should_not set_the_flash
    end

  end

  context "new" do
    before :each do
      @method = :get
      @action = :new
      create_order_details
    end
    
    it_should_allow_managers_only do
      response.should be_success
    end
    
    it "should return the right order details" do
      grant_and_sign_in(@user)
      do_request
      response.should be_success
      assigns(:accounts).should contain_all [@account, @account2]
      assigns(:facility).should == @authable
      assigns(:order_detail_action).should == :send_statements
      (assigns(:order_details) - [@order_detail1, @order_detail3]).should be_empty
    end
    
    it_should_support_searching
  end
  
  context "send_statements" do
    before :each do
      create_order_details
      @method=:post
      @action=:send_statements
      @params.merge!({:order_detail_ids => [@order_detail1.id, @order_detail3.id]})
    end
    
    it_should_allow_managers_only :redirect do
      response.should be_redirect
    end
        
    it "should create and send statements" do
      @order_detail1.reload.reviewed_at.should < Time.zone.now
      @order_detail1.statement.should be_nil
      @order_detail1.price_policy.should_not be_nil
      @order_detail1.account.type.should == 'CreditCardAccount'
      @order_detail1.dispute_at.should be_nil
      
      grant_and_sign_in(@user)
      do_request
      flash[:error].should be_nil
      assigns(:account_statements).should have_key(@account)
      assigns(:account_statements).should have_key(@account2)
      response.should redirect_to :action => :new
    end
    
    context "errors" do
      it "should display an error for no orders" do
        @params[:order_detail_ids] = nil
        grant_and_sign_in(@user)
        do_request
        flash[:error].should_not be_nil
        response.should redirect_to :action => :new
      end
    end
  end

  context 'show' do

    before :each do
      @method=:get
      @action=:show
      @params.merge!(:id => @statement.id)
    end

    it_should_allow_managers_only { assigns(:statement).should == @statement }

  end

end
