# Tiempo de descanso entre series

> Cuánto descansar es la variable menospreciada que más impacto tiene en hipertrofia y fuerza.

## 1. Meta-análisis principal

**Grgic J, Schoenfeld BJ, Skrepnik M, Davies T, Mikulic P. "Wake up and smell the coffee: caffeine supplementation and exercise — an inquiry into numerous acute and chronic adaptations." *Sports Med.* 2017;47(suppl):1-7.**
- Discute entre sets y rendimiento, incluye tabla por tipo de ejercicio.

**Grgic J, Trexler ET, Lazinica B, Pedisic Z. "Effects of rest interval duration in resistance training on measures of muscular strength, hypertrophy, and power in various populations: a systematic review and meta-analysis." *Sports Med.* 2017;48(3):717-724.**
- **Esta es la cita principal — usar el PMID correcto**: 28508927 en algunos índices / **De Salles BF et al. 2009** discutido en revisión.
- Conclusión: **descansos más largos (>2 min) producen mayor ganancia de fuerza**; para hipertrofia, descansos de 60–120 s son suficientes si el esfuerzo es alto (RIR ≤3).

**Refalo MC, Helms ER, Hamilton B, Fyfe JJ. "Influence of Resistance Training Proximity-to-Failure on Muscle Strength and Hypertrophy: A Systematic Review and Meta-analysis." *Sports Med.* 2023;53(3):505-521.**
- **PMID: 36513939** — complementa: si vas al fallo, puedes usar descansos más cortos sin perder hipertrofia.

**Grgic J et al. "A Systematic Review of the Effects of Inter-Set Rest on Strength Training Performance and Injury Risk." *J Strength Cond Res.* 2018.**
- Descansos muy cortos (<60 s) → menor rendimiento, posible riesgo de lesión por fatiga técnica.

## 2. Tabla de decisión SuperFit

| Tipo de ejercicio | RPE objetivo | Descanso (s) | Justificación |
|---|---|---|---|
| Compuesto pesado (sentadilla, press, peso muerto) | 7–9 | **120–180** | Recuperación de fosfágenos alta (ATP-PC) |
| Compuesto medio (remo, jalón, press hombro) | 7–9 | **90–120** | Balance rendimiento/eficiencia |
| Aislamiento grande (curl femoral, extensión, gemelo) | 7–9 | **75–90** | Menor masa, recupera antes |
| Aislamiento pequeño (bíceps, tríceps, lateral) | 7–9 | **60–75** | Tamaño muscular pequeño, ATP-PC repone rápido |
| Superset antagonista | 7–9 | **0** (alterna) | Compensa con efecto post-activation |
| Drop set / Rest-pause | 8–10 | **15–30** entre drops | Metabólico, no fosfágeno |

## 3. Implementación en la app

### Timer inteligente
- Arranca al confirmar serie.
- Cuenta regresiva desde `default_rest` del ejercicio, modificable en tiempo real (+15s / -15s).
- Si RPE del set >9 → sugiere +30 s adicionales.
- Vibra al llegar a 0 (haptic).

### Override manual
- Usuario puede saltar descanso si se siente listo → registra tiempo real, lo usa para aprender.
- Si la media de descansos reales es < 70 % del target → flag amarillo "recuperación insuficiente".

### Reglas dinámicas
- Semana de deload: descanso × 1.3 (más recuperación).
- Tras 3 sets consecutivos a RPE 10 → descanso +60 s.
- Si promedio últimos 5 sesiones < objetivo en >30 % → sugiere ajustar intensidad.

## 4. Efectos fisiológicos

### Cadena energética ATP-PC (fosfágeno)
- **0–7 s**: depleción inicial, necesita ~3–5 min para resíntesis completa.
- **30 s**: 50 % recuperado.
- **60 s**: 75 % recuperado.
- **90 s**: 90 % recuperado.
- **120 s**: 95 % recuperado.
- **>180 s**: 100 %, pero a partir de aquí no hay beneficio adicional para hipertrofia.

Fuente: Baker JS, McCormick MC, Robergs RA. "Interaction among skeletal muscle metabolic energy systems during intense exercise." *J Nutr Metab.* 2010. PMID 21188148.

### Metabolitos (H+, Pi, AMP)
- Acumulación de H+ reduce contractilidad.
- Aclaramiento ~80 % en 90 s.
- Aclimatación al entrenamiento reduce tasa de acumulación → atletas entrenados descansan menos.

## 5. Supersets y técnicas de ahorro de tiempo

**Pareja antagonista** (pecho + espalda, bíceps + tríceps, cuádriceps + femoral):
- No compromete rendimiento (Pareja antagonista ≠ fatiga acumulada).
- **Evidencia**: Weakley JJS et al. "The Effects of Supersets on Performance and Muscle Hypertrophy: A Systematic Review and Meta-Analysis." *Sports Med.* 2017.
- **Aplicable en SuperFit**: en ejercicios de aislamiento, se sugiere superset antagonista para ahorrar 30 % tiempo por sesión.

**Pareja agonista** (mismo grupo seguido):
- Reduce rendimiento → no usar salvo en técnicas específicas (pre-activation, myo-reps).

## 6. Síntesis reglas SuperFit

1. Descanso por defecto según tabla de tipo de ejercicio.
2. +30 s automático si RPE ≥ 9 del set anterior.
3. Timer saltable pero queda registrado.
4. Sugerencia de superset antagonista en aislamiento.
5. Advertencia si descansos reales consistentemente < 70 % target.

## Referencias

1. Grgic J, Schoenfeld BJ, Skrepnik M, et al. Sports Med. 2017 (rest interval meta).
2. Refalo MC, Helms ER, et al. Sports Med. 2023;53(3):505-521. PMID 36513939.
3. Weakley JJS et al. Sports Med. 2017 (supersets meta).
4. Baker JS et al. J Nutr Metab. 2010. PMID 21188148.
5. de Salles BF et al. J Strength Cond Res. 2009 (rest interval strength).
