# add methods to Enumerable, which makes them available to Array
module Enumerable

  # sum of an array of numbers
  def sum
    self.inject(0) { |acc, i| acc + i }
  end

  # average of an array of numbers
  def average
    self.sum / self.length.to_f
  end

  # variance of an array of numbers
  def variance
    avg = self.average
    self.inject(0) { |acc, i| acc + (i - avg)**2 }
  end

  # standard deviation of an array of numbers
  def standard_deviation
    return Math.sqrt(self.variance / (self.length - 1))
  end

end

