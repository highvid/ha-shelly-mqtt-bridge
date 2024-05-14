class SelfHealingHash < Hash
  def []=(key, value)
    if value.nil?
      delete(key)
    else
      super
    end
  end

  def safe_merge!(hash)
    hash.each do |key, value|
      existing_value = self[key]
      if existing_value.present?
        value.is_a?(Array) ? self[key].append(*value) : self[key].append(value)
      else
        self[key] = value.is_a?(Array) ? value : [value]
      end
    end
  end
end
