ActiveAdmin.register User do

  menu :if => proc { current_user.is? :admin }

  index do
    column :first_name
    column :last_name
    default_actions
  end

  filter :first_name
  filter :last_name

  form :partial => 'form'

end
