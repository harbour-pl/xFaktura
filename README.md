# xFaktura

Program do wystawiania faktur z obsługą
[Krajowego Systemu e-Faktur (KSeF)](https://ksef.podatki.gov.pl/),
napisany w języku [xDev](https://github.com/xDev-Language/xDev).

## Wymagania

Windows 10 lub nowszy, 64-bitowy.

## Instalacja

1. Pobierz `xFaktura-…-win64.zip` z [Releases](https://github.com/xDev-Language/xFaktura/releases).
2. Rozpakuj go, np. do `C:\`; powstanie katalog `C:\xFaktura`.
3. Uruchom `xfaktura.exe`.

Przy pierwszym uruchomieniu program sam zakłada obok siebie katalogi na dane
(rok, firma, ksef, kontrahenci, wydruki); przy kolejnych tylko sprawdza, czy są.

## Funkcje

- [x] Dane firmy i lista kontrahentów
- [x] Faktury VAT i faktury korygujące – wydruk do PDF
- [x] Plik XML faktury zgodny ze schematem FA(3)
- [x] Wysyłka do KSeF tokenem, numer KSeF i pobieranie UPO
- [x] Kod QR faktury (KOD I) na wydruku
- [x] Lista tokenów KSeF – token zapisany zaszyfrowany
- [x] Lista certyfikatów KSeF – wczytanie pliku `.crt` i klucza `.key` z Aplikacji Podatnika
- [x] Tryb offline (offline24, niedostępność, awaria) – kod QR certyfikatu (KOD II)
- [x] Termin wysyłki faktur offline i przypomnienie o nim
- [x] Archiwizacja i odtwarzanie danych
- [x] Logowanie do KSeF certyfikatem (XAdES)

## Budowanie ze źródeł

Wymagany jest kompilator [xDev](https://github.com/xDev-Language/xDev/releases).

```bat
xdev xfaktura.rmk
```

Powstaje `xfaktura.exe`. Źródła są w katalogu `src`.

## Licencja

GNU General Public License, wersja 3, plik [LICENSE](LICENSE).

> [!NOTE]
> Projekt jest w budowie (wersja 0.0.0).

> [!CAUTION]
> Zanim zaczniesz wystawiać prawdziwe faktury, wypróbuj program na środowisku testowym KSeF:
> Pliki -> Ustawienia -> Firma -> KSeF -> Testowe. Faktury testowe nie mają mocy prawnej.
