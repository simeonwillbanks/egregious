require 'spec_helper'
require "active_record"

describe ActiveRecord do
  context "when listing error classes" do
    it "has them configured corrctly" do
      expect(exception_codes[ActiveRecord::AttributeAssignmentError]).to eq(Egregious.status_code(:bad_request))
      expect(exception_codes[ActiveRecord::MultiparameterAssignmentErrors]).to eq(Egregious.status_code(:bad_request))
      expect(exception_codes[ActiveRecord::ReadOnlyRecord]).to eq(Egregious.status_code(:forbidden))
      expect(exception_codes[ActiveRecord::RecordInvalid]).to eq(Egregious.status_code(:bad_request))
      expect(exception_codes[ActiveRecord::RecordNotFound]).to eq(Egregious.status_code(:not_found))
      expect(exception_codes[ActiveRecord::UnknownAttributeError]).to eq(Egregious.status_code(:bad_request))

      if rails_version_lt_eq(3)
        expect(exception_codes[ActiveRecord::HasAndBelongsToManyAssociationForeignKeyNeeded]).to eq(Egregious.status_code(:bad_request))
      end

      if rails_version_lt_eq(4)
        expect(exception_codes[ActiveRecord::ReadOnlyAssociation]).to eq(Egregious.status_code(:forbidden))
      end
    end
  end
end
