# xFaktura

Program do wystawiania faktur z obsługą
[Krajowego Systemu e-Faktur (KSeF)](https://ksef.podatki.gov.pl/),
napisany w języku [xDev](https://github.com/xDev-Language/xDev).

## Wymagania

Windows 10 lub nowszy, 64-bitowy.

## Instalacja

1. Pobierz `xFaktura-…-win64.zip` z [Releases](https://github.com/harbour-pl/xFaktura/releases/download/v0.0.0/xFaktura-2026-11-12-win64.zip).
2. Rozpakuj go, np. do `C:\`; powstanie katalog `C:\xFaktura`.
3. Uruchom `xfaktura.exe`.

Przy pierwszym uruchomieniu program sam zakłada obok siebie katalogi na dane
(rok, firma, ksef, kontrahenci, wydruki); przy kolejnych tylko sprawdza, czy są.

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