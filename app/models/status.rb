module Status

  Pending = 1
  Confirmed = 2
  Reconfirm = 3

  def self.values
    [
      ['Pending',Pending],
      ['Confirmed', Confirmed],
      ['Reconfirm', Reconfirm]
    ]
  end
end