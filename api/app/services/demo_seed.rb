# Fully synthetic demo dataset for a fictional tool brand ("Northforge Tools").
# Names, emails (example.com/example.net), products and texts are invented.
# run! is idempotent (keyed by email / slug / external_ref); reset! wipes and rebuilds.
# No AgentRun or Incident records are seeded: every AI result in the app comes from a real request.
module DemoSeed
  PASSWORD = "resolveiq2026".freeze

  USERS = [
    { name: "Selin Aydın", email: "selin@resolveiq.demo", role: "manager", team: "operations", title: "Destek Operasyon Müdürü" },
    { name: "Burak Demir", email: "burak@resolveiq.demo", role: "agent", team: "battery", title: "Batarya ve Şarj Uzmanı" },
    { name: "Ayşe Kara", email: "ayse@resolveiq.demo", role: "agent", team: "warranty", title: "Garanti Uzmanı" },
    { name: "Emre Yılmaz", email: "emre@resolveiq.demo", role: "agent", team: "technical", title: "Teknik Destek Uzmanı" }
  ].freeze

  CUSTOMERS = [
    [ "Mert Şahin", "mert.sahin@example.com", "Şahin Mobilya Atölyesi", "pro", "Bursa" ],
    [ "Elif Koç", "elif.koc@example.net", nil, "standard", "İzmir" ],
    [ "Kerem Aksoy", "kerem.aksoy@example.com", "Aksoy Yapı Ltd.", "enterprise", "Ankara" ],
    [ "Zeynep Arslan", "zeynep.arslan@example.net", nil, "standard", "İstanbul" ],
    [ "Hakan Öztürk", "hakan.ozturk@example.com", "Öztürk İnşaat", "enterprise", "Kocaeli" ],
    [ "Deniz Polat", "deniz.polat@example.net", nil, "standard", "Antalya" ],
    [ "Cem Yıldırım", "cem.yildirim@example.com", "Yıldırım Elektrik", "pro", "Eskişehir" ],
    [ "Gizem Çelik", "gizem.celik@example.net", nil, "standard", "Trabzon" ],
    [ "Onur Kaplan", "onur.kaplan@example.com", "Kaplan Çatı Sistemleri", "pro", "Konya" ],
    [ "Seda Güneş", "seda.gunes@example.net", nil, "standard", "Samsun" ],
    [ "Tolga Erdem", "tolga.erdem@example.com", "Erdem Peyzaj", "pro", "Muğla" ],
    [ "Buse Aydemir", "buse.aydemir@example.net", nil, "standard", "Adana" ],
    [ "Serkan Uçar", "serkan.ucar@example.com", "Uçar Restorasyon", "enterprise", "Erzurum" ],
    [ "İpek Taş", "ipek.tas@example.net", nil, "standard", "Edirne" ],
    [ "Volkan Bulut", "volkan.bulut@example.com", "Bulut Tadilat", "pro", "Kayseri" ]
  ].freeze

  ARTICLES = [
    {
      slug: "pc-5-batarya-sarj-olmuyor-temel-kontroller", product: "pc5_battery", category: "battery_charging",
      title: "PC-5 batarya şarj olmuyor: temel kontroller", tags: %w[batarya şarj pc-5 kontrol],
      body: <<~MD
        PC-5 PowerCell bataryanız şarj cihazına takıldığında şarj olmuyorsa aşağıdaki adımları sırayla uygulayın.

        1. Bataryayı şarj cihazından çıkarın ve temas yüzeylerini kuru bir bezle temizleyin.
        2. Şarj cihazını farklı bir prize takarak prizden kaynaklı bir sorun olmadığını doğrulayın.
        3. Bataryayı yeniden, sonuna kadar oturtarak takın; "klik" sesini duyun.
        4. Şarj cihazındaki LED'in rengini ve yanıp sönme biçimini not edin (bkz. QC-2 LED göstergeleri makalesi).
        5. Sorun devam ederse bataryanın seri numarasını ve LED davranışını destek ekibine iletin.

        Not: Batarya kasasında çatlak, şişme veya sıvı sızıntısı varsa bataryayı kullanmayın ve şarj etmeyin.
      MD
    },
    {
      slug: "qc-2-sarj-cihazi-led-gostergeleri", product: "qc2_charger", category: "battery_charging",
      title: "QC-2 şarj cihazı LED göstergeleri ne anlama gelir?", tags: %w[şarj led qc-2 gösterge],
      body: <<~MD
        QC-2 Hızlı Şarj Cihazı durumunu tek bir LED ile gösterir.

        - Sabit yeşil: Şarj tamamlandı.
        - Yanıp sönen yeşil: Şarj devam ediyor.
        - Sabit kırmızı: Batarya algılandı, şarj öncesi kontrol yapılıyor (birkaç saniye sürer).
        - Hızlı yanıp sönen kırmızı: Batarya hatası veya batarya sıcaklığı şarj aralığının dışında.
        - LED yanmıyor: Cihaz enerji almıyor; prizi ve kabloyu kontrol edin.

        Şarj için uygun batarya sıcaklığı 5°C ile 40°C arasıdır.
      MD
    },
    {
      slug: "batarya-omrunu-uzatma-ipuclari", product: nil, category: "battery_charging",
      title: "Batarya ömrünü uzatmak için ipuçları", tags: %w[batarya bakım ömür],
      body: <<~MD
        Lityum-iyon bataryaların ömrünü uzatmak için:

        1. Bataryayı tamamen boşalmadan şarj edin; uzun süre boş bırakmayın.
        2. Uzun süre kullanmayacaksanız yaklaşık %50 doluluk seviyesinde saklayın.
        3. Bataryayı doğrudan güneş ışığından ve ısı kaynaklarından uzak tutun.
        4. Yalnızca orijinal Northforge şarj cihazlarını kullanın.
      MD
    },
    {
      slug: "vc-20-matkap-mandren-kaymasi", product: "vc20_drill", category: "product_defect",
      title: "VC-20 matkapta mandren kayması: ayar ve kontrol", tags: %w[matkap mandren uç kayma],
      body: <<~MD
        Uç delme sırasında kayıyorsa:

        1. Aleti kapatın ve bataryayı çıkarın.
        2. Mandreni tamamen açıp ucu en dibe kadar yerleştirin.
        3. Mandreni elle sıkın, ardından tork halkasını "matkap" konumuna alın.
        4. Ucun şaftında aşınma veya yağ olup olmadığını kontrol edin; gerekirse temizleyin.
        5. Sorun sürerse mandren değişimi için servis kaydı açın.
      MD
    },
    {
      slug: "garanti-kapsami-ve-basvuru", product: nil, category: "warranty",
      title: "Garanti kapsamı ve başvuru adımları", tags: %w[garanti başvuru fatura],
      body: <<~MD
        Northforge ürünleri satın alma tarihinden itibaren 2 yıl garantilidir (bataryalar dahil).

        1. Faturanızın veya satın alma belgenizin fotoğrafını hazırlayın.
        2. Ürünün seri numarasını etiketten okuyun.
        3. Destek talebinize arızayı ve ne zaman başladığını yazın.
        4. Ekibimiz ön değerlendirme sonrası kargo kodu veya yetkili servis yönlendirmesi gönderir.

        Kullanıcı hatası, düşürme veya yetkisiz müdahale kaynaklı hasarlar garanti kapsamı dışındadır.
      MD
    },
    {
      slug: "iade-ve-degisim-sureci", product: nil, category: "warranty",
      title: "İade ve değişim süreci", tags: %w[iade değişim kargo],
      body: <<~MD
        1. Teslimattan itibaren 14 gün içinde iade talebi oluşturabilirsiniz.
        2. Ürünü orijinal kutusu ve aksesuarlarıyla paketleyin.
        3. Size iletilen iade kargo kodunu kullanarak gönderin.
        4. Ürün depomuza ulaştıktan sonra 3 iş günü içinde inceleme sonucunu bildiririz.
      MD
    },
    {
      slug: "ig-115-disk-degisimi-ve-guvenli-kullanim", product: "ig115_grinder", category: "spare_parts",
      title: "IG-115 taşlama disk değişimi ve güvenli kullanım", tags: %w[taşlama disk yedek parça güvenlik],
      body: <<~MD
        1. Aleti kapatın ve fişini/bataryasını çıkarın.
        2. Mil kilidine basılı tutarak flanş somununu anahtarla gevşetin.
        3. Yeni diski yalnızca 115 mm ve en az 13.300 dev/dk değerli olacak şekilde seçin.
        4. Koruyucu kapağı takmadan aleti asla çalıştırmayın.
        5. Koruyucu gözlük ve eldiven kullanın.
      MD
    },
    {
      slug: "kargo-takibi-ve-teslimat-gecikmeleri", product: nil, category: "order_shipping",
      title: "Kargo takibi ve teslimat gecikmeleri", tags: %w[kargo sipariş teslimat],
      body: <<~MD
        1. Sipariş onay e-postasındaki takip numarasıyla kargo firmasının sayfasından durumu kontrol edin.
        2. 3 iş gününden uzun süre hareket görünmüyorsa sipariş numaranızla bize yazın.
        3. Hasarlı teslimatta paketi teslim almadan önce tutanak tutturun.
      MD
    },
    {
      slug: "aletten-yanik-kokusu-veya-duman", product: nil, category: "safety",
      title: "Aletten yanık kokusu veya duman gelirse ne yapmalı?", tags: %w[güvenlik duman koku acil],
      body: <<~MD
        Güvenliğiniz önceliğimizdir.

        1. Aleti hemen kapatın ve bataryasını çıkarın veya fişini çekin.
        2. Aleti yanıcı olmayan bir zemine bırakın ve soğumasını bekleyin.
        3. Aleti veya bataryayı tekrar kullanmayın, açmaya çalışmayın.
        4. Ürünün fotoğrafını ve seri numarasını destek ekibine iletin; talebiniz acil olarak işlenir.
      MD
    },
    {
      slug: "lm-40-bicak-bakimi", product: "lm40_mower", category: "usage_howto",
      title: "LM-40 çim biçme makinesi bıçak bakımı", tags: %w[çim biçme bıçak bakım],
      body: <<~MD
        1. Bataryayı çıkarın ve kalın eldiven giyin.
        2. Makineyi yan yatırın; bıçak somununu saat yönünün tersine çevirerek sökün.
        3. Bıçağı bileyleyin veya aşınmışsa orijinal yedek bıçakla değiştirin.
        4. Bıçağı dengeli takın ve somunu belirtilen torkta sıkın.
      MD
    },
    {
      slug: "cs-18-kesim-derinligi-ayari", product: "cs18_saw", category: "usage_howto", status: "draft",
      title: "CS-18 daire testerede kesim derinliği ayarı", tags: %w[testere ayar derinlik],
      body: <<~MD
        1. Bataryayı çıkarın.
        2. Derinlik kolunu gevşetin ve tabanı istenen derinliğe getirin.
        3. Bıçağın malzemeden en fazla 5 mm taşmasına dikkat edin.
        4. Kolu sıkıca kilitleyin.
      MD
    }
  ].freeze

  # [ref, customer_index, channel, status, priority, category, product, assignee_email, hours_ago, subject, description]
  # The six "pc5-cold" tickets describe the same symptom in different words; the rest are controls.
  TICKETS = [
    [ "pc5-cold-1", 2, "email", "open", "high", "battery_charging", "pc5_battery", nil, 110,
      "PC-5 batarya şarj olmuyor, kırmızı ışık yanıp sönüyor",
      "Şantiyede kullandığımız 3 adet PC-5 bataryadan ikisi QC-2 şarj cihazına takınca şarj olmuyor. Şarj cihazındaki kırmızı ışık hızlı hızlı yanıp sönüyor. Bataryalar gece boyunca konteynerde kalmıştı, sabah hava eksi derecelerdeydi." ],
    [ "pc5-cold-2", 4, "web", "open", "normal", nil, "pc5_battery", nil, 86,
      "Şarj cihazında kırmızı LED, batarya dolmuyor",
      "Yeni aldığımız PC-5 batarya şarja takıldığında kırmızı LED sürekli yanıp sönüyor ve şarj başlamıyor. Araçta soğukta bekledikten sonra oluyor. Bir süre içeride bekletince bazen düzeliyor ama sahada vakit kaybediyoruz." ],
    [ "pc5-cold-3", 8, "chat", "in_progress", "high", "battery_charging", "pc5_battery", "burak@resolveiq.demo", 70,
      "Soğuk havada PC-5 bataryalar şarj almıyor",
      "Çatı işlerinde soğukta bıraktığımız PC-5 bataryalar şarj cihazına takıldığında kırmızı LED yanıp sönüyor, şarj olmuyor. Ekipte 4 batarya aynı sorunu yaşıyor. Aynı partiden mi acaba?" ],
    [ "pc5-cold-4", 6, "email", "open", "normal", nil, "pc5_battery", nil, 52,
      "Bataryam şarj olmuyor - LED kırmızı yanıp sönüyor",
      "Merhaba, PC-5 bataryamı akşam garajda bıraktım, sabah şarja taktığımda şarj cihazının ışığı kırmızı yanıp sönmeye başladı ve şarj başlamadı. Garaj oldukça soğuk. Batarya arızalı mı?" ],
    [ "pc5-cold-5", 12, "web", "pending", "high", "battery_charging", "pc5_battery", "burak@resolveiq.demo", 30,
      "PC-5 batarya soğuk sonrası şarj hatası veriyor",
      "Restorasyon şantiyemizde sabahları PC-5 bataryalar şarj olmuyor; QC-2 şarj cihazı kırmızı yanıp sönüyor. Bataryalar gece boyunca soğuk depoda duruyor. Öğleden sonra bazıları şarj oluyor. Çözüm önerisi bekliyoruz." ],
    [ "pc5-cold-6", 14, "chat", "open", "normal", nil, "pc5_battery", nil, 9,
      "Kırmızı ışık yanıp sönüyor, şarj başlamıyor",
      "PC-5 batarya şarja takınca kırmızı ışık yanıp sönüyor, şarj başlamıyor. Batarya gece kamyonette soğukta kalmıştı. Başka batarya ile şarj cihazı normal çalışıyor." ],

    [ "pc5-crack", 0, "email", "open", "normal", "warranty", "pc5_battery", "ayse@resolveiq.demo", 60,
      "PC-5 batarya kasasında çatlak",
      "Bataryayı merdivenden düşürdükten sonra kasasında çatlak oluştu. Şu an çalışıyor ama kullanmak güvenli mi, garantiye girer mi?" ],
    [ "pc5-runtime", 9, "web", "open", "low", "battery_charging", "pc5_battery", nil, 44,
      "PC-5 bataryanın çalışma süresi kısaldı",
      "Yaklaşık iki yıllık PC-5 bataryam eskisine göre yarı sürede bitiyor. Tam doluyken bile matkapla kısa süre çalışabiliyorum. Normal bir yıpranma mı?" ],
    [ "pc5-gauge", 11, "chat", "open", "low", "usage_howto", "pc5_battery", nil, 20,
      "Batarya seviye göstergesi butonu basmıyor",
      "PC-5 bataryanın üzerindeki seviye gösterge butonuna basınca ışıklar yanmıyor. Batarya alete takınca çalışıyor, sadece gösterge çalışmıyor." ],

    [ "vc20-chuck", 3, "email", "in_progress", "normal", "product_defect", "vc20_drill", "emre@resolveiq.demo", 96,
      "VC-20 matkapta uç kayıyor",
      "VC-20 matkapla betona delik açarken uç sürekli kayıyor, mandreni ne kadar sıksam da tutmuyor." ],
    [ "vc20-noise", 7, "web", "open", "normal", "product_defect", "vc20_drill", nil, 40,
      "Matkaptan metalik ses geliyor",
      "VC-20 matkap yüksek devirde çalışırken dişli kutusundan metalik bir tıkırtı sesi geliyor. Performans düşmedi ama ses artıyor." ],
    [ "ig115-smoke", 5, "chat", "open", "urgent", "safety", "ig115_grinder", "emre@resolveiq.demo", 6,
      "Taşlama makinesinden duman çıktı",
      "IG-115 ile kesim yaparken motor kısmından duman ve yanık kokusu geldi. Hemen kapattım. Tekrar kullanmaya korkuyorum." ],
    [ "ig115-disc", 13, "email", "resolved", "low", "spare_parts", "ig115_grinder", "emre@resolveiq.demo", 200,
      "IG-115 için uygun disk hangisi?",
      "IG-115 taşlama için hangi ölçüde ve devirde disk almalıyım? Yedek disk siparişi vermek istiyorum." ],
    [ "qc2-fan", 1, "web", "open", "normal", "product_defect", "qc2_charger", nil, 34,
      "QC-2 şarj cihazının fanı çok ses yapıyor",
      "QC-2 şarj cihazının fanı şarj sırasında yüksek sesle çalışıyor, eskiden bu kadar ses yoktu. Şarj normal tamamlanıyor." ],
    [ "cargo-late", 10, "email", "open", "normal", "order_shipping", "lm40_mower", "ayse@resolveiq.demo", 28,
      "LM-40 siparişim hâlâ gelmedi",
      "Bir hafta önce verdiğim LM-40 çim biçme makinesi siparişim kargoda görünüyor ama 4 gündür hareket yok." ],
    [ "lm40-blade", 10, "chat", "resolved", "low", "usage_howto", "lm40_mower", "emre@resolveiq.demo", 300,
      "LM-40 bıçağı nasıl değiştirilir?",
      "LM-40 çim biçme makinesinin bıçağı köreldi, nasıl değiştirebilirim?" ],
    [ "tb22-latch", 3, "web", "pending", "low", "warranty", "tb22_toolbox", "ayse@resolveiq.demo", 75,
      "TB-22 takım çantasının kilidi kırıldı",
      "TB-22 modüler takım çantasının yan kilidi iki ay içinde kırıldı. Değişim mümkün mü?" ],
    [ "cs18-blade", 6, "email", "open", "normal", "spare_parts", "cs18_saw", nil, 15,
      "CS-18 için yedek testere bıçağı",
      "CS-18 akülü daire testere için ahşap kesim bıçağı arıyorum, hangi ölçü uyumlu?" ],
    [ "warranty-drill", 8, "web", "resolved", "normal", "warranty", "vc20_drill", "ayse@resolveiq.demo", 260,
      "VC-20 garanti başvurusu",
      "VC-20 matkabım 8 aylık ve tetik arızası var. Garanti başvurusunu nasıl yapabilirim?" ],
    [ "pc5-contacts", 4, "email", "resolved", "normal", "battery_charging", "pc5_battery", "burak@resolveiq.demo", 420,
      "Batarya tam şarj olmuyor",
      "PC-5 batarya şarj cihazında yarıda kalıyor, tam dolmuyor." ],
    [ "return-saw", 11, "web", "resolved", "low", "warranty", "cs18_saw", "ayse@resolveiq.demo", 340,
      "CS-18 iade talebi",
      "CS-18 testereyi yanlışlıkla sipariş ettim, kutusu açılmadı. İade etmek istiyorum." ],
    [ "drill-howto", 13, "chat", "open", "low", "usage_howto", "vc20_drill", nil, 3,
      "VC-20 darbe modu nasıl açılır?",
      "Yeni aldığım VC-20 matkapta darbe modunu nasıl açacağımı bulamadım." ]
  ].freeze

  REPLIES = {
    "pc5-cold-3" => [ [ "burak@resolveiq.demo", false, "Merhaba Onur Bey, bataryaların seri numaralarını ve şarj cihazındaki LED davranışının kısa bir videosunu paylaşabilir misiniz?" ],
                      [ nil, false, "Seri numaralarını ekledim. Hepsi aynı ay alınmıştı." ],
                      [ "burak@resolveiq.demo", true, "Aynı hafta benzer başka bildirimler de var gibi, kontrol edeceğim." ] ],
    "pc5-cold-5" => [ [ "burak@resolveiq.demo", false, "Merhaba Serkan Bey, bataryaları şarj öncesi oda sıcaklığında bekletmeyi deneyebilir misiniz? Sonucu bize yazarsanız sevinirim." ] ],
    "vc20-chuck" => [ [ "emre@resolveiq.demo", false, "Merhaba Zeynep Hanım, mandren kayması için bilgi bankamızdaki adımları uyguladınız mı? Ucun şaftını da kontrol etmenizi rica ederiz." ] ],
    "ig115-disc" => [ [ "emre@resolveiq.demo", false, "Merhaba, IG-115 için 115 mm çapında ve en az 13.300 dev/dk değerli diskler uyumludur. Koruyucu kapağı mutlaka kullanın." ] ],
    "lm40-blade" => [ [ "emre@resolveiq.demo", false, "Merhaba, bataryayı çıkarıp eldiven giydikten sonra bıçak somununu saat yönünün tersine çevirerek sökebilirsiniz. Ayrıntılı adımları ekledim." ] ],
    "warranty-drill" => [ [ "ayse@resolveiq.demo", false, "Merhaba, fatura fotoğrafınızı ve seri numarasını ilettiğiniz için teşekkürler. Kargo kodunuz e-posta ile gönderildi." ] ],
    "pc5-contacts" => [ [ "burak@resolveiq.demo", false, "Merhaba Hakan Bey, batarya ve şarj cihazı temas yüzeylerini kuru bir bezle temizleyip bataryayı sonuna kadar oturtarak tekrar deneyin. Sorun bu şekilde çözülüyor." ] ],
    "return-saw" => [ [ "ayse@resolveiq.demo", false, "Merhaba, iade kargo kodunuz oluşturuldu. Ürün depomuza ulaştığında 3 iş günü içinde iade işlemi tamamlanacaktır." ] ],
    "tb22-latch" => [ [ "ayse@resolveiq.demo", false, "Merhaba Kerem Bey, kırık kilidin fotoğrafını ve fatura bilgisini paylaşabilir misiniz?" ] ]
  }.freeze

  module_function

  SLA_POLICIES = [
    { name: "Acil", first_reply_minutes: 30, resolution_minutes: 240, priority: "urgent", position: 0 },
    { name: "Yüksek", first_reply_minutes: 60, resolution_minutes: 480, priority: "high", position: 1 },
    { name: "Normal", first_reply_minutes: 240, resolution_minutes: 1440, priority: "normal", position: 2 },
    { name: "Düşük", first_reply_minutes: 480, resolution_minutes: 2880, priority: "low", position: 3 }
  ].freeze

  MACROS = [
    { name: "Batarya LED videosu iste", description: "Şarj LED davranışının videosunu ister ve ticket'ı beklemede bırakır.",
      actions: { status: "pending", add_tags: [ "bilgi-istendi" ],
                 reply: "Merhaba, şarj cihazındaki LED'in rengini ve yanıp sönme biçimini kısa bir videoyla paylaşabilir misiniz? Bataryanın seri numarasını da yazarsanız teşekkür ederiz." } },
    { name: "Garanti süreci başlat", description: "Garanti ekibine atar ve fatura ister.",
      actions: { category: "warranty", add_tags: [ "garanti" ],
                 reply: "Merhaba, garanti değerlendirmesi için fatura veya satın alma belgenizin fotoğrafını ve ürünün seri numarasını iletmenizi rica ederiz. 2 iş günü içinde dönüş yapacağız." } },
    { name: "Bilgi bankası ile kapat", description: "Müşteriye KB adımlarını hatırlatıp çözer.",
      actions: { status: "resolved", add_tags: [ "kb" ],
                 reply: "Merhaba, paylaştığımız kontrol adımları sorunu giderdiyse talebinizi çözüldü olarak işaretliyorum. Yeni bir belirti olursa yanıtlayarak yeniden açabilirsiniz." } }
  ].freeze

  AUTOMATION_RULES = [
    { name: "Garanti anahtar kelimesi", event: "ticket_created", position: 0,
      conditions: { keywords: [ "garanti", "iade", "değişim" ] },
      actions: { category: "warranty", team: "warranty", add_tags: [ "garanti" ] } },
    { name: "Acil güvenlik", event: "ticket_created", position: 1,
      conditions: { keywords: [ "acil", "duman", "yangın", "kıvılcım" ] },
      actions: { priority: "urgent", add_tags: [ "acil", "güvenlik" ] } },
    { name: "PC-5 batarya etiketi", event: "ticket_created", position: 2,
      conditions: { product: "pc5_battery" },
      actions: { add_tags: [ "pc-5", "batarya" ], team: "battery" } }
  ].freeze

  def run!(now: Time.current)
    ActiveRecord::Base.transaction do
      seed_sla_policies
      seed_macros
      seed_automation_rules
      users = seed_users
      customers = seed_customers(now)
      articles = seed_articles(users, now)
      seed_tickets(users, customers, articles, now)
    end
    counts
  end

  def reset!
    tables = [ CsatRating, TicketLink, AuditLog, IncidentTicket, TicketArticle, TicketMessage, Incident, AgentRun,
               Ticket, KnowledgeArticle, Customer, Session, User, Macro, AutomationRule, SlaPolicy ].map(&:table_name)
    ActiveRecord::Base.connection.execute("TRUNCATE #{tables.join(', ')} RESTART IDENTITY CASCADE")
    run!
  end

  def counts
    { users: User.count, customers: Customer.count, tickets: Ticket.count, articles: KnowledgeArticle.count,
      incidents: Incident.count, agent_runs: AgentRun.count }
  end

  def seed_users
    USERS.to_h do |attrs|
      user = User.find_or_initialize_by(email: attrs[:email])
      user.assign_attributes(attrs.except(:email))
      user.password = PASSWORD if user.new_record?
      user.save!
      [ attrs[:email], user ]
    end
  end

  def seed_customers(now)
    CUSTOMERS.map.with_index do |(name, email, company, tier, city), i|
      Customer.find_or_create_by!(email: email) do |c|
        c.assign_attributes(name: name, company: company, tier: tier, city: city, created_at: now - (400 - i * 20).days)
      end
    end
  end

  def seed_articles(users, now)
    ARTICLES.map.with_index do |attrs, i|
      KnowledgeArticle.find_or_create_by!(slug: attrs[:slug]) do |a|
        a.assign_attributes(attrs.except(:slug, :status).merge(status: attrs.fetch(:status, "published"),
                                                               author: users["selin@resolveiq.demo"],
                                                               created_at: now - (90 - i).days, updated_at: now - (30 - i).days))
      end
    end
  end

  def seed_sla_policies
    SLA_POLICIES.each do |attrs|
      policy = SlaPolicy.find_or_initialize_by(name: attrs[:name])
      policy.assign_attributes(attrs)
      policy.save!
    end
  end

  def seed_macros
    MACROS.each do |attrs|
      macro = Macro.find_or_initialize_by(name: attrs[:name])
      macro.assign_attributes(attrs)
      macro.save!
    end
  end

  def seed_automation_rules
    AUTOMATION_RULES.each do |attrs|
      rule = AutomationRule.find_or_initialize_by(name: attrs[:name])
      rule.assign_attributes(attrs)
      rule.save!
    end
  end

  def seed_tickets(users, customers, articles, now)
    TICKETS.each do |ref, cust_i, channel, status, priority, category, product, assignee_email, hours_ago, subject, description|
      next if Ticket.exists?(external_ref: ref)

      created = now - hours_ago.hours
      ticket = Ticket.create!(
        external_ref: ref, customer: customers[cust_i], channel: channel, status: status, priority: priority,
        category: category, product: product, assignee: users[assignee_email], subject: subject, description: description,
        created_at: created, updated_at: created, resolved_at: status == "resolved" ? created + 20.hours : nil
      )
      ticket.messages.create!(author_type: "customer", body: description, created_at: created, updated_at: created)

      Array(REPLIES[ref]).each_with_index do |(email, internal, body), i|
        at = created + (i + 1) * 2.hours
        if email
          ticket.messages.create!(author_type: "agent", user: users[email], internal: internal, body: body, created_at: at, updated_at: at)
          ticket.update_columns(first_response_at: at) if !internal && ticket.first_response_at.nil?
        else
          ticket.messages.create!(author_type: "customer", body: body, created_at: at, updated_at: at)
        end
      end
      ticket.update_columns(updated_at: ticket.messages.maximum(:created_at) || created)
      SlaAssigner.assign!(ticket)

      link = { "vc20-chuck" => "vc-20-matkap-mandren-kaymasi", "lm40-blade" => "lm-40-bicak-bakimi",
               "ig115-disc" => "ig-115-disk-degisimi-ve-guvenli-kullanim", "warranty-drill" => "garanti-kapsami-ve-basvuru",
               "pc5-contacts" => "pc-5-batarya-sarj-olmuyor-temel-kontroller", "return-saw" => "iade-ve-degisim-sureci" }[ref]
      article = articles.find { |a| a.slug == link }
      TicketArticle.create!(ticket: ticket, knowledge_article: article, linked_by: ticket.assignee) if article

      if ticket.resolved? && %w[ig115-disc lm40-blade warranty-drill pc5-contacts return-saw].include?(ref)
        score = { "warranty-drill" => 5, "return-saw" => 4, "pc5-contacts" => 5, "ig115-disc" => 4, "lm40-blade" => 5 }[ref]
        ticket.create_csat_rating!(customer: ticket.customer, score: score, comment: "Demo CSAT kaydı")
      end
    end
  end
end
