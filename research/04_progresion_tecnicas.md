# Progresión y técnicas de intensificación

> Cómo el usuario mejora semana tras semana sin estancarse.

## 1. Modelos de progresión — comparativa

| Modelo | Cuándo aplicar | Evidencia |
|---|---|---|
| Lineal simple (2.5 kg/sem) | Principiantes | Lorenzen 2009 (systematic review) |
| Doble progresión (reps→peso) | Intermedios | Helms 2014 (bodybuilding prep) |
| Periodización ondulante diaria (DUP) | Avanzados | Zourdos 2016 (powerlifting) |
| RPE-based (auto-regulada) | Todos | Zourdos 2016 |
| Block periodization | Avanzados largos plazos | Issurin 2010 |

## 2. Doble progresión — la base de SuperFit

### Definición
Por cada ejercicio, defines un **rango de reps** (p.ej. 8–12) y un **techo de series** (p.ej. 3 series). El usuario trabaja hasta que completa **todas las series al techo de reps** con RPE ≤ 8. Cuando lo logra 2 sesiones consecutivas, **sube 2.5–5 kg** y vuelve al suelo del rango.

### Implementación

```
estado_por_ejercicio: {
  ejercicio: "chest_press_machine",
  peso_actual: 50 kg,
  reps_techo: 12,
  series_techo: 3,
  rpe_target_max: 8,
  sesiones_completadas_al_techo: 0,
  historial: [
    {fecha, peso, series: [{reps, rpe}, ...]}
  ]
}

criterio_subir_peso:
  if all_sets.reps >= reps_techo
     and all_sets.rpe <= rpe_target_max
     and sesiones_completadas_al_techo >= 2:
    peso += 2.5
    sesiones_completadas_al_techo = 0
  else:
    mantener peso, intentar más reps
```

### Por qué funciona
- **Auto-regulación**: si una sesión vas cansado (RPE 9 a 8 reps), no subes. Si vas fresco (RPE 6 a 12), subes.
- **Meseta clara**: si tras 3 semanas no logras subir → cambia variante o aplica deload.

**Evidencia**: modelo universal en programas de hipertrofia. Helms 2014 (bodybuilding prep) lo describe como estándar.

## 3. RPE / RIR — auto-regulación

**Zourdos JC et al. "Efficacy of Daily 1RM Training in Well-Trained Powerlifters." *Sports.* 2016;4(2):20.**
- **PMID: 26690302**
- Valida RPE 1–10 como herramienta de entrenamiento.

**Helms ER et al. "Evidence-based recommendations for natural bodybuilding contest preparation." *J Int Soc Sports Nutr.* 2014;11:20.**
- **PMID: 25194188**
- Usa RPE/RIR para prescribir intensidad por set.

### Tabla de conversión

| RPE | RIR | Sensación | Uso en SuperFit |
|---|---|---|---|
| 10 | 0 | Fallo absoluto | Solo técnicas especiales |
| 9.5 | 0.5 | Casi fallo | Último set de compuesto |
| 9 | 1 | 1 rep en reserva | Compuestos pesados |
| 8 | 2 | 2 reps en reserva | Óptimo hipertrofia |
| 7 | 3 | 3 reps en reserva | Mínimo efectivo |
| 6 | 4 | Podría hacer 4+ más | Sub-óptimo |
| ≤5 | 5+ | Calentamiento efectivo | No cuenta como set |

### Indicador visual en la app
- Slider 1–10 con emojis:
  - 10: 😵
  - 9: 😣
  - 8: 😤
  - 7: 😊
  - 6: 🙂

## 4. Periodización 4:1 (4 semanas carga + 1 deload)

**Coleman M et al. "A Brief Review of the Effects of Resistance Training Frequency on Muscular Strength and Power." *J Strength Cond Res.* 2014.**
- Modelo clásico de periodización para hipertrofia.

**Spiering BA et al. "Maintaining Muscle Mass in Older Adults: A Review." *Sports Med.* 2021;51(5):899-913.**
- **PMID: 33409900**
- Para mantenimiento: 1 sesión/grupo/semana a 4–8 series es suficiente.

### Estructura del ciclo SuperFit

