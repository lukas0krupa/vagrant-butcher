require 'fileutils'

module Vagrant
  module Butcher
    module Helpers
      module KeyFiles

        def cache_dir(env)
          @cache_dir ||= File.expand_path(File.join(root_path(env), butcher_config(env).cache_dir))
        end

        def guest_key_path(env)
          @guest_key_path ||= butcher_config(env).guest_key_path
        end

        def key_filename(env)
          @key_filename ||= "#{env[:machine].name}-client.pem"
        end

        def client_key_path(env)
          @client_key_path ||= butcher_config(env).client_key || "#{cache_dir(env)}/#{key_filename(env)}"
        end

        def create_cache_dir(env)
          unless File.exists?(cache_dir(env))
            ui(env).info "Creating #{cache_dir(env)}"
            FileUtils.mkdir_p(cache_dir(env))
          end
        end

        def grab_key_from_guest(env)
          create_cache_dir(env)

          machine(env).communicate.execute("cat #{guest_key_path(env)}", sudo: true) do |type,data|
            File.open("#{cache_dir(env)}/#{key_filename(env)}", "w") { |f| f << data } if type == :stdout
          end

          ui(env).info "Saved client key to #{cache_dir(env)}/#{key_filename(env)}"
        end

        def cleanup_cache_dir(env)
          unless @failed_deletions
            key_file = "#{cache_dir(env)}/#{key_filename(env)}"
            File.delete(key_file) if File.exists?(key_file)
            Dir.delete(cache_dir(env)) if (Dir.entries(cache_dir(env)) - %w{ . .. }).empty?
          else
            ui(env).warn "#{@failed_deletions} not butchered from the Chef Server. Client key was left at #{client_key_path(env)}"
          end
        end

        def copy_guest_key(env)
          begin
            grab_key_from_guest(env)
          rescue ::Vagrant::Errors::VagrantError => e
            ui(env).error "Failed to create #{cache_dir(env)}/#{key_filename(env)}: #{e.class} - #{e}"
          end
        end

      end
    end
  end
end
