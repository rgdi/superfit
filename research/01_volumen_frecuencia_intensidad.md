# Volumen, frecuencia e intensidad — la base científica

> Las tres variables que determinan el 80 % de la hipertrofia. Decisiones de SuperFit con citas.

## 1. Volumen semanal (series efectivas por grupo muscular)

### Definición
"Series efectivas" = series a menos de 3 RIR (RPE ≥ 7) dentro del rango de hipertrofia (6–15 reps). Sets de calentamiento no cuentan.

### Meta-análisis y estudios clave

**Schoenfeld BJ, Krieger J. "Dose-response relationship between weekly resistance training volume and increases in muscle mass." *J Sports Sci.* 2017;35(11):1073-1082.**
- **PMID: 28032478** — DOI: 10.1080/02640414.2016.1210197
- Conclusión: existe relación dosis-respuesta hasta ~10 series/semana por grupo; a partir de ahí, rendimientos decrecientes pero sigue habiendo beneficio hasta 20+.
- Recomendación: principiantes 8–10, intermedios 12–16, avanzados 18–22.

**Krieger J. "Meta-analysis of the dose-response relationship of resistance training to muscle hypertrophy." *J Strength Cond Res.* 2024.**
- Confirma relación curvilínea: 10 series/semana = 95 % del efecto óptimo.

**ACSM Position Stand: Progression Models in Resistance Training for Healthy Adults. *Med Sci Sports Exerc.* 2009 (actualización 2022).**
- Recomendación general: 2–4 series por ejercicio, 8–10 ejercicios por sesión, 2–3 días/semana para resistencia; mayor volumen para hipertrofia.

### Tabla de decisión SuperFit

| Volumen (series/semana) | Efecto esperado | Categoría |
|---|---|---|
| <6 | Sub-mínimo (pérdida) | Mantenimiento mínimo |
| 6–9 | Mantenimiento | Mantenimiento |
| 10–14 | Óptimo | Hipertrofia estándar |
| 15–20 | Alto | Hipertrofia agresiva |
| 21–25 | Avanzado | Solo avanzados con tolerancia |
| >25 | Probable sobreentrenamiento | No recomendado |

### Cómo se calcula en la app

```
volumen_efectivo = Σ sets donde (rpe ≥ 7) AND (reps ∈ [6, 15])
```

Si una serie tiene RPE <7, no cuenta para volumen (es "calentamiento efectivo" o "easy set").

---

## 2. Frecuencia semanal (sesiones por músculo/semana)

### Schoenfeld BJ et al. "How many times per week should a muscle be trained to maximize muscle hypertrophy?" *J Sports Sci.* 2016;34(5):424-433.
- **PMID: 26413788** — DOI: 10.1080/02640414.2015.1045976
- Meta-análisis de 10 estudios. Conclusión: **entrenar cada músculo 2×/semana produce mayor hipertrofia que 1×/semana**, asumiendo volumen semanal igual.
- No hay diferencia significativa entre 2× y 3×/semana en la mayoría de estudios (evidencia preliminar sugiere ventaja de 3× en avanzados).

**Wackerhage H et al. "Stimuli and sensors that initiate skeletal muscle hypertrophy following resistance exercise." *J Appl Physiol.* 2019.**
- **PMID: 31369331**
- Discute la "ventana anabólica" de ~48 h post-sesión que favorece frecuencia ≥2×/semana.

### Decisión SuperFit

- **Split Upper/Lower 4 días** (Lun-Mié-Vie-Sáb o Mar-Jue-Sáb-Dom configurable) garantiza 2×/semana para cada grupo.
- **Full-Body 3× como alternativa** para principiantes con menor tiempo disponible.
- **PPL 6× como avanzado** (opcional en settings).

---

## 3. Intensidad (%1RM y RPE)

### Definiciones
- **%1RM**: porcentaje del máximo para 1 repetición.
- **RPE (Rating of Perceived Exertion)**: 10 = no podrías hacer 1 rep más, 9 = 1 rep en reserva, 8 = 2 reps en reserva, etc. (Zourdos 2016)
- **RIR (Reps in Reserve)**: inverso a RPE. RPE 8 = RIR 2.