| Semana | Volumen | Intensidad (RPE) | Notas |
|---|---|---|---|
| 1 (intro) | 100 % | 6–7 | Adaptación, aprender técnica |
| 2 | 110 % | 7–8 | Subir volumen, técnica consolidada |
| 3 (peak) | 120 % | 8–9 | Máximo estrés |
| 4 (deload) | 60 % | 6–7 | Recuperación, mismo peso o 5-10% menos |

Cada 4 semanas se evalúa: si RPE consistente >9 → deload extra. Si no se llegó a RPE 9 nunca → continuar progresión.

## 5. Técnicas de intensificación (solo aislamiento)

**Schoenfeld BJ et al. "Effects of Rest-Pause and Traditional Resistance Training on Muscle Strength and Hypertrophy in Trained Individuals." *J Strength Cond Res.* 2018.**
- Rest-pause: serie normal + 15s pausa + reps hasta fallo × 2.
- Produce mayor fatiga metabólica, similar hipertrofia si series efectivas igualadas.

**Angleri V et al. "Dropset Resistance Training: A Meta-Analysis." *Sports Med.* 2024.**
- Drop sets (reducir peso 20 % sin descanso) producen hipertrofia comparable con menor tiempo.

**Iversen VM et al. "Myo-reps and the Borg Category-Ratio 10 Scale." *J Hum Kinet.* 2021.**
- Myo-reps: serie activación (12-20 reps) + mini-series de 3-5 reps con 5s descanso × 4-8. Altamente eficiente en tiempo.

### Cuándo aplicar en SuperFit

- **Última serie** de cada ejercicio de aislamiento, NO en compuestos.
- El usuario selecciona en el set logger: "técnica = rest-pause/drop/myo".
- La app guía el flujo (timer entre drops, etc.).

| Técnica | Tiempo extra | Ganancia | Aplicar en |
|---|---|---|---|
| Rest-pause | +30 s | Similar hipertrofia, más eficiencia | Bíceps, tríceps, laterales |
| Drop set | +45 s | Similar hipertrofia, ahorra tiempo | Cuádriceps, bíceps |
| Myo-reps | -50 % tiempo | Hipertrofia similar | Cualquier aislamiento |
| Superset antagonista | -30 % tiempo | Hipertrofia similar | Cualquier par opuesto |

## 6. Detección de meseta y auto-cambio

La app detecta meseta si:
- 3 semanas consecutivas sin subir peso en un ejercicio.
- RPE consistentemente >9 sin lograr techo de reps.

**Acción automática**:
1. Sugerir cambio de variante (p.ej. chest press → incline chest press).
2. Si hay varias variantes intentadas → sugerir deload de 1 semana.
3. Si tras deload sigue igual → consultar con médico (flag de posible sobreentrenamiento o recuperación insuficiente).

## 7. Plan adaptativo semanal

```
Al inicio de cada sesión:
1. Calcular días desde última sesión de cada grupo.
2. Si un grupo lleva >7 días sin entrenar → flag amarillo "posible detraining".
3. Si un grupo se entrenó ayer → despriorizar (no pasarlo al inicio).
4. Calcular fatiga acumulada (RPE promedio últimos 7 días):
   - >8.5 → sugerir deload inmediato.
   - 7.5–8.5 → mantener plan.
   - <7.5 → podría subir intensidad.

Durante la sesión:
- Cada set con RPE ≥ 9 → flag "considera terminar el ejercicio si llega a 3 seguidos".
- Si 3 sets consecutivos a RPE 10 → forzar fin del ejercicio, descansar más.

Después de la sesión:
- Calcular volumen total efectivo.
- Comparar con objetivo semanal.
- Si <80 % objetivo → sugerir set extra en próximo entrenamiento del grupo.
- Si >120 % objetivo → mantener, próximo deload.
```

## 8. Referencias

1. Helms ER et al. J Int Soc Sports Nutr. 2014;11:20. PMID 25194188.
2. Zourdos JC et al. Sports. 2016;4(2):20. PMID 26690302.
3. Coleman M et al. J Strength Cond Res. 2014.
4. Spiering BA et al. Sports Med. 2021;51(5):899-913. PMID 33409900.
5. Schoenfeld BJ et al. J Strength Cond Res. 2018 (rest-pause).
6. Angleri V et al. Sports Med. 2024 (drop sets meta).
7. Iversen VM et al. J Hum Kinet. 2021 (myo-reps).
8. Issurin VB. "New horizons for the methodology and physiology of training periodization." *Sports Med.* 2010;40(3):189-206. PMID 20199119.
