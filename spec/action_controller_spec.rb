require 'spec_helper'
require "action_controller"

describe ActionController do
  context "when listing error classes" do
    it "has them configured corrctly" do
      expect(exception_codes[AbstractController::ActionNotFound]).to eq(Egregious.status_code(:bad_request))
      expect(exception_codes[ActionController::InvalidAuthenticityToken]).to eq(Egregious.status_code(:bad_request))
      expect(exception_codes[ActionController::MethodNotAllowed]).to eq(Egregious.status_code(:not_allowed))
      expect(exception_codes[ActionController::MissingFile]).to eq(Egregious.status_code(:not_found))
      expect(exception_codes[ActionController::RoutingError]).to eq(Egregious.status_code(:bad_request))
      expect(exception_codes[ActionController::UnknownHttpMethod]).to eq(Egregious.status_code(:not_allowed))

      if rails_version_lt_eq(4)
        expect(exception_codes[ActionController::UnknownController]).to eq(Egregious.status_code(:bad_request))
      end
    end
  end
end
