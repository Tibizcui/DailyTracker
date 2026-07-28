# DailyTracker 3.1

Version majeure : gros travail de stabilité et 10 nouveautés. Compatible avec le patch **Midnight 12.0.7** (interface 120007).

## Corrections de bugs

- L'onglet **The War Within** affichait « Midnight » dans le titre et les infobulles. C'est corrigé, chaque extension affiche désormais son vrai nom.
- **Fuite mémoire corrigée** : l'interface recréait tous ses cadres à chaque rafraîchissement (à chaque quête rendue, changement de zone, gain de réputation...). Elle réutilise maintenant les mêmes cadres. Nettement plus léger sur les longues sessions de jeu.
- Les rafraîchissements en rafale (changements de zone, mises à jour de réputation) sont désormais regroupés pour alléger la charge.
- Numéros de version harmonisés partout.
- Sécurités ajoutées sur l'ouverture via le menu Addons et l'intégration TibiSuite.

## Nouveautés

- **Défilement réel** du panneau des quêtes, avec barre latérale et molette. Fini le contenu coupé quand la liste est longue.
- **Compteur global** de complétion, affiché dans le titre et dans l'infobulle de la minicarte.
- Bouton **Réduire tout / Déployer tout** pour plier ou déplier toutes les sections d'un clic.
- Filtre **À faire** qui masque les quêtes déjà terminées.
- **Suivi manuel** des quêtes sans détection automatique : un bouton Fait / À faire, avec remise à zéro automatique au reset quotidien ou hebdomadaire. Ces quêtes comptent maintenant dans les barres de progression.
- **Temps restant** avant le reset quotidien et le reset hebdomadaire, sous la légende et dans l'infobulle minicarte.
- Les **catégories vides** (comme PvP) sont automatiquement masquées.
- La fenêtre **rouvre au login** si elle était ouverte à la déconnexion.
- Nouvelle commande **`/tdt check`** qui vérifie les identifiants de quêtes contre les données du jeu et signale ceux à corriger.
- **Interface bilingue français / anglais** (l'anglais bascule automatiquement selon le client).

---

# DailyTracker 3.1 (English)

Major stability overhaul plus 10 new features. Compatible with **Midnight 12.0.7** (interface 120007).

## Bug fixes

- The **The War Within** tab wrongly showed "Midnight" in the title and tooltips. Fixed.
- **Memory leak fixed**: the UI recreated every frame on each refresh (every turned-in quest, zone change, reputation gain...). It now reuses frames. Much lighter over long play sessions.
- Bursty refreshes (zone changes, reputation updates) are now batched to reduce load.
- Version numbers unified across the addon.
- Added safety guards for the Addons menu button and TibiSuite integration.

## New features

- **Real scrolling** for the quest panel, with a scrollbar and mouse wheel. No more clipped content on long lists.
- **Global completion counter** in the title and the minimap tooltip.
- **Collapse all / Expand all** button for the quest sections.
- **To do** filter that hides already completed quests.
- **Manual tracking** for quests without auto-detection: a Done / To do button, with automatic reset at the daily or weekly reset. These quests now count toward progress bars.
- **Time until daily and weekly reset**, under the legend and in the minimap tooltip.
- **Empty categories** (such as PvP) are hidden automatically.
- The window **reopens on login** if it was open at logout.
- New **`/tdt check`** command to validate quest IDs against the game data and flag those needing a fix.
- **Bilingual French / English** interface (switches automatically with the client).
