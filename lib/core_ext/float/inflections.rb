module CoreExt
  module FloatInflections
    def to_w_h
      number = self
      number * 1 / 60
    end
  end
end

class Float
  include CoreExt::FloatInflections
end
