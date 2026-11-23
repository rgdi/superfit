# Auditoría v1.6.0

Qué se revisó, cómo se midió y qué cambió. Dos revisiones independientes (una de la app,
otra del motor de planificación) más una batería automática de 180 perfiles.

## Cómo se mide la planificación

`app/test/planning_audit_test.dart` genera un programa para cada combinación de:
2–6 días × 35/50/75 min × principiante/intermedio/avanzado × hipertrofia/fuerza ×
catálogo completo/gimnasio pequeño (180 perfiles). Para cada uno calcula el volumen
semanal por músculo frente a su objetivo, el equilibrio empuje:tirón y los minutos.
Con `AUDIT_PRINT=1` imprime una línea por perfil.

| Métrica (180 perfiles)                         | Antes | Ahora |
|------------------------------------------------|-------|-------|
| Músculos a cero por programa (media / peor)    | 3,7 / 15 | 3,0 / 7 |
| Músculos por debajo del 50 % del objetivo      | 6,2   | 4,8   |
| Programas con un músculo grande a cero         | 4     | 0     |
| Empuje:tirón fuera de 0,5–1,6                  | 65    | 3     |
| Sesiones que superan el tiempo disponible      | 0     | 0     |
| Aductores (media del objetivo / perfiles a 0)  | 6 % / 138 | 61 % / 0 |
| Deltoides posterior (media / perfiles a 0)     | 11 % / 106 | 65 % / 0 |

Los músculos que quedan a cero en sesiones cortas son casi siempre los "opcionales"
(lumbares, oblicuos, trapecio superior), que se trabajan de forma indirecta y ya no
cuentan como carencia, y el glúteo medio / sóleo con 2 días de 35 min: no caben.
El test falla si estas cifras empeoran.

## Hallazgos y correcciones

### Planificación
1. El generador repartía por grupo muscular, no por músculo: deltoides posterior y
   aductores casi nunca recibían trabajo. → Generador v2 por músculo y por minuto.
2. Tres objetivos semanales distintos (generador, mapa, programa). → `muscleWeeklyTarget` único.
3. Sesiones de cuerpo completo cortas sin pierna. → Fase inicial con patrones obligatorios.
4. Sin límite superior: algunos músculos al 200 %. → Penalización por encima de 1,5×.
5. Datos del catálogo: pec deck y cruce de poleas marcados como tirón; prensa/hack con
   isquios como secundarios (trabajan aductores, Kubo 2019, PMID 31230110); remo con lumbares.
6. Lesiones: press de hombro permitido con pinzamiento y elevaciones laterales excluidas
   (al revés de lo razonable); crunch excluido con cualquier dolor lumbar.
7. Semana del mesociclo mal calculada tras el cambio de hora.
8. La rotación seguía un índice y se desincronizaba; ahora elige la sesión hecha hace más tiempo.
9. No se tenía en cuenta la recuperación al proponer la sesión del día.

### Cargas
10. Saltos de peso imposibles en máquinas con pila gruesa (p. ej. 45 → 52 kg). → Se predicen
    las reps con el peso siguiente; si no llegas, se mantiene y se amplía el rango.
11. Las semanas de descarga, calentamientos y drops alimentaban la progresión.
12. La descarga recortaba el peso dos veces.
13. Con top set + back-off, el peso base salía del back-off.
14. Sesiones claramente fáciles no subían si no tocabas el tope de reps.
15. El modelo opinaba con una sola sesión, no redondeaba a la máquina, no predecía reps y
    no tenía en cuenta la fatiga de series anteriores de la misma sesión.

### App
16. Pérdida de datos al guardar máquinas/ajustes antes de terminar de cargarlos.
17. Varias sesiones activas a la vez (series huérfanas contando en récords y volumen).
18. Al reanudar se perdían series extra, back-offs y sustituciones de ejercicio.
19. Copia de seguridad incompleta y restauración que no recargaba la app.
20. "Borrar todo" no borraba fotos ni todos los ajustes.
21. IDs de rutina repetidos al regenerar el programa.
22. Onboarding que no avanzaba, comparación de fotos que fallaba, métricas con coma decimal,
    cargas infinitas en historial y detalle.
23. Inicio: récords comparados solo con 35 días y semana móvil distinta a la de los puntos.
24. Opción de libras que no hacía nada (eliminada).

## Límites conocidos
- Los objetivos de volumen son de población (Pelland 2026, Schoenfeld 2017); tu respuesta
  individual solo la aprende el modelo con el tiempo.
- La asignación de series a músculos secundarios (0,5) es una convención, no una medida.
- Con 2 días de 35 minutos no cabe todo: se priorizan los músculos grandes.
