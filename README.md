# Boodschappenapp (Wordbattle App)

Deze korte gids legt uit hoe je de nieuwste code uit GitHub via **GitHub Desktop** ophaalt en vervolgens in **Xcode** bouwt.

## Laatste wijzigingen ophalen met GitHub Desktop
1. Open **GitHub Desktop** en selecteer de repo in de linkerkolom.
2. Controleer linksboven of je op de juiste branch zit (meestal `main` of `work`).
3. Zie je een aparte branch met een wijziging (bijv. `origin/work`)? Klik op de branch-dropdown linksboven, selecteer die branch en klik op **Switch Branch**.
4. Klik daarna rechtsboven op **Fetch origin**. Verschijnt er een blauwe **Pull**-knop, klik daarop om de nieuwe commit binnen te halen.
5. In het tabblad **History** zie je de nieuwste commit. De lokale map bevat nu dezelfde code als op GitHub.com, inclusief de branch die je hebt gekozen.

### Wat als GitHub Desktop om je lokale wijzigingen vraagt?
- Krijg je een pop-up met opties zoals op de screenshot ("Leave my changes on main" / "Bring my changes…")? Kies **Leave my changes on main** als je de wijziging van GitHub.com wilt testen zonder jouw eigen lokale werk mee te verplaatsen. GitHub Desktop stash je werk dan op de huidige branch zodat je veilig kunt overschakelen.
- Heb je kleine lokale tweaks die je mee wilt nemen naar de nieuwe branch? Kies **Bring my changes…** zodat GitHub Desktop ze meeverhuist.
- Weet je het niet zeker? Kies **Cancel**, commit of stash je eigen werk, en probeer daarna opnieuw te switchen.

> Tip: Na het overschakelen en pullen kun je in **History** controleren of de online wijziging zichtbaar is. Wil je terug naar je oude branch, open opnieuw de branch-dropdown en kies je vorige branch; je gestashte werk wordt dan teruggezet.

## Wat nu doen als je een branch met mijn aanpassing ziet
1. **Klik op de branch** die je ziet in de blauwe balk of in de branch-dropdown (zoals `gavinblinksparks-blip`).
2. Kies **Fetch origin** en daarna **Pull**. De commit met de aanpassing wordt nu opgehaald.
3. Open het project in Xcode en draai een build (**⌘B**) of run (**⌘R**) om te checken of alles werkt.
4. Wil je hierna terug naar je eigen branch (bijv. `main` of `work`)? Open weer de branch-dropdown, kies je branch en klik opnieuw op **Fetch** → **Pull** zodat je lokale map netjes gelijk blijft.
5. Klaar met testen en wil je samenvoegen? Start een Pull Request vanaf de branch met de aanpassing of kies **Branch > Merge into Current Branch** in GitHub Desktop.

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
