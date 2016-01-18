if defined?(ChefSpec)
  def create_opt(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:opt, :create, resource_name)
  end

  def delete_opt(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:opt, :delete, resource_name)
  end
end
