# secret = Kube.app('segment-lineage').secret('cloudsql-lineage-db-credentials')
# secret.add_as_env :production, url: 'postgres://svc-segment-lineage:K0touL"h?N&BV}\VfFvsEvkg@localhost:5432/segment_lineage'

# secret = Kube.app('segment-lineage').secret('pubsub-lineage-credentials')
# secret.add_as_file :production, "credentials.json"

KubeLayout.define do |s|
  s.cluster :internal do |c|
    c.loader_vault_path "secret/dmfs/secrets_for_loader/internal_cluster"
    c.kube_context "gke_liveramp-eng-dmfs_us-central1_dmfs-internal-sharedvpc"
  end

  s.cluster :external do |c|
    c.loader_vault_path "secret/dmfs/secrets_for_loader/external_cluster"
    c.kube_context "gke_liveramp-eng-dmfs_us-central1_dmfs-external-sharedvpc"
  end

  s.app 'segment-lookalike' do |a|
    a.cluster :external
    a.env :production do |e|
      e.namespace :default
    end
    a.env :staging do |e|
      e.namespace :staging
    end

    a.secret "cloudsql-instance-credentials" do |s|
      s.source_type :file
    end

    a.secret "cloudsql-db-credentials" do |s|
      s.source_type :env
    end


  end

  s.app 'segment-lineage' do |a|
    a.cluster :internal

    a.env :production do |e|
      e.namespace :default
    end
    a.env :staging do |e|
      e.namespace :staging
    end

    a.secret "fizzbuzz" do |s|
      s.source_type :env
    end

    a.secret "cloudsql-lineage-instance-credentials" do |s|
      s.source_type :file
    end

    a.secret "cloudsql-lineage-db-credentials" do |s|
      s.source_type :env
    end

    a.secret "pubsub-lineage-credentials" do |s|
      s.source_type :file
    end

    # a.secret "google-pubsub-creds" do |s|
    #   s.source_type :file
    # end
  end
end
