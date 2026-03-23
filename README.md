# Motor Financiero Determinístico para Sistemas de Salud

> **Mismo input → mismo output. Siempre.**

Sistema de cálculo financiero auditable y reproducible para sistemas de información en salud, implementado en SQL Server.

## 🎯 Problema que resuelve

Imagina esta situación: Una auditoría llega 4 años después y pregunta:

> "¿Por qué esta cirugía costó exactamente ₡157,500 en 2022?"

Las tarifas han cambiado múltiples veces desde entonces. **¿Cómo demuestras que el cálculo original fue correcto?**

## ✅ Solución: Motor Determinístico

Este repositorio contiene una implementación de referencia de un **motor financiero determinístico** con tres pilares fundamentales:

### 1️⃣ Versionamiento
- **Nunca** se modifican tarifas existentes
- Siempre se crea una nueva versión
- Versiones anteriores quedan congeladas permanentemente

### 2️⃣ Frozen Amounts (Montos Congelados)
- Se guarda no solo el resultado, sino **todo el contexto** del cálculo
- ¿Qué tarifa? ¿Qué versión? ¿Qué fecha? ¿Cuántas horas?
- Fotografía completa e inalterable del cálculo

### 3️⃣ Funciones Puras
- Cálculo implementado como función SQL
- Sin variables externas ni efectos secundarios
- Mismos parámetros → mismo resultado. Siempre.

## 🚀 Demo en acción

Este código fue presentado en vivo en el podcast ["Un Show para TI"](https://www.youtube.com/live/xajAFAHb75E) (episodio 7, marzo 2026).

**Resultado de la demo:**
```sql
CasoNumero      FechaCirugia  Original    Recalculado  Verificación
CIR-2022-001    2022-06-15    157500.00   157500.00    MATCH PERFECTO ✓
CIR-2023-002    2023-03-20     82000.00    82000.00    MATCH PERFECTO ✓
CIR-2024-003    2024-02-10    108000.00   108000.00    MATCH PERFECTO ✓
CIR-2026-004    2026-03-15    138000.00   138000.00    MATCH PERFECTO ✓
```

Casos desde hace 4 años hasta hoy → **Reproducibilidad perfecta. Céntimo por céntimo.**

## 📂 Contenido del repositorio

- `motor_financiero_demo.sql` - Script completo con base de datos de ejemplo
- `ejemplos_casos.sql` - Casos de prueba adicionales
- Documentación completa en este README

## 🛠️ Requisitos

- SQL Server 2016 o superior
- SQL Server Management Studio (SSMS) recomendado

## ⚡ Inicio rápido

1. Abre SQL Server Management Studio
2. Ejecuta `motor_financiero_demo.sql`
3. Ejecuta las queries de verificación
4. ¡Observa el MATCH PERFECTO!

## 🏗️ Arquitectura

### Base de datos: `DemoPodcast`

**Tablas principales:**

- `TarifaRol` - Tarifas versionadas por rol y fecha
- `CasoQuirurgico` - Casos con montos congelados

**Función clave:**
```sql
dbo.CalcularCostoQuirurgico(
    @RolParticipante VARCHAR(100),
    @FechaCirugia DATE,
    @HorasDuracion DECIMAL(6,2)
) RETURNS DECIMAL(18,2)
```

Esta función busca la tarifa vigente en la fecha específica y calcula el costo de forma determinística.

## 🌍 Aplicabilidad universal

Aunque este ejemplo habla de sistemas quirúrgicos, **los patrones son universales** para cualquier sistema que maneje dinero a lo largo del tiempo:

✅ **Bancos** - Cálculo de intereses retroactivo  
✅ **Seguros** - Primas y liquidaciones históricas  
✅ **Nóminas** - Salarios con versiones de convenio  
✅ **Facturación** - Precios con descuentos versionados  

Si alguna vez has tenido que responder: *"¿Por qué cobramos esto hace X años?"* → estos patrones son para ti.

## 📚 Más información

Este repositorio contiene código simplificado para fines educativos y demostrativos.

Para la explicación completa con casos de uso reales, arquitectura detallada, y lecciones aprendidas desde la trinchera en sistemas de salud pública:

**📖 [Arquitectura y diseño de sistemas integrales de gestión quirúrgica](https://www.amazon.com/-/es/Hubert-García-Gordon-ebook/dp/B0GR8HBMXK/)**  
*Por Hubert García Gordon*  
ISBN: 978-9930-00-756-3

## 👤 Autor

**Hubert García Gordon**
- 10+ años en sistemas de información en salud (CCSS, Costa Rica)
- Tutor UNED - Sistemas de Información en Salud
- LinkedIn: [hubert-garcia-24946925](https://www.linkedin.com/in/hubert-garcia-24946925/)

## 📄 Licencia

Este proyecto está bajo licencia MIT. Ver archivo `LICENSE` para más detalles.

## 🤝 Contribuciones

¿Encontraste un bug? ¿Tienes una mejora? Los pull requests son bienvenidos.

Para cambios mayores, por favor abre un issue primero para discutir qué te gustaría cambiar.

---

⭐ Si este código te fue útil, considera darle una estrella al repo y compartir el conocimiento.
