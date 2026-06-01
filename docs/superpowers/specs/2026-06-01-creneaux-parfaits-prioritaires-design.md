# Créneaux parfaits prioritaires sur la page d'accueil

## Objectif

Mettre en avant les créneaux parfaits (≥ 2h) en tête de chaque jour sur la page
d'accueil de Volley Météo, sans rien cacher des autres créneaux. Le détail du
jour (heure par heure) reste inchangé.

## Comportement actuel

- `home_screen.dart` affiche 7 cartes de jour. Chaque carte liste **tous** ses
  créneaux dans l'ordre chronologique.
- Un créneau (`VolleyballWindow`) est un bloc contigu d'heures jouables
  (`windSpeed < 15`, `precipitation == 0`, en journée) d'au moins 2h.
- La note du créneau (`VolleyRating.parfait / tresBien / bien / jouable`) dérive
  des **moyennes** du bloc. Un créneau noté `Parfait` peut donc contenir une
  heure moins bonne diluée dans la moyenne.
- Le clic sur un jour ouvre `day_detail_screen.dart` : vue heure par heure.

## Comportement cible (révisé)

> Révision après test terrain : l'accueil ne montre plus une liste de créneaux
> moyennés (qui affichait p.ex. « 07h–15h Bien » en noyant la fin venteuse).
> Objectif réel : savoir d'un coup d'œil **quand aller au beach**.

### Page d'accueil — le seul écran modifié

1. **Un seul créneau par jour : le meilleur.** Pour chacun des 7 jours, on
   affiche uniquement le meilleur créneau (ou « Pas de créneau favorable » si
   aucune plage jouable ≥ 2h).
2. **Vent faible avant tout.** On classe les heures en paliers de vent :
   `< 5` (parfait), `< 10`, `< 15` (jouable). Le meilleur créneau est le segment
   continu du **palier le plus calme** disponible ce jour-là qui dure **≥ 2h**.
   On préfère donc un créneau calme de 2h à un long créneau plus venteux.
3. **Durée variable.** Le créneau s'étend tant que le vent reste dans le même
   palier (de 2h à toute la matinée selon la météo).
4. **Note honnête (pas de moyenne trompeuse).** La note (`Parfait` / `Très bien`
   / `Bien`) dépend du **vent maximum** du créneau, pas de la moyenne : toutes
   les heures du créneau respectent donc le seuil annoncé.
5. Contraintes communes : en journée (`isDaylight`), sans pluie
   (`precipitation == 0`). La pluie et la nuit coupent les segments.

### Détail du jour — inchangé

Aucune modification. La vue heure par heure et les infos météo restent
exactement comme aujourd'hui.

## Impact technique

- **`weather_service.dart` (`_findWindows`)** : faire évoluer la détection de
  créneaux pour produire deux catégories par jour — créneaux parfaits stricts
  (≥ 2h) et créneaux non-parfaits (≥ 2h sur les heures restantes) — sans
  chevauchement horaire.
- **`volleyball_window.dart`** : la note `Parfait` doit refléter un créneau
  strictement parfait. Les autres notes restent basées sur les moyennes du bloc
  restant.
- **`home_screen.dart` (`_DayCard`)** : ordonner les créneaux parfaits en
  premier dans la liste du jour.
- **`day_detail_screen.dart`** : aucun changement.

## Hors périmètre (YAGNI)

- Pas de regroupement de créneaux dans le détail du jour.
- Pas de repli/fallback : si un jour n'a pas de créneau parfait, ses créneaux
  non-parfaits s'affichent normalement (ils ne sont jamais cachés).
- Pas de changement de localisation, de plage de jours, ni de design global.

## Critères de réussite

- Un jour avec une plage continue d'heures toutes parfaites ≥ 2h affiche ce
  créneau en tête, badge `Parfait`.
- Aucun horaire n'apparaît dans deux créneaux du même jour.
- Le détail du jour est identique à la version actuelle.
