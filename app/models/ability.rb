class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    if user.roles.size == 0 && !user.new_record?
      can :manage, User, :id => user.id
    end
    if user.is? :admin
      can :manage, :all
    else
      can :read, ActiveAdmin::Page, :name => "Dashboard"
    end
  end

end
