require 'spec_helper'

describe "walls/edit" do
  before(:each) do
    @wall = assign(:wall, stub_model(Wall))
  end

  it "renders the edit wall form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", wall_path(@wall), "post" do
    end
  end
end
