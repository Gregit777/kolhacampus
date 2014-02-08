require "rvm/capistrano"
require 'bundler/capistrano'

set :rvm_ruby_string, '2.0.0-p247@kolhacampus'
set :rvm_type, :system
set :rvm_path, '/usr/local/rvm'
set :stages, %w(production staging)
set :default_stage, "production"
require 'capistrano/ext/multistage'

set :application, "kolhacampus"
set :user, "106fm"
set :group, "www-data"

set :scm, :git
set :repository, "file:///home/106fm/repos/kolhacampus"
set :local_repository, File.expand_path('../../',__FILE__)

set :deploy_via, :remote_cache
set :git_shallow_clone, 1
set :use_sudo, false
set :keep_releases, 5
#ssh_options[:forward_agent] = true
default_run_options[:pty] = true

server "10.50.10.9", :app, :web, :db, :primary => true

set :bundle_flags,    "--deployment"
arr = fetch(:shared_children)
arr.concat(['tmp','public/uploads'])
arr.delete('tmp/pids')
arr.delete('public/system')
set :shared_children, arr

# if you want to clean up old releases on each deploy uncomment this:
after "deploy:restart", "deploy:cleanup"
before "deploy:assets:precompile", "deploy:copy_config"
before "deploy:assets:precompile", "deploy:force_recompile"

namespace :deploy do

  # override setup task and add tmp/* to shared dirs
  task :setup, :except => { :no_release => true } do
    dirs = [deploy_to, releases_path, shared_path]
    dirs += shared_children.map { |d| File.join(shared_path, d) }
    run "#{try_sudo} mkdir -p #{dirs.join(' ')}"
    run "#{try_sudo} chmod g+w #{dirs.join(' ')}" if fetch(:group_writable, true)
    tmp_dirs = ['pids','cache','sockets', 'session', 'config'].map { |d| File.join(shared_path, 'tmp', d) }
    run "#{try_sudo} mkdir -p #{tmp_dirs.join(' ')}"
  end

  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    # mkdir -p is making sure that the directories are there for some SCM's that don't
    # save empty folders
    run <<-CMD
      rm -rf #{latest_release}/log #{latest_release}/public/system #{latest_release}/tmp &&
      mkdir -p #{latest_release}/public
    CMD
    shared_children.map do |d|
      run "ln -s #{shared_path}/#{d} #{latest_release}/#{d}"
    end

  end

  task :force_recompile, :except => { :no_release => true } do
    patterns = %w(html views_preloader* vendor*)
    stage = fetch :stage, 'production'
    removables = patterns.map{|pt| "#{latest_release}/public/assets/apps/mobile/#{pt}"}
    removables << "#{latest_release}/tmp/cache/assets/#{stage}/sprockets/"
    run "rm -rf #{removables.join(' ')}"
  end

  task :copy_config, :except => { :no_release => true } do
    run "cp #{shared_path}/config/database.yml #{latest_release}/config/database.yml"
    run "cp #{shared_path}/config/secret_token.rb #{latest_release}/config/initializers/secret_token.rb"
    run "cp #{shared_path}/config/twitter.rb #{latest_release}/config/initializers/twitter.rb"
  end

end