class SelfHealingArray < Array
  def >>(name)
    delete(name)
  end
end
