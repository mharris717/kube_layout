module KubeLayout
  class << self
    def method_missing(sym, *args, &b)
      instance.send(sym, *args, &b)
    end
    attr_accessor :instance
  end

  def self.define(&b)
    self.instance = Top.new
    yield instance
  end

  module DslObj
    def self.included(mod)
      super
      mod.send(:attr_accessor, :name, :parent)
    end
  end

  class Cluster
    include DslObj
    dsl_accessor :loader_vault_path, :kube_context
  end

  class Env
    include DslObj
    dsl_accessor :namespace
  end

  class Secret
    include DslObj
    dsl_accessor :source_type
    def app; parent; end

    def vault_path(env)
      base = parent.cluster_obj.loader_vault_path
      sub = [parent.name, env, name].join("/")
      "#{base}/#{sub}"
    end

    def add_as_file(env, file)
      raise "wrong secret type" unless source_type == 'file'
      path = vault_path(env)
      secret_file = MakeSecretFile.new(
        name: name,
        file: file,
        namespace: app.env(env).namespace
      ).call
      ec "vault write #{path} secret.yml=@#{secret_file}"
    end

    def add_as_env(env, keys)
      raise "wrong secret type" unless source_type == 'env'
      path = vault_path(env)
      secret_file = MakeSecretFileFromEnv.new(
        name: name,
        file: "whatever.yml",
        namespace: app.env(env).namespace,
        vals: keys
      ).call
      ec "vault write #{path} secret.yml=@#{secret_file}"
      # env=#{env} app=#{app.name} namespace=#{app.env(env).namespace} updatedAt='#{Time.now.to_s}' updatedBy='#{me}'
    end
  end

  class App
    include DslObj
    dsl_accessor :cluster
    grouping_dsl_accessor :env, Env
    grouping_dsl_accessor :secret, Secret

    def cluster_obj
      parent.cluster cluster
    end

    def env_secrets
      envs.values.map do |e|
        secrets.values.map do |s|
          EnvSecret.new(secret: s, env: e)
        end
      end.flatten
    end
  end

  class Top
    grouping_dsl_accessor :cluster, Cluster
    grouping_dsl_accessor :app, App
  end

  class EnvSecret
    include FromHash
    attr_accessor :env, :secret, :updated_at

    def name
      "#{env.name}:#{secret.name}"
    end

    def vault_path
      secret.vault_path(env.name)
    end

    def exists?
      res = ec("vault read #{vault_path}", silent: true)
      if res =~ /updatedAt(.+)/
        str = $1.strip
        self.updated_at = Time.parse(str)
      end
      true
    rescue => exp
      puts exp.message
      false
    end
    def to_s
      "#{name} - #{exists?}"
    end
  end
end
