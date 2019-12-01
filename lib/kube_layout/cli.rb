
module KubeLayout
  module CLI
    class Secret < Thor
      class_option :app, required: true
      class_option :name, required: true
      class_option :env, required: true
      class_option :def, default: ".kube_layout"

      desc "file","Make a secret from a file"
      option :sourcefile, required: true
      def file
        load_def!
        secret.add_as_file options[:env], options[:sourcefile]
      end

      desc "env --env a:b","Make a secret as env vars"
      option :vars, type: :hash, required: true
      def env
        load_def!
        secret.add_as_env options[:env], options[:vars]
      end

      no_commands do
        def secret
          KubeLayout.app(options[:app]).secret(options[:name])
        end

        def load_def!
          f = options[:def]
          if FileTest.exists?(f)
            load f
          else
            raise "Definition file #{f} does not exist"
          end
        end
      end
    end
    class Base < Thor
      desc "secret TYPE", "Make a secret entry in Vault"
      subcommand "secret", Secret
    end
  end
end
