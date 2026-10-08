# StudyFlow

StudyFlow, öğrencilerin derslerini, görevlerini ve çalışma sürelerini tek yerden takip edebildiği bir Flutter mobil uygulamasıdır. Kullanıcı ders ve görev ekler, Pomodoro ile çalışma oturumu başlatır, günlük ve haftalık çalışma istatistiklerini inceler. Veriler cihazda saklanır, internet gerekmez.

## Proje amacı

- Derslerini ve görevlerini düzenli tutmak,
- Pomodoro tekniğiyle çalışma süresini ölçmek ve kaydetmek,
- Ne kadar, hangi derse çalışıldığını gerçek verilerden görmek.

## Özellikler

Durum tablosu, proje ilerledikçe güncellenir.

| Modül | Neler yapabilir | Durum |
|---|---|---|
| **Dersler** | Listeleme, ekleme, düzenleme, silme, ders detayı, derse bağlı görev ilerlemesi ve çalışılan süre | Tamam |
| **Görevler** | Ekleme, düzenleme, silme, tamamlama, öncelik, son tarih, erteleme, arama ve filtreleme (durum, ders) | Tamam |
| **Pomodoro** | Başlat / duraklat / devam / sıfırla, çalışma ve mola aşamaları, süre ayarı, derse bağlı ya da serbest çalışma, oturum kaydı | Tamam |
| **İstatistikler** | Günlük hedef halkası, haftalık çalışma grafiği (Pazartesi–Pazar), derslere göre dağılım, bu hafta biten görevler | Tamam |
| **Ayarlar** | Profil kartı (isim, toplam çalışma, biten görev, ders sayısı), günlük hedef, Pomodoro ve mola süresi, bildirim anahtarı | Tamam |
| **Ana sayfa (Dashboard)** | Günlük hedef halkası, bugün biten görevler, son çalışmalar zaman çizgisi, "Merhaba, isim" | Tamam |
| **Bildirimler** | Çalışma süresi bitince yerel bildirim: Pomodoro başlarken önceden planlanır, uygulama arkadayken ve ekran kilitliyken de gelir. İzin ilk Pomodoro'da istenir, Ayarlar'daki anahtarla kapatılır | Tamam |

## Kullanılan teknolojiler

| Alan | Paket |
|---|---|
| Çerçeve | Flutter, Dart (SDK `^3.13.1`) |
| Route ve bağımlılık yönetimi | `flutter_modular` |
| Yerel veritabanı | `hive`, `hive_flutter` |
| HTTP katmanı | `dio` |
| Grafik | `fl_chart` |
| Bildirim | `flutter_local_notifications` |
| Yazı tipi, tarih | `google_fonts`, `intl` |
| Kimlik üretimi | `uuid` |
| Test | `flutter_test`, `mocktail`, `integration_test` |

## Proje mimarisi

Uygulama **MVVM** düzenindedir. Veri tek yönde akar:

```
View  →  ViewModel  →  Repository  →  Hive (yerel veritabanı)
```

- **View:** sadece çizer ve kullanıcı dokunuşunu ViewModel'e iletir. Hesap, veri okuma ya da kayıt yapmaz.
- **ViewModel:** `ChangeNotifier`. Ekranın durumunu (`loading`, `empty`, `error`, `success`) ve hazır sonuçlarını tutar, değişince ekrana haber verir. Yalnızca Repository'leri bilir; `BuildContext` ya da widget içermez.
- **Repository:** ViewModel ile veritabanı arasındaki tek kapıdır. Hive'a doğrudan o dokunur.
- **Saf hesaplar** (örneğin istatistik hesapları) ayrı bir sınıfta tutulur, ekrandan ve veritabanından bağımsız test edilir.

### Klasör yapısı

