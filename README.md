## O knihovně

Experimentální **neoficiální** webscrape knihovna pro komunikaci se systémem [iCanteen](https://www.z-ware.cz/internetove-objednavky). Tento repozitář je nástupcem [hernik/canteenlib](https://git.mnau.xyz/hernik/canteenlib).

## Funkční funkce(\*)

- získání jídelníčku na aktuální den (s cenami)
- Objednání / zrušení objednávek
- Nabídnutí jídla do burzy / zrušení
- Získání a objednání cizího jídla z burzy

[Příklad používání](https://github.com/tpkowastaken/canteenlib/blob/main/example/test_everything_example.dart)

_\* Knihovna nemusí fungovat na všech instancích systému iCanteen, proto žádám každého, kdo může a je uživatelem iCanteen, aby otestoval funkčnost této knihovny a případné problémy [nahlásil na github issues](https://github.com/tpkowastaken/icanteenlib/issues/new?assignees=tpkowastaken&labels=kompatibilita&projects=&template=hl--en--kompatibility.md&title=Kompatibilita%3A+)_

### [Otestované instance iCanteen](https://github.com/tpkowastaken/canteenlib/blob/main/COMPATIBILITY.md)

## Licence

```
MIT License

Copyright (c) 2022-2023 Matyáš Caras, Tomáš Protiva and contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
