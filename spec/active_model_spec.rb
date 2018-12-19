require 'spec_helper'
require "active_model"

describe ActiveModel do
  context "when listing error classes" do
    it "has them configured corrctly" do
      expect(exception_codes[ActiveModel::MissingAttributeError]).to eq(Egregious.status_code(:bad_request))
    end
  end
end
