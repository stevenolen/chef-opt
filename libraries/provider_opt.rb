require 'chef/provider/lwrp_base'
require_relative 'helpers'

class Chef
  class Provider
    class Opt < Chef::Provider::LWRPBase # rubocop:disable ClassLength
      # Chef 11 LWRP DSL Methods
      use_inline_resources if defined?(use_inline_resources)

      def whyrun_supported?
        true
      end

      # Mix in helpers from libraries/helpers.rb
      include OptCookbook::Helpers

      action :create do
        # user
        group "#{new_resource.name} :create opt" do
          append true
          group_name new_resource.run_group
          action :create
        end

        user "#{new_resource.name} :create opt" do
          username new_resource.run_user
          gid 'opt' if new_resource.run_user == 'opt'
          action :create
        end
        # init file for service, abstract to support deb and rhel7
        template "/etc/init.d/opt-#{new_resource.name}" do
          owner 'root'
          group 'root'
          mode '0755'
          source 'sysvinit.erb'
          cookbook 'opt'
          variables(config: new_resource)
        end

        # add shared dirs for chef deploy
        directory "#{new_resource.deploy_path}/shared" do
          recursive true
          owner new_resource.run_user
          group new_resource.run_group
        end

        %w(config pids log).each do |d|
          directory "#{new_resource.deploy_path}/shared/#{d}" do
            recursive true
            owner new_resource.run_user
            group new_resource.run_group
          end
        end

        # opt is a private repo, add deploy key.
        file "#{new_resource.deploy_path}/shared/deploy_key" do
          owner new_resource.run_user
          group new_resource.run_group
          mode '0700'
          content new_resource.deploy_key
        end

        file "#{new_resource.deploy_path}/shared/deploy_ssh_wrapper.sh" do
          owner new_resource.run_user
          group new_resource.run_group
          mode '0700'
          content "#!/usr/bin/env bash\n/usr/bin/env ssh -o \"StrictHostKeyChecking=no\" -i \"#{new_resource.deploy_path}/shared/deploy_key\" $1 $2"
        end

        # database.yml
        template "#{new_resource.deploy_path}/shared/config/database.yml" do
          source 'database.yml.erb'
          cookbook 'opt'
          owner new_resource.run_user
          group new_resource.run_group
          variables(config: new_resource)
          notifies :restart, "service[opt-#{new_resource.name}]", :delayed
        end

        # secrets (hardcoded in source?)
        # template "#{new_resource.deploy_path}/shared/config/secrets.yml" do
        #   source 'secrets.yml.erb'
        #   cookbook 'opt'
        #   owner new_resource.run_user
        #   group new_resource.run_group
        #   variables(config: new_resource)
        #   notifies :restart, "service[opt-#{new_resource.name}]", :delayed
        # end

        # generate ES config file, only supports one instance currently.
        template "#{new_resource.deploy_path}/shared/config/elasticsearch.yml" do
          source 'elasticsearch.yml.erb'
          cookbook 'opt'
          owner new_resource.run_user
          group new_resource.run_group
          variables(config: new_resource)
          notifies :restart, "service[opt-#{new_resource.name}]", :delayed
        end

        # generate auth config file. for shib integration.
        template "#{new_resource.deploy_path}/shared/config/auth.yml" do
          source 'auth.yml.erb'
          cookbook 'opt'
          owner new_resource.run_user
          group new_resource.run_group
          variables(config: new_resource)
          notifies :restart, "service[opt-#{new_resource.name}]", :delayed
        end

        # required headers for mysql2, imagemagick gem (which gets installed with bundler below)
        # not OS compatible yet, refactor
        %w(mysql-devel sqlite sqlite-devel freetds freetds-devel).each do |pkg|
          package pkg
        end

        # farm out to chef deploy.
        # note namespace "new resource" causes some weird stuff here.
        computed_path = path_plus_bundler
        opt_resource = new_resource
        deploy_branch opt_resource.name do
          deploy_to opt_resource.deploy_path
          repo opt_resource.repo
          revision opt_resource.revision
          ssh_wrapper "#{new_resource.deploy_path}/shared/deploy_ssh_wrapper.sh"
          user opt_resource.run_user
          group opt_resource.run_group
          symlink_before_migrate(
            'config/database.yml' => 'config/database.yml',
            'config/elasticsearch.yml' => 'config/elasticsearch.yml',
            'config/auth.yml' => 'config/auth.yml',
            'bundle' => '.bundle'
          )
          before_migrate do
            execute 'bundle install' do
              environment 'PATH' => computed_path
              cwd release_path
              command "bundle install --path #{opt_resource.deploy_path}/shared/bundle"
            end
            execute 'npm install' do
              cwd release_path
            end
            execute 'block build' do
              environment 'PATH' => computed_path
              cwd release_path
              command 'bundle exec blocks build'
            end
          end
          migrate true
          migration_command "RAILS_ENV=#{opt_resource.rails_env} bundle exec rake db:migrate"
          purge_before_symlink %W(log tmp/pids config/database.yml)
          before_symlink do
            execute 'db:seed' do
              environment 'PATH' => computed_path
              cwd release_path
              command "RAILS_ENV=#{opt_resource.rails_env} bundle exec rake db:seed; touch #{opt_resource.deploy_path}/shared/.seeded"
              not_if { ::File.exist?("#{opt_resource.deploy_path}/shared/.seeded") }
            end
          end
          symlinks(
            'log' => 'log',
            'pids' => 'tmp/pids'
          )
          restart_command "service opt-#{opt_resource.name} restart"
        end

        service "opt-#{new_resource.name}" do
          supports restart: true, status: true
          action [:enable, :start]
        end
      end

      action :delete do
        # stop service
        service "opt-#{new_resource.name}" do
          supports restart: true, status: true
          action [:disable, :stop]
        end

        # delete deploy path and remove init script.
        directory "#{new_resource.deploy_path}" do
          action :delete
        end

        file "/etc/init.d/opt-#{new_resource.name}" do
          action :delete
        end
      end
    end
  end
end
