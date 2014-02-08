set :deploy_env, 'production'
set :rails_env, 'production'
set :branch, "master"
set :deploy_to, "/var/www/#{application}/production"

namespace :deploy do
  task :restart, :except => { :no_release => true } do
    run "#{sudo} /etc/init.d/kolhacampus -e production upgrade"
  end
end