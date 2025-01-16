module CoreExt
  module IntegerInflections
    def to_w_h
      number = to_f
      number * 1 / 60
    end
  end
end

class Integer
  include CoreExt::IntegerInflections
end
