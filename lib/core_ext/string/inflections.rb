module CoreExt
  module StringInflections
    def to_w_h
      number = to_f
      number * 1 / 60
    end

    def safe_titleize
      titleize.tr('/', ' ')
    end
  end
end

class String
  include CoreExt::StringInflections
end
