require 'chef/resource/lwrp_base'

class Chef
  class Resource
    class Opt < Chef::Resource::LWRPBase
      self.resource_name = :opt
      actions :create, :delete
      default_action :create

      attribute :name, kind_of: String, name_attribute: true
      attribute :repo, kind_of: String, default: 'git@github.com:ucla/opt.git'
      attribute :revision, kind_of: String, default: 'master'
      attribute :port, kind_of: Integer, default: 3000
      attribute :run_user, kind_of: String, default: 'opt'
      attribute :run_group, kind_of: String, default: 'opt'
      attribute :db_host, kind_of: String, default: '127.0.0.1'
      attribute :db_port, kind_of: Integer, default: 3306
      attribute :db_name, kind_of: String, default: 'opt' # set to name attr?
      attribute :db_user, kind_of: String, default: 'opt'
      attribute :db_password, kind_of: String, default: 'tsktsk'
      attribute :es_host, kind_of: String, default: '127.0.0.1'
      attribute :es_port, kind_of: Integer, default: 9200
      attribute :es_index_prefix, kind_of: String, default: 'opt-'
      attribute :deploy_path, kind_of: String, required: true
      attribute :bundler_path, kind_of: String, default: nil
      attribute :rails_env, kind_of: String, default: 'production'
      attribute :deploy_key, kind_of: String, required: true
      attribute :shib_secret, kind_of: String, default: nil
      attribute :shib_client_name, kind_of: String, default: nil
      attribute :shib_site, kind_of: String, default: nil
      attribute :secret, kind_of: String, required: true
      attribute :recaptcha_public_key , kind_of: String, default: nil
      attribute :recaptcha_private_key , kind_of: String, default: nil
    end
  end
end
