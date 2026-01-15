---
description: Todo listesindeki maddeleri sırasıyla gerçekleştirmek için kullanılan ana iş akışı.
---

Bu workflow, `todo-list.md` dosyasındaki bir maddeyi alıp, planlamadan uygulamaya ve test aşamasına kadar uçtan uca tamamlamanızı sağlar.

### Adımlar:

1. **Yeterlilik Planı Oluştur**
   - `todo-list.md` dosyasını oku.
   - Sıradaki veya istenen maddeyi seç.
   - Bu maddeyi yerine getirmek için kapsamlı bir `implementation_plan` (yeterlilik planı) oluştur.
   - Planı kullanıcıya sun veya onay al.

2. **Özellikleri Fonksiyonelleştir**
   - Oluşturulan plana sadık kalarak gerekli kod değişikliklerini yap.
   - Yeni fonksiyonları ve mantıksal yapıları oluştur.

3. **Kodu Kontrol Et**
   - Yazılan kodun doğruluğunu, okunabilirliğini ve projenin geri kalanıyla uyumunu kontrol et.
   - Olası bugları gözden geçir.

4. **Derle**
   - Projenin derleme komutlarını çalıştır (Örn: `./build.sh`, `make`, `npm run build` vb.).
   - Derleme hataları varsa gider.

5. **Test Et**
   - Uygulanan özelliğin istendiği gibi çalışıp çalışmadığını test et.
   - Varsa test scriptlerini çalıştır veya manuel olarak doğrula.

6. **Karar ve Todo Güncelleme**
   - **Eğer çalışıyorsa:** `todo-list.md` dosyasında ilgili maddenin yanına tik at (tamamlandı olarak işaretle).
   - **Eğer çalışmıyorsa:** Hataları tespit et ve **2. Adıma (Fonksiyonelleştirme)** geri dön.

7. **Changelog Kaydı**
   - Yapılan değişikliği, sürüm numarasını ve kısa açıklamasını `changelog.md` dosyasına ekle.

8. **Uygulamayı Aç**
   - Uygulamayı çalıştırarak son halini gözlemle.
