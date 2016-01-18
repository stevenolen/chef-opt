# install ruby with rbenv, java, npm, git, mysql-server and set up db.
node.default['rbenv']['rubies'] = ['2.1.7']
include_recipe 'ruby_build'
include_recipe 'ruby_rbenv::system'
include_recipe 'nodejs::npm'
package 'java-1.7.0-openjdk'
package 'git'
rbenv_global '2.1.7'
rbenv_gem 'bundle'

mysql_service 'default' do
  port '3306'
  version '5.6'
  initial_root_password 'changeme'
  action [:create, :start]
end

execute 'add test db info' do
  command "sleep 5s; /usr/bin/mysql -h 127.0.0.1 -uroot -pchangeme -e \"CREATE DATABASE IF NOT EXISTS opt; GRANT ALL ON opt.* to 'opt' identified by 'tsktsk';\""
end

opt_deploy_key = data_bag_item('deploy', 'opt')

# opt service block
opt 'default' do
  revision 'master'
  es_host 'elasticsearch' # /etc/hosts from linked docker container!
  deploy_path '/var/opt'
  bundler_path '/usr/local/rbenv/shims'
  deploy_key opt_deploy_key['private']
end