# Fictional product line ("Northforge Tools") and support taxonomy used by the
# synthetic demo. No real manufacturer product names are used.
module Catalog
  PRODUCTS = {
    "vc20_drill" => "VC-20 VoltCore 20V Akülü Matkap",
    "pc5_battery" => "PC-5 PowerCell 5Ah Batarya",
    "qc2_charger" => "QC-2 Hızlı Şarj Cihazı",
    "ig115_grinder" => "IG-115 Avuç Taşlama",
    "cs18_saw" => "CS-18 Akülü Daire Testere",
    "lm40_mower" => "LM-40 Akülü Çim Biçme",
    "tb22_toolbox" => "TB-22 Modüler Takım Çantası"
  }.freeze

  CATEGORIES = {
    "battery_charging" => "Batarya ve şarj",
    "product_defect" => "Ürün arızası",
    "warranty" => "Garanti ve iade",
    "order_shipping" => "Sipariş ve kargo",
    "spare_parts" => "Yedek parça",
    "usage_howto" => "Kullanım / nasıl yapılır",
    "safety" => "Güvenlik"
  }.freeze

  TEAMS = {
    "battery" => "Batarya ve Şarj Ekibi",
    "warranty" => "Garanti ve İade Ekibi",
    "technical" => "Teknik Destek Ekibi",
    "operations" => "Destek Operasyonları"
  }.freeze

  # Default routing used by triage fallback and shown to the model as context.
  CATEGORY_TEAM = {
    "battery_charging" => "battery",
    "product_defect" => "technical",
    "warranty" => "warranty",
    "order_shipping" => "warranty",
    "spare_parts" => "technical",
    "usage_howto" => "technical",
    "safety" => "technical"
  }.freeze

  module_function

  def as_json
    {
      products: PRODUCTS.map { |code, name| { code: code, name: name } },
      categories: CATEGORIES.map { |code, name| { code: code, name: name } },
      teams: TEAMS.map { |code, name| { code: code, name: name } }
    }
  end
end
