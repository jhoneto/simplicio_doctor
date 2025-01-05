class Discount < ApplicationRecord
  belongs_to :payment

  LIST = [
           [ "Honorários", :fees ],
           [ "Impostos", :taxes ],
           [ "Tx. bancárias", :bank_taxes ],
           [ "Cert. digital PJ", :certificate ],
           [ "Adicional de IR", :extra_taxes ],
           [ "Declaração IR", :income_tax_return ],
           [ "Outros", :others ]
        ]

  def discount_type_str
    return "Honorários" if self.discount_type.to_sym == :fees
    return "Impostos" if self.discount_type.to_sym == :taxes
    return "Tarifas bancárias" if self.discount_type.to_sym == :bank_taxes
    return "Cert. digital PJ" if self.discount_type.to_sym == :certificate
    return "Adicional de IR" if self.discount_type.to_sym == :extra_taxes
    return "Declaração IR" if self.discount_type.to_sym == :income_tax_return
    "Outros" if self.discount_type.to_sym == :others
  end
end
