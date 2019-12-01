class MakeSecretFile
  include FromHash
  attr_accessor :name, :file, :namespace

  def hash_for_yaml
    {
      apiVersion: 'v1',
      kind: 'Secret',
      metadata: {
        name: name,
        namespace: namespace,
      },
      type: 'Opaque',
      data: data_for_yaml,
    }.to_string_keys
  end

  def data_for_yaml
    {
      file => encoded_file,
    }
  end

  def encoded_file
    raise "no file" unless FileTest.exist?(file)
    ec("cat #{file} | base64").strip
  end

  fattr(:output_path) do
    f = File.basename(file).split('.').first
    "tmp/#{rand(1000000000000)}_#{f}.yml"
  end

  def call
    str = YAML.dump(hash_for_yaml)
    File.create output_path, str
    output_path
  end
end

class MakeSecretFileFromEnv < MakeSecretFile
  attr_accessor :vals
  def data_for_yaml
    res = {}
    vals.each do |k,v|
      res[k] = encode(v)
    end
    res
  end
end
