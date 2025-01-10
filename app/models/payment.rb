class Payment < ApplicationRecord
  belongs_to :medical_organization_partner
  has_many :discounts, dependent: :destroy
  has_many :invoice_partners

  accepts_nested_attributes_for :discounts, allow_destroy: true

  before_create :update_total_value
  after_create :register_payment
  before_destroy :unregister_payment

  validates_presence_of :payment_date

  scope :by_start_date, ->(d) { where("payment_date >= ?", d.to_date) }
  scope :by_end_date, ->(d) { where("payment_date <= ?", d.to_date) }
  scope :by_partner_id, ->(id) { where("medical_organization_partner_id = ?", id) }
  scope :by_medical_organization_id, ->(id) { joins(:medical_organization_partner).where("medical_organization_partners.medical_organization_id = ?", id) }

  def self.total_by_month(medical_organization_partner_id)
    where(medical_organization_partner_id: medical_organization_partner_id)
      .group_by_month_of_year(:payment_date, format: "%m/%Y")
      .sum(:total_value)
  end
  def self.current_competence
    Date.today.strftime("%m/%Y")
  end

  def self.charges_fees(competence, partner_id)
    Payment.joins(:discounts).
      where(medical_organization_partner_id: partner_id).
      where("discounts.discount_type = ?", :fees).
      where("discounts.competence = ?", competence).count == 0
  end

  def self.charges_certificate(compentece, partner_id)
    Payment.joins(:discounts).
      where(medical_organization_partner_id: partner_id).
      where("discounts.discount_type = ?", :certificate).
      where("discounts.created_at between ? and ?", 1.year.ago.strftime("%Y-%m-%d"), Time.current.strftime("%Y-%m-%d")).count == 0
  end

  def self.charges_bank_taxes(competence, partner_id)
    partner = MedicalOrganizationPartner.find(partner_id)
    return false if partner.transfer_tax_free
    Payment.joins(:discounts).
      where(medical_organization_partner_id: partner_id).
      where("discounts.discount_type = ?", :bank_taxes).
      where("discounts.competence = ?", competence).count >= partner.free_bank_transfer
  end

  def update_total_value
    invoice_values = InvoicePartner.to_pay_to_partner(self.medical_organization_partner_id).inject(0.0) { |sum, p| sum + p.original_value }

    self.total_value = invoice_values - self.discounts.inject(0.0) { |sum, d| sum + d.value }
  end

  def register_payment
    InvoicePartner.to_pay_to_partner(self.medical_organization_partner_id).each do |ip|
      ip.payment_id = self.id
      ip.register_payment
    end
  end

  def unregister_payment
    InvoicePartner.where(payment_id: self.id).each do |ip|
      ip.payment_id = nil
      ip.status = :open
      ip.save
      invoice = Invoice.find(ip.invoice_id)
      invoice.status = :release
      invoice.save
    end
  end

  def self.dirf_report(medical_organization_id: nil, partner_name: nil,
                       partner_cpf: nil, start_date: "1900-01-01", end_date: "1900-01-01")
    query = select('mop.name,
                    mop.cpf,
                    mop.email,
                    payment_date,
                    (select sum(original_value) from invoice_partners where payment_id = payments.id) original_value,
                    (select sum(value) from discounts where payment_id = payments.id ) as discount,
                    total_value')
    query = query.joins('inner join medical_organization_partners as mop
                         on payments.medical_organization_partner_id = mop.id')
    query = query.where("payment_date between ?  and ?", start_date, end_date)
    query = query.where("mop.medical_organization_id = ?", medical_organization_id) unless medical_organization_id.blank?
    query = query.where("name ilike UPPER(?)", "%#{partner_name.upcase}%") unless partner_name.blank?
    query = query.where("cpf = ?", partner_cpf) unless partner_cpf.blank?
    query.order("name")
  end

  def self.resume(medical_organization_id: nil, medical_organization_partner_id: nil,
                  start_date: "1900-01-01", end_date: "1900-01-01")
    @payments = Payment.by_start_date(start_date)
                       .by_end_date(end_date)
    @payments = @payments.by_partner_id(medical_organization_partner_id) unless medical_organization_partner_id.blank?
    @payments = @payments.by_medical_organization_id(medical_organization_id) unless medical_organization_id.blank?

    @resume = []
    doctor_ids = @payments.map { |p| p.medical_organization_partner_id }.uniq
    payment_ids = @payments.map { |p| p.id }.uniq

    competences = InvoicePartner.joins(:invoice).where("payment_id in (?)", payment_ids).select("distinct invoices.competence").order(:competence).map { |p| p.competence }.uniq

    MedicalOrganizationPartner.where("id in (?)", doctor_ids).each do |doctor|
      unless doctor.nil?
        competences.each do |c|
          @resume << {
            id: doctor&.id,
            cpf: doctor&.cpf,
            name: doctor&.name,
            competence: c,
            original_value: 0,
            fees: 0,
            taxes: 0,
            bank_taxes: 0,
            certificate: 0,
            extra_taxes: 0,
            others: 0,
            income_tax_return: 0,
            final_value: 0
          }
        end
      end
    end

    @resume.each do |r|
      payments = Payment.select("sum(invoice_partners.original_value) as original_value, sum(payments.total_value) final_value")
                        .joins("inner join invoice_partners on invoice_partners.payment_id = payments.id")
                        .joins("inner join invoices on invoice_partners.invoice_id = invoices.id")
                        .where(medical_organization_partner_id: r[:id])
                        .where("invoices.competence = ?", r[:competence])
                        .order(:original_value)
      discounts = Discount.joins(:payment)
                          .where("medical_organization_partner_id = ?", r[:id])
                          .where("competence = ?", r[:competence])
      r[:original_value] = payments.first.original_value unless payments.first.nil?
      r[:fees] = discounts.inject(0.0) { |sum, d| d.discount_type.to_sym == :fees ? sum + d.value : sum }
      r[:taxes] = discounts.inject(0.0) { |sum, d| d.discount_type.to_sym == :taxes ? sum + d.value : sum }
      r[:bank_taxes] = discounts.inject(0.0) { |sum, d| d.discount_type.to_sym == :bank_taxes ? sum + d.value : sum }
      r[:certificate] = discounts.inject(0.0) { |sum, d| d.discount_type.to_sym == :certificate ? sum + d.value : sum }
      r[:extra_taxes] = discounts.inject(0.0) { |sum, d| d.discount_type.to_sym == :extra_taxes ? sum + d.value : sum }
      r[:others] = discounts.inject(0.0) { |sum, d| d.discount_type.to_sym == :others ? sum + d.value : sum }
      r[:income_tax_return] = discounts.inject(0.0) { |sum, d| d.discount_type.to_sym == :income_tax_return ? sum + d.value : sum }
      r[:final_value] = payments.first.final_value unless payments.first.nil?
    end

    # @resume.each do |r|
    #   @payments.each do |payment|
    #     if !payment.medical_organization_partner.nil? && r[:cpf] == payment.medical_organization_partner.cpf
    #       r[:original_value] += payment.invoice_partners.inject(0.0){ |sum, ip| sum + ip.original_value }
    #       r[:fees] += payment.discounts.inject(0.0){ |sum, d| d.discount_type.to_sym == :fees ? sum + d.value : sum }
    #       r[:taxes] += payment.discounts.inject(0.0){ |sum, d| d.discount_type.to_sym == :taxes ? sum + d.value : sum }
    #       r[:bank_taxes] += payment.discounts.inject(0.0){ |sum, d| d.discount_type.to_sym == :bank_taxes ? sum + d.value : sum }
    #       r[:certificate] += payment.discounts.inject(0.0){ |sum, d| d.discount_type.to_sym == :certificate ? sum + d.value : sum }
    #       r[:extra_taxes] += payment.discounts.inject(0.0){ |sum, d| d.discount_type.to_sym == :extra_taxes ? sum + d.value : sum }
    #       r[:final_value] += payment.total_value
    #     end
    #   end
    # end
  end
end