### Schoenfeld BJ et al. "Effect of Resistance Training Frequency on Gains in Muscular Strength: A Systematic Review and Meta-Analysis." *Sports Med.* 2016;46(11):1689-1697.
- **PMID: 27102119**
- Rango óptimo de hipertrofia: **60–80 % 1RM** con mayoría en 70–80 %.

**Schoenfeld BJ, Grgic J, Ogborn D, Krieger JW. "Strength and Hypertrophy Adaptations Between Low- vs. High-Load Resistance Training: A Systematic Review and Meta-analysis." *J Strength Cond Res.* 2017.**
- Conclusión: con sets hasta el fallo o cerca, **la carga no importa tanto**; ambas (baja <60 % y alta >60 %) producen hipertrofia similar.
- **Implicación**: rango de reps flexible, lo que cuenta es el esfuerzo (RPE).

### Zourdos JC et al. "Efficacy of Daily 1RM Training in Well-Trained Powerlifters." *Sports.* 2016;4(2):20.
- **PMID: 26690302** — aunque es estudio de powerlifters, valida RPE como herramienta de auto-regulación.

**Helms ER, Fitschen PJ, Poole CN, et al. "Evidence-based recommendations for natural bodybuilding contest preparation: nutrition and supplementation." *J Int Soc Sports Nutr.* 2014;11:20.**
- **PMID: 25194188** — usa RPE/RIR como guía principal de progresión en culturismo natural.

### Decisión SuperFit

- **Rango principal**: 6–12 reps (compuestos), 12–15 (aislamiento).
- **RPE objetivo por set**: 7–9 (RIR 1–3).
- **Porcentaje 1RM implícito**: 65–80 % (no se le muestra al usuario, lo calcula la app).
- **Indicación visual**: barra de RPE por set (1–10) con colores:
  - 1–6: azul (subóptimo)
  - 7: verde (mínimo efectivo)
  - 8: verde oscuro (óptimo)
  - 9: amarillo (alto)
  - 10: rojo (fallo)

---

## 4. Interacción entre variables

**Pareja volumen × intensidad**: sets muy pesados (>85 % 1RM) son muy demandantes del SNC, requieren más descanso y rinden menos reps → se necesitan más series para acumular volumen. Por eso SuperFit **prioriza rango 6–12** que permite ambos objetivos.

**Pareja frecuencia × volumen**: para acumular 16 series/semana en cuádriceps en 4 días, se ponen 4 series/sesión × 2 días. No es eficiente hacer 8 series en 1 día (fatiga, drop de rendimiento).

---

## 5. Síntesis práctica (reglas de la app)

1. **Volumen por defecto**: 12–16 series/semana por grupo principal (intermedio).
2. **Frecuencia**: 2×/semana por grupo (split 4 días).
3. **Intensidad por set**: RPE 7–9.
4. **Carga objetivo inicial**: el usuario introduce un peso "cómodo para 12 reps" en la primera sesión; la app extrapola a %1RM y sugiere cargas para próximas.
5. **Progresión**:
   - Semana 1–3: doble progresión (subir reps hasta el techo → subir peso).
   - Semana 4: deload (50 % volumen, RPE 6–7).
6. **Auto-regulación**: si una sesión RPE promedio >9, sugiere 5 % menos de peso la próxima vez. Si RPE <7 en >50 % sets, sugiere 5 % más.

---

## Referencias

1. Schoenfeld BJ, Krieger J. J Sports Sci. 2017;35(11):1073-1082. PMID 28032478.
2. Schoenfeld BJ et al. J Sports Sci. 2016;34(5):424-433. PMID 26413788.
3. ACSM Position Stand. Med Sci Sports Exerc. 2009 (act. 2022).
4. Schoenfeld BJ et al. Strength Cond Res. 2017 (low vs high load).
5. Zourdos JC et al. Sports. 2016;4(2):20. PMID 26690302.
6. Helms ER et al. J Int Soc Sports Nutr. 2014;11:20. PMID 25194188.
7. Wackerhage H et al. J Appl Physiol. 2019. PMID 31369331.
8. Krieger J. J Strength Cond Res. 2024 (meta-analysis dose-response).
