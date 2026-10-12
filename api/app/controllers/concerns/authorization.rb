module Authorization
  extend ActiveSupport::Concern

  class Forbidden < StandardError; end

  private

  def require_manager!
    raise Forbidden, "Bu işlem yalnızca yöneticiler (manager) içindir" unless current_user&.manager?
  end
end
