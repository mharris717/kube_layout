class Object
  def dsl_accessor(*names)
    names.each do |n|
      define_method(n) do |*args|
        if args.empty?
          instance_variable_get("@#{n}")
        elsif args.size == 1
          v = args.first
          v = v.kind_of?(Symbol) ? v.to_s : v
          instance_variable_set("@#{n}",v)
        else
          raise "bad"
        end
      end
    end
  end

  def grouping_dsl_accessor(name, cls)
    fattr("#{name}s") { {} }
    define_method(name) do |name_arg, &b|
      name_arg = name_arg.to_s
      if b
        obj = cls.new
        obj.name = name_arg
        obj.parent = self
        b[obj]
        send("#{name}s")[name_arg] = obj
      else
        send("#{name}s").fetch(name_arg)
      end
    end
  end
end
