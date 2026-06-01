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

## Comportement cible

### Page d'accueil — le seul écran modifié

1. **Définition stricte d'un créneau parfait** : suite continue d'heures où
   **chaque heure** est parfaite — `windSpeed < 5`, ciel dégagé
   (`cloudCover < 40`), en journée (`isDaylight`), sans pluie
   (`precipitation == 0`) — d'une durée **≥ 2h**.
2. **Priorité visuelle** : pour **chacun des 7 jours**, les créneaux parfaits
   sont listés **en tête** de la carte du jour, suivis des autres créneaux
   (Très bien / Bien / Jouable). Rien n'est masqué.
3. **Pas de doublon horaire** : un créneau parfait strict est souvent un
   sous-ensemble d'un bloc jouable plus large. Le découpage doit éviter qu'un
   même horaire apparaisse deux fois. Règle : on extrait d'abord les segments
   parfaits stricts (≥ 2h) ; les heures jouables **restantes** autour forment
   les créneaux non-parfaits (eux aussi ≥ 2h pour rester affichables).

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
