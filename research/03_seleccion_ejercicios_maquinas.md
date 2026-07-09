# Selección de ejercicios y máquinas

> Por qué elegimos máquinas de palanca selectora y cables, no peso libre.

## 1. Criterios de selección

### ¿Por qué priorizar máquinas?

**Máquinas de palanca selectora (selectorized):**
- **Seguridad**: sin riesgo de caída de barra, sin necesidad de spotter.
- **Facilidad de carga**: cambio de peso en 5 s.
- **Curva de fuerza**: muchas tienen path fijo que reduce puntos débiles → mayor carga efectiva.
- **Aislamiento**: menor estabilización requerida → el músculo objetivo trabaja más.

**Evidencia:**
- Haugen ME, Vårvik FT, Larsen S, Wernbom M, Løvold S, Raastad T. "Free Weight vs Machine-Based Resistance Training: A Systematic Review and Meta-analysis." *J Strength Cond Res.* 2021.
- **Conclusión**: ambos producen hipertrofia similar; las máquinas pueden ser superiores para principiantes (seguridad) y para ejercicios de aislamiento (carga efectiva).

**Cables y poleas:**
- **Tensión constante** a lo largo del ROM (vs. peso libre donde la resistencia varía).
- Versatilidad: ángulo de tracción modificable → estímulo desde distintos vectores.
- Útiles para aislamiento de dorsales, deltoides posteriores, bíceps, tríceps.

### ¿Cuándo peso libre?

- **Sentadilla libre, peso muerto, press banca**: parte del "ABC" del culturismo.
- Pero en SuperFit preferimos **hack squat, leg press, chest press machine** por seguridad y menor requirement de spotter.
- Sentadilla con barra queda como **alternativa opcional** para usuarios avanzados.

## 2. Catálogo de máquinas — gimnasio comercial típico (Basic-Fit, McFIT, Fitness Park, etc.)

### Tren superior

| Máquina | Músculo principal | Patrón |
|---|---|---|
| Chest Press Machine | Pectoral mayor (clavicular + esternal) | Horizontal push |
| Pec Deck / Fly Machine | Pectoral mayor (esternal) | Horizontal adduction |
| Shoulder Press Machine | Deltoides anterior, lateral, tríceps | Vertical push |
| Lateral Raise Machine | Deltoides lateral | Abducción hombro |
| Lat Pulldown | Dorsal ancho, bíceps, braquial | Vertical pull |
| Seated Row Machine | Dorsal, romboides, trapecio medio, bíceps | Horizontal pull |
| Cable Tricep Pushdown | Tríceps (lateral + largo) | Extensión codo |
| Cable Bicep Curl | Bíceps, braquial | Flexión codo |
| Face Pull | Deltoides posterior, trapecio medio | Rotación externa + pull horizontal |
| Cable Crossover / Functional Trainer | Pectoral, deltoides anterior | Press multi-ángulo |
| Pullover Machine / Cable Pullover | Dorsal, pectoral (esternal) | Pull-over |

### Tren inferior

| Máquina | Músculo principal | Patrón |
|---|---|---|
| Leg Press | Cuádriceps, gluteos, isquios | Squat (acostado) |
| Hack Squat | Cuádriceps, gluteos | Squat (inclinado) |
| Leg Extension | Cuádriceps (aislamiento) | Extensión rodilla |
| Leg Curl (sentado o acostado) | Isquios (aislamiento) | Flexión rodilla |
| Hip Adductor Machine | Aductores | Aducción cadera |
| Hip Abductor Machine | Glúteo medio, menor | Abducción cadera |
| Standing Calf Raise | Gemelos, sóleo | Extensión tobillo |
| Seated Calf Raise | Sóleo | Extensión tobillo |
| Smith Machine | Multiuso (avanzado) | Variable |
| Hip Thrust Machine | Glúteo mayor | Extensión cadera |
| Back Extension | Erector espinal, glúteo | Extensión lumbar |

### Core / abdomen

| Máquina | Músculo principal | Patrón |
|---|---|---|
| Cable Crunch | Recto abdominal | Flexión tronco |
| Rotary Torso | Oblicuos | Rotación |
| Captain's Chair / Hanging Leg Raise | Recto abdominal, flexores cadera | Anti-extensión |

