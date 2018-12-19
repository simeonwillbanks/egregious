require "egregious/version"
require "egregious/extensions/exception"
require 'rack'

require 'abstract_controller/base'
require 'action_controller'
require 'action_controller/metal/request_forgery_protection'
require 'active_model'
require 'active_record'
require 'active_record/errors'
require 'active_record/associations'
require 'active_record/validations'


module Egregious

  # Must sub out (Experimental) to avoid a class name: VariantAlsoNegotiates(Experimental)
  def self.clean_class_name(str)
    str.gsub(/\s|-|'/,'').sub('(Experimental)','')
  end

  # use these exception to control the code you are throwing from you code
  # all http statuses have an exception defined for them
  Rack::Utils::HTTP_STATUS_CODES.each do |key, value|
    class_eval "class #{Egregious.clean_class_name(value)} < StandardError; end"
  end

  def self.status_code(status)
    if status.is_a?(Symbol)
      key = status.to_s.split("_").map {|e| e.capitalize}.join(" ")
      Rack::Utils::HTTP_STATUS_CODES.invert[key] || 500
    else
      status.to_i
    end
  end

  def status_code(status)
    Egregious.status_code(status)
  end


  # internal method that loads the exception codes
  def self._load_exception_codes

    # by default if there is not mapping they map to 500/internal server error
    exception_codes = {
        SecurityError=>status_code(:forbidden)
    }
    # all status codes have a exception class defined
    Rack::Utils::HTTP_STATUS_CODES.each_value do |value|
      exception_codes.merge!(eval("Egregious::#{Egregious.clean_class_name(value)}")=>value.downcase.gsub(/\s|-/, '_').to_sym)
    end

    require 'egregious/extensions/mongoid' if defined?(Mongoid)

    {
      "AbstractController::ActionNotFound" => :bad_request,
      "ActionController::InvalidAuthenticityToken" => :bad_request,
      "ActionController::MethodNotAllowed" => :not_allowed,
      "ActionController::MissingFile" => :not_found,
      "ActionController::RoutingError" => :bad_request,
      "ActionController::UnknownHttpMethod" => :not_allowed,
      "ActionController::UnknownController" => :bad_request,
      "ActiveModel::MissingAttributeError" => :bad_request,
      "ActiveRecord::AttributeAssignmentError" => :bad_request,
      "ActiveRecord::MultiparameterAssignmentErrors" => :bad_request,
      "ActiveRecord::ReadOnlyAssociation" => :forbidden,
      "ActiveRecord::ReadOnlyRecord" => :forbidden,
      "ActiveRecord::RecordInvalid" => :bad_request,
      "ActiveRecord::RecordNotFound" => :not_found,
      "ActiveRecord::UnknownAttributeError" => :bad_request,
      "ActiveRecord::HasAndBelongsToManyAssociationForeignKeyNeeded" => :bad_request,
      "Mongoid::Errors::InvalidFind" => :bad_request,
      "Mongoid::Errors::DocumentNotFound" => :not_found,
      "Mongoid::Errors::Validations" => :unprocessable_entity,
      "Mongoid::Errors::ReadonlyAttribute" => :forbidden,
      "Mongoid::Errors::UnknownAttribute" => :bad_request,
      "Warden::NotAuthenticated" => :unauthorized,
      # technically this should be forbidden, but for some reason cancan returns AccessDenied when you are not logged in
      "CanCan::AccessDenied" => :unauthorized,
      "CanCan::AuthorizationNotPerformed" => :unauthorized,
    }.each do |constant_str, code|
      if Object.const_defined?(constant_str)
        exception_codes.merge!(Object.const_get(constant_str) => status_code(code))
      end
    end

    @@exception_codes = exception_codes
  end

  @@exception_codes = self._load_exception_codes
  @@root = defined?(Rails) ? Rails.root : nil

  # exposes the root of the app
  def self.root
    @@root
  end

  # set the root directory and stack traces will be cleaned up
  def self.root=(root)
    @@root=root
  end

  # a little helper to help us clean up the backtrace
  # if root is defined it removes that, for rails it takes care of that
  def clean_backtrace(exception)
    if backtrace = exception.backtrace
      if Egregious.root
        backtrace.map { |line|
          line.sub Egregious.root.to_s, ''
        }
      else
        backtrace
      end
    end
  end

  # this method exposes the @@exception_codes class variable
  # allowing someone to re-configure the mapping. For example in a rails initializer:
  # Egregious.exception_codes = {NameError => "503"}   or
  # If you want the default mapping and then want to modify it you should call the following:
  # Egregious.exception_codes.merge!({MyCustomException=>"500"})
  def self.exception_codes
    @@exception_codes
  end

  # this method exposes the @@exception_codes class variable
  # allowing someone to re-configure the mapping. For example in a rails initializer:
  # Egregious.exception_codes = {NameError => "503"}   or
  # If you want the default mapping and then want to modify it you should call the following:
  # Egregious.exception_codes.merge!({MyCustomException=>"500"})
  def self.exception_codes=(exception_codes)
    @@exception_codes=exception_codes
  end

  # this method will auto load the exception codes if they are not set
  # by an external configuration call to self.exception_code already
  # it is called by the status_code_for_exception method
  def exception_codes
    return Egregious.exception_codes
  end

  # this method will lookup the exception code for a given exception class
  # if the exception is not in our map then see if the class responds to :http_status
  # if not it will return 500
  def status_code_for_exception(exception)
      Egregious.status_code_for_exception(exception)
  end

  def self.status_code_for_exception(exception)
    status_code(self.exception_codes[exception.class]  ||
               (exception.respond_to?(:http_status) ? (exception.http_status||:internal_server_error) : :internal_server_error))
  end

  # this is the method that handles all the exceptions we have mapped
  def egregious_exception_handler(exception)
    egregious_flash(exception)
    egregious_log(exception)
    egregious_respond_to(exception)
  end

  # override this if you want your flash to behave differently
  def egregious_flash(exception)
    flash.now[:alert] = exception.message
  end

  # override this if you want your logging to behave differently
  def egregious_log(exception)
    logger.fatal(
        "\n\n" + exception.class.to_s + ' (' + exception.message.to_s + '):\n    ' +
            clean_backtrace(exception).join("\n    ") +
            "\n\n")
    notify_airbrake(exception)
  end

   # override this if you want to control what gets sent to airbrake
  def notify_airbrake(exception)
    # tested with airbrake 4.3.5 and 5.0.5
    if defined?(Airbrake)
      if(Airbrake.respond_to?(:notify_or_ignore))
        env['airbrake.error_id'] = Airbrake.notify_or_ignore(exception, airbrake_request_data) # V4
      else
        # V5
        notice = Airbrake::Rack::NoticeBuilder.new(env).build_notice(exception)
        env['airbrake.error_id'] = Airbrake.notify(notice)
      end
    end
  end

  # override this if you want to change your respond_to behavior
  def egregious_respond_to(exception)
    respond_to do |format|
      status = status_code_for_exception(exception)
      format.xml { render :xml=> exception.to_xml, :status => status }
      format.json { render :json=> exception.to_json, :status => status }
      # render the html page for the status we are returning it exists...if not then render the 500.html page.
      format.html {
        # render the rails exception page if we are local/debugging
        if(Rails.application.config.consider_all_requests_local || request.local?)
          raise exception
        else
          render :file => File.exists?(build_html_file_path(status)) ?
                                      build_html_file_path(status) : build_html_file_path('500'),
                           :status => status
        end
      }
    end
  end

  def build_html_file_path(status)
    File.join(Rails.root, 'public', "#{status_code(status)}.html")
  end

  def self.included(base)
    base.class_eval do
      rescue_from 'Exception' , :with => :egregious_exception_handler
    end
  end
end
