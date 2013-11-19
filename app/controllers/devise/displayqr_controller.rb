class Devise::DisplayqrController < DeviseController
  prepend_before_filter :authenticate_scope!, :only => [:show,:update]

  include Devise::Controllers::Helpers

  def show
    if not resource.nil? and not resource.gauth_secret.nil?
      render :show
    else
      sign_in scope, resource, :bypass => true
      redirect_to stored_location_for(scope) || :root
    end
  end

  def update
    wants_gauth = params[resource_name]['gauth_enabled'].to_i > 0
    can_update = if wants_gauth
      resource.assign_tmp
      resource.validate_token(params['token'].to_i)
    else
      true
    end
    if can_update and resource.set_gauth_enabled(params[resource_name])
      set_flash_message :notice, "Status Updated!"
      sign_in scope, resource, :bypass => true
      redirect_to stored_location_for(scope) || :root
    else
      msg = (wants_gauth and not can_update) ? "Token was incorrect" : "Status update failed"
      set_flash_message :error, msg
      render :show
    end
  end

  private
  def scope
    resource_name.to_sym
  end

  def authenticate_scope!
    send(:"authenticate_#{resource_name}!")
    self.resource = send("current_#{resource_name}")
  end
end