## 3. Mapeo músculo → ejercicios (subset clave)

### Pectoral mayor
- **Compuesto**: Chest Press Machine (selectorized)
- **Esternal**: Pec Deck
- **Clavicular (upper chest)**: Chest Press con respaldo reclinado, Press militar
- **Decúbito**: Cable Crossover desde arriba

### Dorsal ancho
- **Vertical pull**: Lat Pulldown (agarre neutro o supino)
- **Horizontal pull**: Seated Row Machine
- **Pull-over**: Cable Pullover

### Deltoides
- **Anterior**: Shoulder Press, front raises (cable)
- **Lateral**: Lateral Raise Machine
- **Posterior**: Face Pull, Reverse Pec Deck

### Cuádriceps
- **Compuesto**: Leg Press, Hack Squat
- **Aislamiento**: Leg Extension
- **Función**: Sentadilla con barra (alternativa)

### Isquiosurales
- **Compuesto**: Leg Curl acostado (más carga), Romanian Deadlift (avanzado)
- **Aislamiento**: Leg Curl sentado (más aislación)
- **Movimiento**: Buenos días (avanzado)

### Glúteo mayor
- **Compuesto**: Hip Thrust Machine, Sentadilla hack
- **Aislamiento**: Cable Kickback, glúteo en máquina de abducción (4-way hip)

### Gemelos
- **Standing**: gemelo + sóleo
- **Seated**: énfasis en sóleo

## 4. Criterios de inclusión en SuperFit

1. **Disponibilidad**: máquina presente en ≥80 % de gimnasios comerciales UE (Basic-Fit, McFIT, Fitness Park, VivaFit, Holmes Place).
2. **Seguridad**: sin spotter requerido, sin riesgo de caída de peso.
3. **Evidencia**: ejercicio respaldado por al menos 1 estudio biomecánico/EMG.
4. **Aislamiento efectivo**: ratio músculo-objetivo/estabilizadores alto.

## 5. Por cada ejercicio guardamos

- `id` (slug, p.ej. "chest_press_machine")
- `name_es` / `name_en`
- `category`: compound | isolation
- `pattern`: squat | hinge | horizontal_push | vertical_push | horizontal_pull | vertical_pull | carry | rotation | isolation
- `primary_muscles`: [array de ids]
- `secondary_muscles`: [array de ids]
- `equipment_id`: id de la máquina
- `image_path`: ruta al PNG
- `instructions_es` / `instructions_en`: 3-4 puntos
- `cues_es` / `cues_en`: cues técnicos ("pecho arriba", "codos pegados")
- `default_reps`: 8-12 típico
- `default_rest`: según tabla Fase 2
- `rpe_target`: 7-9
- `contraindications`: array (p.ej. ["shoulder_impingement", "lower_back_pain"])
- `tempo`: 3-1-2-0 (excéntrico-pausa-concéntrico-pausa)
- `source_research`: DOI o PMID

## 6. Sustituciones automáticas

La app debe poder **sustituir un ejercicio** por otro del mismo patrón + músculos primarios. Esto se activa cuando:
- Máquina ocupada en el gym.
- Usuario tiene lesión o molestia.
- Estancamiento de 3+ semanas (variación).

Lógica:
```
sustituto = exercises
  where pattern == original.pattern
    AND primary_muscles intersect original.primary_muscles
    AND id != original.id
  order by (primary_muscles_overlap desc, equipment_diversity desc)
  limit 3
```

## 7. Bibliografía

1. Haugen ME et al. J Strength Cond Res. 2021 (free weight vs machine meta).
2. Contreras B. "Bodyweight Strength Training Anatomy." Human Kinetics, 2013.
3. Hales M. "Biomechanical analysis of the standing calf raise." 2021.
4. NSCA Exercise Technique Manual (7th ed., 2021).
5. Schoenfeld BJ. "Science and Development of Muscle Hypertrophy." Human Kinetics, 2020. (Libro de referencia)
6. Contreras B. "Anatomy of Stretching." 2014.
