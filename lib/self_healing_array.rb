class SelfHealingArray < Array
  def >>(other)
    delete(other)
  end
end
