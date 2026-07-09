# Apéndice — protocolo de uso de SuperFit y mantenimiento

> Cómo usar la app una vez instalada. Manual de usuario condensado.

## 1. Primer arranque (onboarding, 60 s)

1. **Selecciona nivel** (principiante, intermedio, avanzado).
2. **Selecciona objetivo** (hipertrofia, fuerza, mantenimiento, definición).
3. **Unidades** (kg / lb).
4. **Idioma** (es / en).
5. **Día de la semana actual** para arrancar tu plan.
6. **Foto inicial** (opcional pero recomendado para comparar progreso).

La app genera:
- Plan de 4 semanas (3 carga + 1 deload).
- Rutina del día.
- Pesos sugeridos basados en tu primera sesión.

## 2. Pantalla principal (Home)

- **Card "Hoy"**: nombre rutina, duración estimada, músculos principales, botón EMPEZAR.
- **Streak**: días consecutivos entrenados (congelado si fallas >2 días).
- **Resumen última sesión**: fecha, duración, RPE promedio, total series.
- **Mini-gráfico**: volumen semanal (últimas 4 semanas).

## 3. Sesión de entrenamiento

### Flujo
1. **Warmup guiado** (3 min movilidad + 3 min específicos).
2. **Ejercicio 1 → N**: por cada uno:
   - Imagen con músculos activados resaltados.
   - Instrucciones y cues.
   - Set logger:
     - Reps objetivo (p.ej. 8–12).
     - Peso (con sugerencia basada en historial).
     - RPE post-set (slider 1–10).
     - Botón CHECK → guarda set, arranca timer descanso.
   - Timer descanso con vibración al 0.
3. **Cooldown** (2 min estiramientos).
4. **Cierre sesión**:
   - Notas globales.
   - RPE de la sesión.
   - Sensación general (energía, motivación, sueño).

### Si la app se cierra a media sesión
- Se guarda automáticamente. Al reabrir, "Recuperar sesión" en home.

## 4. Progresión automática

- **Doble progresión**: si completas todas las series al techo de reps a RPE ≤8 dos veces seguidas → sube 2.5 kg.
- **RPE demasiado alto**: si promedio >9 tres sesiones → sugiere -5% peso.
- **Meseta detectada** (3 semanas sin progresar) → propone variante o deload.

## 5. Progreso visual

- **Galería de fotos** por fecha con comparador lado-a-lado.
- **Métricas corporales**: peso, % grasa (manual), perímetros.
- **1RM estimado** por ejercicio (Epley): `1RM = peso × (1 + reps/30)`.
- **Volumen semanal** por grupo muscular.

## 6. Enciclopedia de ejercicios

- Lista completa con filtros (músculo, patrón, equipamiento).
- Detalle: imagen, músculos activados, instrucciones, cues, contraindicaciones.

## 7. Plan adaptativo

La app aprende de:
- **Histórico de pesos y RPE** → qué ejercicios te cuestan más.
- **Adherencia** → qué días rindes mejor.
- **Fatiga acumulada** → cuándo meter deload extra.
- **Volumen efectivo** → si llegas al target semanal.

Cada lunes (o día de inicio de semana) muestra:
- Resumen de la semana anterior.
- Ajuste al plan si procede.
- Próximo deload programado.

## 8. Backup y privacidad

- **100% local**: nada sale del dispositivo.
- **Exportar datos**: genera JSON + DB en carpeta accesible, lo puedes guardar en Drive o compartir.
- **Restaurar**: importas el JSON de un backup previo.
- **Borrar todo**: opción en settings (irreversible).

## 9. FAQ rápido

**¿Y si el gym no tiene una máquina?** → la app sugiere sustitutos del mismo patrón muscular.

**¿Y si no llego al peso objetivo?** → registra el peso real y RPE, la app ajusta.

**¿Y si entreno más días de los planificados?** → la app reorganiza las rutinas según días disponibles.

**¿Y si paro 2 semanas por vacaciones?** → la app detecta el gap, sugiere protocolo de retorno (60% volumen primera semana).

**¿Necesito pesas en casa?** → no, todo se hace con máquinas de gym.

## 10. Cuándo NO usar la app

- Dolor agudo articular → consulta médico, la app no es sustituto.
- Embarazo → adapta con profesional, la app no cubre embarazo.
- Menores de 16 años → uso bajo supervisión.
- Patologías cardiovasculares → médico primero.

---

**Filosofía SuperFit:** la app es tu entrenador silencioso, no tu amo. Si un día prefieres hacer otra cosa, hazla. La app se adapta a ti, no al revés.
