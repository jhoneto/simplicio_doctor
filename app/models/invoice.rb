class Invoice < ApplicationRecord
  # belongs_to :medical_organization
  belongs_to :hospital
  belongs_to :hospital_local
  has_many :invoice_partners, class_name: "InvoicePartner", dependent: :delete_all
  accepts_nested_attributes_for :invoice_partners, reject_if: ->(attributes) { attributes["original_value"].blank? }, allow_destroy: true

  scope :by_medical_organization, ->(id) { where(medical_organization_id: id) }
  scope :by_hospital, ->(id) { where(hospital_id: id) }
  scope :by_start_date, ->(d) { where("invoice_date >= ?", d.to_date.beginning_of_day) }
  scope :by_end_date, ->(d) { where("invoice_date <= ?", d.to_date.end_of_day) }
  scope :by_status, ->(s) { where(status: s) }
  scope :by_medical_organization_partner, ->(mop) { joins(:invoice_partners).where("invoice_partners.medical_organization_partner_id = ?", mop) }

  validates_presence_of :competence, :cnae, :cnae_description, :description, :original_value, :iss_perc, :value
  validates :invoice_number, uniqueness: { scope: :medical_organization_id, message: "Essa nota já existe para essa empresa" }, allow_nil: true
  validate :check_partners_value

  before_create :rps_values, :calculate_taxes, :set_status

  # after_commit :send_nfse, on: :create

  ALL_AUTHORIZED = [ :authorized, :release, :paid ]
  ALL_PAID = [ :release, :paid ]

  def set_status
    if self.invoice_number.nil?
      self.status = :pending
    else
      self.status = :authorized
    end
  end

  def check_partners_value
    errors.add(:invoice_partners, "A nota deve ter pelo menos 1 médico(a)")  if self.invoice_partners.empty?
    total = self.invoice_partners.inject(0.0) { |sum, p| sum + p.original_value }
    errors.add(:invoice_partners, "A divisão dos valores entre os médicos difere do valor total da nota.")  if self.original_value != total
  end

  def status_text
    case self.status.to_sym
    when :pending
      "Pendente"
    when :reject
      "Rejeitada"
    when :authorized
      "Aguardando Transf. Hospital"
    when :release
      "Pendente Transf Médico"
    when :paid
      "Pago"
    when :waiting_cancel
      "Aguardando cancelamento"
    when :cancelled
      "Cancelada"
    else
      "----"
    end
  end

  def insert_cnae_description
    unless self.cnae.nil?
      cnae = MedicalOrganization.find(self.medical_organization_id).activities.where(cnae: self.cnae).first
      self.cnae_description = cnae.cnae_description
    end
  end

  def rps_values
    if self.invoice_number.nil?
      mo = MedicalOrganization.find(self.medical_organization_id)
      self.rps_number = mo.get_next_rps_number
      self.rps_serial = mo.rps_serie
    end
  end



  def calculate_taxes
    begin
      if self.medical_organization
        if self.medical_organization.tax_calculation_type.to_sym == :presumed_profit
          taxes = PresumedProfitRule.new(self.original_value, self.iss_prepaid, self.federal_taxes_prepaid, self.iss_perc).calculate_taxes

          self.value = taxes[:final_value]

          # Valor total a ser apurado
          self.ir_value_total = taxes[:ir_value]
          self.csll_value_total = taxes[:csll_value]
          self.cofins_value_total = taxes[:cofins_value]
          self.pis_value_total = taxes[:pis_value]
          self.iss_value_total = taxes[:iss_value]

          # Valor destacado na nota
          self.ir_value = taxes[:ir_posted_value]
          self.csll_value = taxes[:csll_posted_value]
          self.cofins_value = taxes[:cofins_posted_value]
          self.pis_value = taxes[:pis_posted_value]
          self.iss_value = taxes[:iss_value]

        end
      end
    rescue
    end
  end

  def export_xml
    return self.invoice_xml unless self.invoice_xml.nil?

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.EnviarLoteRpsEnvio("xmlns:ns2" => "http://www.ginfes.com.br/tipos", "xmlns" => "http://www.ginfes.com.br/servico_enviar_lote_rps_envio", "xmlns:ns3" => "http://www.w3.org/2000/09/xmldsig#") {
        xml.NumeroLote self.rps_number
        xml.Cnpj self.medical_organization.cnpj
        xml.InscricaoMunicipal self.medical_organization.municipal_register.split("-")[0]
        xml.QuantidadeRps 1
        xml.ListaRps {
          xml.Rps {
            xml["ns2"].IdentificacaoRps {
              xml["ns2"].Numero self.rps_number
              xml["ns2"].Serie self.rps_serial
              xml["ns2"].Tipo "1"
            }
            xml["ns2"].DataEmissao self.created_at.strftime("%Y-%m-%dT%H:%M:%S")
            xml["ns2"].NaturezaOperacao "1"
            xml["ns2"].RegimeEspecialTributacao
            xml["ns2"].OptanteSimplesNacional self.medical_organization.simple_opt
            xml["ns2"].IncentivadorCultural "2"
            xml["ns2"].Status "1"
            xml["ns2"].Servico {
              xml["ns2"].Valores {
                xml["ns2"].ValorServicos self.original_value
                xml["ns2"].IssRetido self.iss_prepaid ? "1" : "2"
                xml["ns2"].Aliquota self.iss_perc/100.0
                xml["ns2"].ValorIss self.iss_value unless self.iss_prepaid
                xml["ns2"].ValorIssRetido self.iss_value unless self.iss_prepaid
                xml["ns2"].BaseCalculo self.original_value
                xml["ns2"].ValorPis self.pis_value
                xml["ns2"].ValorCofins self.cofins_value
                xml["ns2"].ValorIr self.ir_value
                xml["ns2"].ValorCsll self.csll_value
                xml["ns2"].ValorLiquidoNfse self.value
              }
              xml["ns2"].ItemListaServico self.cnae.split("/")[0]
              xml["ns2"].CodigoTributacaoMunicipio self.cnae.split("/")[1]
              xml["ns2"].Discriminacao self.description
              xml["ns2"].MunicipioPrestacaoServico self.medical_organization.ibge_code
            }
            xml["ns2"].Prestador {
              xml["ns2"].Cnpj self.medical_organization.cnpj
              xml["ns2"].InscricaoMunicipal self.medical_organization.municipal_register.split("-")[0]
            }
            xml["ns2"].Tomador {
              xml["ns2"].IdentificacaoTomador {
                xml["ns2"].CpfCnpj {
                  xml["ns2"].Cnpj self.hospital.cnpj
                  # xml['ns2'].Cpf invoice.contract.document_number if invoice.contract.document_number.size == 11
                }
              }
              xml["ns2"].RazaoSocial self.hospital.name
              xml["ns2"].Endereco {
                xml["ns2"].Endereco self.hospital.address
                xml["ns2"].Numero self.hospital.address_number
                xml["ns2"].Complemento self.hospital.address_compl
                xml["ns2"].Bairro self.hospital.address_district
                xml["ns2"].Cidade self.hospital.ibge_code
                xml["ns2"].Estado self.hospital.address_state
                xml["ns2"].Cep self.hospital.address_zipcode
              }
              xml["ns2"].Contato {
                xml["ns2"].Telefone self.hospital.invoice_phone
                xml["ns2"].Email self.hospital.invoice_email
              }
            }
          }
        }
      }
    end
    self.invoice_xml = builder.to_xml
    self.save
    self.invoice_xml
  end

  def self.process_return(tmpfile)
    xml = Nokogiri::XML(open(tmpfile))
    xml.xpath("//ns2:Nfse").each do |node|
      rps_number = node.at("Nfse").at("IdentificacaoRps").at("Numero").text
      rps_serial = node.at("Nfse").at("IdentificacaoRps").at("Serie").text
      cnpj = node.at("Nfse").at("PrestadorServico").at("IdentificacaoPrestador").at("Cnpj").text
      invoice = Invoice.joins(:medical_organization)
                       .where("rps_number = ? and rps_serial = ?", rps_number, rps_serial)
                       .where("medical_organizations.cnpj = ?", cnpj)
                       .order("created_at desc").select("invoices.id")
      invoice = Invoice.find(invoice.first.id)
      invoice.invoice_number = node.at("Nfse").at("IdentificacaoNfse").at("Numero").text
      invoice.verification_code = node.at("Nfse").at("IdentificacaoNfse").at("CodigoVerificacao").text
      invoice.invoice_date = node.at("Nfse").at("DataEmissao")
      invoice.status = :authorized
      invoice.save
    end
  end

  def self.billing_report(params)
    invoices = Invoice.by_medical_organization(params[:by_medical_organization]).joins(:invoice_partners)
    invoices = invoices.by_start_date(params[:by_start_date]) if params[:by_start_date].present?
    invoices = invoices.by_end_date(params[:by_end_date]) if params[:by_end_date].present?

    invoices = invoices.joins("inner join medical_organization_partners on medical_organization_partners.id = invoice_partners.medical_organization_partner_id")
                       .select("medical_organization_partners.id, name,  sum(invoice_partners.original_value) total, EXTRACT(MONTH FROM invoice_date) imonth, EXTRACT(YEAR FROM invoice_date) iyear")
                       .group("medical_organization_partners.id, name, EXTRACT(MONTH FROM invoice_date), EXTRACT(YEAR FROM invoice_date)")
                       .order("name, iyear, imonth")
    report = Hash.new
    invoices.each do |inv|
      report[inv.id.to_s.to_sym] = {} if report[inv.id.to_s.to_sym].nil?
      report[inv.id.to_s.to_sym][:name] = inv.name
      report[inv.id.to_s.to_sym]["#{inv.imonth.to_i}_#{inv.iyear.to_i}".to_sym] = inv.total
    end
    report
  end

  def send_nfse
    return if self.status.to_sym == :authorized

    NfseHub.new("28b84b89-4da3-4460-b0e1-31d007d29179", NfseHub.url).send_nfse(id) if medical_organization.enabled_nfsehub && Rails.env == "development"
    NfseHub.new(ENV["NFSEHUB_TOKEN"], NfseHub.url).send_nfse(id) if medical_organization.enabled_nfsehub && Rails.env == "production"
  end

  def cancel_nfse
    NfseHub.new("28b84b89-4da3-4460-b0e1-31d007d29179", NfseHub.url).cancel_nfse(id) if medical_organization.enabled_nfsehub && Rails.env == "development"
    NfseHub.new(ENV["NFSEHUB_TOKEN"], NfseHub.url).cancel_nfse(id) if medical_organization.enabled_nfsehub && Rails.env == "production"
  end

  def self.report_tax_calculate(date1, date2, invoice_status)
    query = Invoice.joins(:medical_organization)
                   .select("
                     medical_organization_id,
                     medical_organizations.social_name,
                     sum(original_value) as total_original_value,
                     sum(value) as total_value,
                     sum(case iss_prepaid when true then iss_value else 0 end) as total_posted_iss,
                     sum(iss_value_total) as total_iss,
                     sum(case federal_taxes_prepaid when true then pis_value else 0 end) as total_posted_pis,
                     sum(case federal_taxes_prepaid when true then cofins_value else 0 end) as total_posted_cofins,
                     sum(case federal_taxes_prepaid when true then csll_value else 0 end) as total_posted_csll,
                     sum(case federal_taxes_prepaid when true then ir_value else 0 end) as total_posted_ir,
                     sum(pis_value_total) as total_pis,
                     sum(cofins_value_total) as total_cofins,
                     sum(csll_value_total) as total_csll,
                     sum(ir_value_total) as total_ir")
                   .by_start_date(date1)
                   .by_end_date(date2)
                   .group("medical_organization_id, medical_organizations.social_name")
                   .order("social_name asc")
    query = if invoice_status.to_sym == :only_paid
              query.by_status(ALL_PAID)
    else
              query.by_status(ALL_AUTHORIZED)
    end
    query
  end
end