```
lib/
├── main.dart, app_widget.dart     Uygulama girişi
├── app_module.dart                Ana modül, alt modülleri bağlar
├── app_shell.dart                 Alt menü ve sayfa alanı
├── core/                          Ortak parçalar
│   ├── constants/                 Sabitler (Hive kutu adları)
│   ├── network/                   Dio ayarı, hata sınıfı
│   ├── theme/                     Renk, boşluk, yazı stili, tema
│   ├── utils/                     Yardımcılar (süre yazısı, gün kısaltması...)
│   └── widgets/                   Ortak bileşenler (kart, buton, çip, durum görünümleri)
├── data/
│   ├── local/                     Hive kaynakları
│   ├── remote/                    Dio ile yazılmış yerel sahte API katmanı
│   └── repositories/              Repository'ler
├── models/                        Birden çok modülün kullandığı modeller
└── modules/
    └── <modül>/                   dashboard, subjects, tasks, pomodoro, statistics, settings
        ├── <modül>_module.dart    Modülün rotaları ve bağımlılık kayıtları
        ├── view_model/            ViewModel (ve varsa saf hesap sınıfları)
        ├── view/                  Sayfalar
        │   └── widgets/           Sayfaya özel bileşenler
        └── models/                Sadece bu modülün ekranlarında kullanılan modeller
```

**Model nereye konur?** Tek modülün ekranlarına özel olan model o modülün `models/` klasörüne, `data/` katmanının ya da birden çok modülün kullandığı model `lib/models/` altına gider.

**Bağımlılık enjeksiyonu:** Her modül, kendi bağımlılıklarını kendi `*_module.dart` dosyasında `addLazySingleton` ile kaydeder; sayfalar ViewModel'i `inject<T>()` ile alır.

## Kurulum

Gereksinimler: Flutter SDK (Dart `^3.13.1` ile uyumlu sürüm) ve bir Android cihaz ya da emülatör.

```bash
git clone https://github.com/kubrainy/StudyFlow.git
cd StudyFlow
flutter pub get
flutter run
```

## Testler

```bash
flutter analyze     # statik analiz
flutter test        # birim ve widget testleri
```

Testler `test/` altında, `lib/` ile aynı klasör düzenindedir (`test/modules/<modül>/view_model`, `view`, `view/widgets`). Repository'ler `mocktail` ile taklit edilir; böylece ViewModel testleri gerçek veritabanına ihtiyaç duymaz.

Şu an kapsananlar: Repository'ler (hem taklit kaynaklarla hem gerçek Dio zinciriyle), Dio katmanı ve yerel adaptör, ViewModel'ler, bildirim servisi, istatistik hesapları, ortak bileşenler ve modüllerin widget'ları. Integration testleri henüz yazılmadı.

**İnternetsiz cihaz doğrulaması** (Android 15 telefon, hiçbir ağ bağlı değil): ders ekleme ve silme (bağlı görevlerle birlikte), görev ekleme ve tamamlama, derse bağlı Pomodoro oturumu kaydı, Pomodoro başlarken bitiş alarmının kurulması, duraklatınca iptal edilmesi, devam edince yeniden kurulması, bitirince iptal edilmesi ve İstatistikler ekranındaki rakamlar sorunsuz çalıştı.

## Ekran görüntüleri

Eklenecek.

## Bilinen problemler ve eksikler

- Bildirim yalnızca Android'de ve yalnızca çalışma aşamasının bitişinde gelir; mola bitişinde bildirim yok. Telefon yeniden başlarsa Pomodoro sayacı ve planlanmış bildirim sıfırlanır.
- REST katmanı gerçek bir sunucuyla konuşmaz: Dio isteklerini uygulamanın içindeki sahte sunucu (`LocalApiAdapter`) karşılar ve Hive'a yazar, internete hiç çıkılmaz. Ders ve görev yazma işleri (ekle, düzenle, sil, tamamla) bu yoldan gider; listeler Hive'dan okunur, yani GET uygulama akışında kullanılmaz. Çalışma oturumları ve ayarlar REST dışındadır.
- Bir kayıt arada silinmişken düzenlenmeye ya da silinmeye çalışılırsa sahte sunucu 404 döner, sayfanın üstünde "İşlem başarısız: Kayıt bulunamadı." yazar. Ders silinirken görev silme yarıda hata verirse o ana kadar silinen görevler geri gelmez.
- Integration testleri ve release build (APK/AAB) henüz yapılmadı.
- İstatistiklerdeki "bu hafta biten görev" sayısı, tamamlanma tarihi kaydedilmemiş eski görevleri saymaz.
- İstatistiklerdeki "Derslere göre" bölümü haftalık değil, tüm zamanları toplar.
