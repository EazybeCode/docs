# Playground Test Kredileri

Playground'da ajanınızı test ederken kredilerin nasıl çalıştığını öğrenin.

## Ne değişti

Playground'da test yaparken ajanınızın ürettiği her yapay zeka yanıtı artık hesabınızdan kredi düşer. Testler, gerçek kullanımla aynı şekilde faturalandırılır çünkü her test yanıtı, gerçek bir müşteri görüşmesinde kullanılacak olan aynı yapay zeka modelini çalıştırır. Maliyet, ajanınız için seçilen **AI Model** seviyesine bağlıdır — daha yüksek seviyeler daha yeteneklidir ve yanıt başına daha fazla ücretlendirilir.

## Maliyeti ve bakiyenizi nereden görebilirsiniz

**Playground** sekmesini açtığınızda, sohbet penceresinin üst kısmında bir faturalandırma çubuğu görünür. İki bilgi gösterir:

- **Yanıt başına maliyet** — ajanın her yanıt gönderdiğinde düşülen tutar (örneğin, Very High seviyesinde $0.04).
- **Kalan bakiye** — yerel para biriminizde mevcut cüzdan bakiyeniz (örneğin, ₹1.838,42 kalan).

Aşağıdaki ekran görüntüsü bunların nerede göründüğünü gösterir. Ajan adı ve durumunun hemen altındaki satıra bakın.

## Yanıt başına maliyet

| Model seviyesi | Yanıt başına maliyet |
| --- | --- |
| Low | $0.01 |
| Medium | $0.02 |
| High | $0.03 |
| Very High | $0.04 |
| Premium | $0.05 |
| Ultra | $0.06 |

**Ultra** seviyesi yalnızca en zor durumlar için tasarlanmıştır. Daha yavaş ve önemli ölçüde daha pahalıdır, bu nedenle yalnızca düşük seviyeler yeterli olmadığında kullanın.

Model seviyesini ajanınızın **Billing** sekmesindeki **AI Model** açılır menüsünden seçebilirsiniz. Yanıt başına fiyat her seviyenin yanında gösterilir.

## Test maliyetlerini düşük tutmak için ipuçları

- **Başlamadan önce doğru seviyeyi seçin.** Selamlamalar ve hazır yanıtlar gibi rutin kontroller için düşük seviye (Low veya Medium) kullanın. Daha yüksek seviyeye yalnızca yanıt kalitesini test etmeniz gerektiğinde geçin.
- **Test senaryolarınızı önceden planlayın.** Aynı görüşmeyi defalarca tekrarlamak yerine her sohbeti odaklı ve kısa tutun.
- **Monthly Breakdown'u kontrol edin** — bir test turundan sonra Billing sekmesindeki bu bölümü inceleyerek ne kadar harcandığını görün.

## Sıkça sorulan sorular

**Her test sohbeti için sabit bir ücret var mı?**
Hayır. Ücretler yapılan yapay zeka işine göre belirlenir. Görüşme başına değil, yapay zeka yanıtı başına ödeme yaparsınız.

**Workflow ajanları nasıl ücretlendirilir?**
Workflow ajanları yanıt başına değil, yapay zeka adımı (düğüm) başına ücretlendirilir. Standart bir sınıflandır-ve-yanıtla akışı, bir müşteri mesajı için iki yapay zeka adımı çalıştırır, bu nedenle mesaj başına iki kez faturalandırılır.

**Ajan tek bir yanıtta birden fazla WhatsApp mesajı gönderirse, bu bir kez mi yoksa birden fazla kez mi ücretlendirilir?**
Tek bir yapay zeka yanıt adımından üretilen birden fazla WhatsApp mesajı tek bir ücret olarak sayılır. Aynı turda birden fazla yapay zeka adımı ayrı ayrı ücretlendirilir.

**Başarısız veya boş yanıtlar için ücretlendirilir miyim?**
Token kullanılmadan gerçekleşen bir sağlayıcı hatası ücretlendirilmez. Token kullanıldıktan sonra oluşan boş bir çıktı ücretlendirilir ve model çalıştıktan sonra meydana gelen bir teslim hatası da ücretlendirilebilir.

**Ücretler hangi para birimindedir?**
Seviye fiyatları USD cinsindendir. Cüzdanınız INR ise, tutarlar yapılandırılmış kur üzerinden çevrilir (şu anda 1 USD = 93,0 INR). Yani $0.04'lık bir yanıt yaklaşık ₹3,72'dir.

**Canlı bir WhatsApp görüşmesi sırasında bakiyem biterse ne olur?**
Ajan çalışmayı durdurur. Gelen mesaj saklanır ancak otomatik yanıt gönderilmez. Devam etmek için bakiyenizi yükleyin.

**Canlı WhatsApp görüşmeleri aynı şekilde mi ücretlendirilir?**
Evet. Canlı görüşmeler, Playground ile aynı seviye fiyatlarını ve aynı adım başına sayımı kullanır.
