# Boodschappenapp (Wordbattle App)

Deze korte gids legt uit hoe je de nieuwste code uit GitHub via **GitHub Desktop** ophaalt en vervolgens in **Xcode** bouwt.

## Laatste wijzigingen ophalen met GitHub Desktop
1. Open **GitHub Desktop** en selecteer de repo in de linkerkolom.
2. Controleer linksboven of je op de juiste branch zit (meestal `main` of `work`).
3. Zie je een aparte branch met een wijziging (bijv. `origin/work`)? Klik op de branch-dropdown linksboven, selecteer die branch en klik op **Switch Branch**.
4. Klik daarna rechtsboven op **Fetch origin**. Verschijnt er een blauwe **Pull**-knop, klik daarop om de nieuwe commit binnen te halen.
5. In het tabblad **History** zie je de nieuwste commit. De lokale map bevat nu dezelfde code als op GitHub.com, inclusief de branch die je hebt gekozen.

## Project openen in Xcode
1. Open de lokale projectmap in Finder.
2. Dubbelklik op `Wordbattle App.xcodeproj` (of kies **File > Open...** in Xcode en navigeer naar dit bestand).
3. Kies bovenin Xcode de app-scheme en een simulator of aangesloten device.

## Builden en draaien
- Build: druk **⌘B**.
- Run: druk **⌘R** om te starten op de gekozen simulator/device.

> Tip: Als je na het testen terug wilt naar je hoofdbranch (bijv. `main`), klik weer op de branch-dropdown in GitHub Desktop en kies de branch die je wilt gebruiken, gevolgd door **Fetch** → **Pull**.

## Veelvoorkomende checks
- Als je geen nieuwe commits ziet: controleer of de juiste branch is geselecteerd en of de remote-URL klopt via **Repository > Repository Settings > Remote** in GitHub Desktop.
- Bij provisioning- of signing-fouten: zorg dat je Apple ID is toegevoegd onder **Xcode > Settings > Accounts**.
- Rare buildfouten? Kies **Product > Clean Build Folder** (⌥⇧⌘K) en probeer opnieuw.
