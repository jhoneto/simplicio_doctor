require("csv")

class Bank < ApplicationRecord
  has_paper_trail

  def self.load_data
    CSV.read("#{Rails.root}/banco.csv", headers: true).each do |row|
      Bank.create(code: row["Número_Código"], name: row["Nome_Reduzido"])
    end
  end
end
