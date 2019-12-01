
class Hash
  def to_string_keys
    res = {}
    each do |k,v|
      vv = v.respond_to?(:to_string_keys) ? v.to_string_keys : v
      res[k.to_s] = vv
    end
    res
  end
end

def encode(str)
  ec("printf '#{str}' | base64", silent: true).strip
end

def me
  ec("whoami").strip
end
