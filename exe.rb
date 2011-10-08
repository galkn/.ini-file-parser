class ::Hash
  def to_obj
    self.each do |k,v|
      if v.kind_of? Hash
        v.to_obj
      end

      # create and initialize an instance variable for this key/value pair
      self.instance_variable_set("@#{k}", v)

      # create the getter that returns the instance variable
      self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")})

      # create the setter that sets the instance variable
      self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})
    end
    return self
  end
end

def to_sym hash
  hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
end

def load_config file_path, overrides = []
  
  # convert overrides to string array
  string_overrides = []
  overrides.each do |o|
    string_overrides.push o.to_s
  end
  overrides = string_overrides
  
  file = File.new file_path, "r"
  config = {}
  group = ""
  attributes = {}
  
  while line = file.gets
    # record group
    line.scan /^(\s*)\[(\w+)\](\s*)$/i do |s1, word, s2|
      if !attributes.empty?
        attributes = to_sym attributes
        config[group] = attributes
      end
      group = word
      attributes = {}
    end
    
    # record assignment
    line.scan /^(\s*)(\w+)(\<(\w)+\>){0,1}(\s*)\=(\s*)(\"){0,1}([a-zA-Z0-9\/,\s]+)(\"){0,1}(\s*)((\;)(.*)){0,1}$/i do |s1, attribute, override, suffix, s2, s3, q1, value, q2, s4|
      
      # get value assigned, explode if array
      quoted_value = "#{q1}#{value}#{q2}".strip
      if quoted_value =~ /^((\w+),)+(\w+)/i
        quoted_value = quoted_value.split ','
      end
      
      if !override.nil?
        override = override.gsub("<", "").gsub(">", "")        
        if overrides.include? override
          attributes[attribute] = quoted_value
        end
      else
        attributes[attribute] = quoted_value
      end
    end
  end
  
  if !attributes.empty?
    attributes = to_sym attributes
    config[group] = attributes
  end
      
  file.close
    
  return config.to_obj
end

obj = load_config "file.ini", ["ubuntu", :production]

puts obj.inspect

