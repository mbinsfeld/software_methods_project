require 'spec_helper'

describe User do

  before { @user = User.new(first_name: "Example", last_name: "User", email: "user@example.com",
                            password: "foobar", password_confirmation: "foobar") }

  subject { @user }

  it { should respond_to(:first_name) }
  it { should respond_to(:last_name)}
  it { should respond_to(:name)}
  it { should respond_to(:email) }
  it { should respond_to(:password_digest) }
  it { should respond_to(:password) }
  it { should respond_to(:password_confirmation) }
  it { should respond_to(:authenticate) }
  it { should respond_to(:microposts) }
  it { should respond_to(:wall) }
  it { should respond_to(:relationships)}
  it { should respond_to(:friends)}
  it { should respond_to(:incoming_pending_friends)}
  it { should respond_to(:outgoing_pending_friends)}
  it { should respond_to(:accept_friend) }
  it { should respond_to(:request_friend) }
  it { should respond_to(:unfriend) }
  it { should respond_to(:mutual_friends)}
  it { should respond_to(:comments) }

  it { should be_valid }

  describe "first name specs" do
    describe "when first name is not present" do
      before { @user.first_name = " " }
      it { should_not be_valid }
    end

    describe "when first name is too long" do
      before { @user.first_name = "a" * 51 }
      it { should_not be_valid }
    end
  end

  describe "last name specs" do
    describe "when last name is not present" do
      before { @user.last_name = " " }
      it { should_not be_valid }
    end

    describe "when last name is too long" do
      before { @user.last_name = "a" * 51 }
      it { should_not be_valid }
    end

  end

  describe "email specs" do

    describe "when email is not present" do
      before { @user.email = " " }
      it { should_not be_valid }
    end

    describe "when email format is invalid" do
      it "should be invalid" do
        addresses = %w[user@foo,com user_at_foo.org example.user@foo.
                     foo@bar_baz.com foo@bar+baz.com]
        addresses.each do |invalid_address|
          @user.email = invalid_address
          expect(@user).not_to be_valid
        end
      end
    end

    describe "when email format is valid" do
      it "should be valid" do
        addresses = %w[user@foo.COM A_US-ER@f.b.org frst.lst@foo.jp a+b@baz.cn]
        addresses.each do |valid_address|
          @user.email = valid_address
          expect(@user).to be_valid
        end
      end
    end

    describe "email address with mixed case" do
      let(:mixed_case_email) { "Foo@ExAMPle.CoM" }

      it "should be saved as all lower-case" do
        @user.email = mixed_case_email
        @user.save
        expect(@user.reload.email).to eq mixed_case_email.downcase
      end
    end

    describe "when email address is already taken" do
      before do
        user_with_same_email = @user.dup
        user_with_same_email.email = @user.email.upcase
        user_with_same_email.save
      end

      it { should_not be_valid }
    end
  end

  describe "password specs" do

    describe "when password is not present" do
      before do
        @user = User.new(name: "Example User", email: "user@example.com",
                         password: " ", password_confirmation: " ")
      end
      it { should_not be_valid }
    end

    describe "when password doesn't match confirmation" do
      before { @user.password_confirmation = "mismatch" }
      it { should_not be_valid }
    end

    describe "return value of authenticate method" do
      before { @user.save }
      let(:found_user) { User.find_by_email(@user.email) }

      describe "with valid password" do
        it { should eq found_user.authenticate(@user.password) }
      end

      describe "with invalid password" do
        let(:user_for_invalid_password) { found_user.authenticate("invalid") }

        it { should_not eq user_for_invalid_password }
        specify { expect(user_for_invalid_password).to be_false }
      end
    end

    describe "with a password that's too short" do
      before { @user.password = @user.password_confirmation = "a" * 5 }
      it { should be_invalid }
    end

  end

  describe "micropost associations" do

    before { @user.save }
    let!(:older_micropost) do
      FactoryGirl.create(:micropost, user: @user, wall: @user.wall, created_at: 1.day.ago)
    end
    let!(:newer_micropost) do
      FactoryGirl.create(:micropost, user: @user, wall: @user.wall,  created_at: 1.hour.ago)
    end

    it "should have the right microposts in the right order" do
      expect(@user.microposts.to_a).to eq [newer_micropost, older_micropost]
    end

    it "should destroy associated microposts" do
      microposts = @user.microposts.to_a
      @user.destroy
      expect(microposts).not_to be_empty
      microposts.each do |micropost|
        expect(Micropost.where(id: micropost.id)).to be_empty
      end
    end

    describe "comment assosiations" do
      let!(:commented_micropost) do
        FactoryGirl.create(:micropost, user: @user, wall: @user.wall, created_at: 1.day.ago)
      end
      let!(:older_comment) do
        FactoryGirl.create(:comment, user: @user, micropost: commented_micropost, created_at: 1.day.ago)
      end
      let!(:newer_comment) do
        FactoryGirl.create(:comment, user: @user, micropost: commented_micropost,  created_at: 1.hour.ago)
      end

      it "should have the right comments in the right order" do
        expect(@user.comments.to_a).to eq [older_comment, newer_comment]
      end

      it "should destroy associated comments" do
        comments = @user.comments.to_a
        @user.destroy
        expect(comments).not_to be_empty
        comments.each do |comment|
          expect(Comment.where(id: comment.id)).to be_empty
        end
      end
    end

  end

  describe "relationships specs" do
    describe "outgoing request friend" do
      let(:other_user) { FactoryGirl.create(:user) }
      before do
        @user.save
        @user.request_friend(other_user)
      end

      its(:outgoing_pending_friends) { should include(other_user) }
      its(:incoming_pending_friends) { should_not include(other_user) }
      its(:friends) { should_not include(other_user) }
    end

    describe "incoming request friend" do
      let(:other_user) { FactoryGirl.create(:user) }
      before do
        @user.save
        other_user.request_friend(@user)
      end

      its(:incoming_pending_friends) { should include(other_user) }
      its(:outgoing_pending_friends) { should_not include(other_user) }
      its(:friends) { should_not include(other_user) }
    end

    describe "accept friend" do
      let(:other_user) { FactoryGirl.create(:user) }
      before do
        @user.save
        @user.request_friend(other_user)
        other_user.accept_friend(@user)
      end

      its(:friends) { should include(other_user) }
      its(:outgoing_pending_friends) { should_not include(other_user) }
      its(:incoming_pending_friends) { should_not include(other_user) }

      describe "unfriend" do
        before do
          @user.unfriend(other_user)
        end
        its(:friends) {should_not include(other_user)}
        its(:outgoing_pending_friends) { should_not include(other_user) }
        its(:incoming_pending_friends) { should_not include(other_user) }
      end
    end

  end


end
