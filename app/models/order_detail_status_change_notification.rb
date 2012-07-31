class OrderDetailStatusChangeNotification < ActiveRecord::Observer
  observe :order_detail
  
  def after_save(order_detail)
  	return unless order_detail.order_status_id_changed?
    old_status = order_detail.order_status_id_was ? OrderStatus.find(order_detail.order_status_id_was) : nil
    new_status = order_detail.order_status
    hooks_to_run = self.class.status_change_hooks[new_status.downcase_name.to_sym]
    hooks_to_run.each { |hook| hook.on_status_change(order_detail, old_status, new_status) } if hooks_to_run
  end

  private

  def self.status_change_hooks
    hash = Settings.try(:order_details).try(:status_change_hooks).try(:to_hash) || {}
    new_hash = {}
    hash.each do |status,classes_listing|
      hooks = []
      Array.wrap(classes_listing).each do |class_definition|
        hooks << build_hook(class_definition)
      end
      new_hash[status] = hooks
    end
    new_hash
  end

  def self.build_hook(class_definition)
    if class_definition.respond_to? :to_hash
      hash = class_definition.to_hash
      clazz = hash.delete(:class).constantize
    else
      hash = {}
      clazz = class_definition.constantize
    end
    # Create a new istance and set settings if the class has that setter
    inst = clazz.new
    inst.settings = hash if inst.respond_to?(:settings=)
    inst
  end
end
