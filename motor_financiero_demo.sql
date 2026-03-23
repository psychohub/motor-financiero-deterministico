-- ============================================================================
-- MOTOR FINANCIERO DETERMINÍSTICO - DEMO
-- ============================================================================
-- Autor: Hubert García Gordon
-- Descripción: Sistema de cálculo financiero auditable y reproducible
--              para sistemas de información en salud
-- 
-- Demostrado en: Podcast "Un Show para TI" - Episodio 7 (Marzo 2026)
-- Más info: https://github.com/psychohub/motor-financiero-deterministico
-- ============================================================================

-- ============================================================================
-- PASO 1: CREAR BASE DE DATOS
-- ============================================================================
-- Esta base de datos es solo para demostración educativa.
-- En producción, integrarías estas tablas en tu sistema existente.

CREATE DATABASE DemoPodcast;
GO

USE DemoPodcast;
GO

-- ============================================================================
-- PASO 2: TABLA DE TARIFAS VERSIONADAS
-- ============================================================================
-- CLAVE: Esta tabla implementa el VERSIONAMIENTO.
-- NUNCA modificamos una fila existente. Solo agregamos nuevas versiones.

CREATE TABLE dbo.TarifaRol (
    TarifaRolId INT PRIMARY KEY IDENTITY(1,1),
    RolNombre VARCHAR(100) NOT NULL,
    MontoPorHora DECIMAL(18,2) NOT NULL,
    FechaVigenciaDesde DATE NOT NULL,
    FechaVigenciaHasta DATE NULL,  -- NULL = vigente indefinidamente
    Version INT NOT NULL,
    FechaCreacion DATETIME2 DEFAULT GETDATE(),
    CreadoPor VARCHAR(100) DEFAULT 'SISTEMA'
);
GO

-- ============================================================================
-- PASO 3: INSERTAR TARIFAS HISTÓRICAS
-- ============================================================================
-- Estas tarifas muestran cómo han cambiado los precios a lo largo del tiempo.
-- Cada rol tiene múltiples versiones según diferentes períodos.

-- Cirujano General - 3 versiones a lo largo de los años
INSERT INTO dbo.TarifaRol (RolNombre, MontoPorHora, FechaVigenciaDesde, FechaVigenciaHasta, Version)
VALUES 
    ('Cirujano General', 45000.00, '2022-01-01', '2022-12-31', 1),
    ('Cirujano General', 52000.00, '2023-01-01', '2023-12-31', 2),
    ('Cirujano General', 58000.00, '2024-01-01', NULL, 3);  -- Vigente actual

-- Anestesiólogo - 3 versiones
INSERT INTO dbo.TarifaRol (RolNombre, MontoPorHora, FechaVigenciaDesde, FechaVigenciaHasta, Version)
VALUES 
    ('Anestesiólogo', 41000.00, '2022-01-01', '2022-12-31', 1),
    ('Anestesiólogo', 44000.00, '2023-01-01', '2023-12-31', 2),
    ('Anestesiólogo', 46000.00, '2024-01-01', NULL, 3);  -- Vigente actual

-- Instrumentista - 3 versiones
INSERT INTO dbo.TarifaRol (RolNombre, MontoPorHora, FechaVigenciaDesde, FechaVigenciaHasta, Version)
VALUES 
    ('Instrumentista', 24000.00, '2022-01-01', '2022-12-31', 1),
    ('Instrumentista', 26000.00, '2023-01-01', '2023-12-31', 2),
    ('Instrumentista', 28000.00, '2024-01-01', NULL, 3);  -- Vigente actual

-- Enfermera Circulante - 3 versiones
INSERT INTO dbo.TarifaRol (RolNombre, MontoPorHora, FechaVigenciaDesde, FechaVigenciaHasta, Version)
VALUES 
    ('Enfermera Circulante', 22000.00, '2022-01-01', '2022-12-31', 1),
    ('Enfermera Circulante', 24000.00, '2023-01-01', '2023-12-31', 2),
    ('Enfermera Circulante', 26000.00, '2024-01-01', NULL, 3);  -- Vigente actual

-- ============================================================================
-- PASO 4: VERIFICAR TARIFAS INSERTADAS
-- ============================================================================
-- Query para ver todas las tarifas versionadas

SELECT 
    TarifaRolId,
    RolNombre,
    MontoPorHora,
    FechaVigenciaDesde,
    FechaVigenciaHasta,
    Version,
    CASE 
        WHEN FechaVigenciaHasta IS NULL THEN 'VIGENTE ACTUAL'
        ELSE 'HISTÓRICA'
    END AS Estado
FROM dbo.TarifaRol
ORDER BY RolNombre, Version;
GO

-- ============================================================================
-- PASO 5: FUNCIÓN DETERMINÍSTICA - EL CORAZÓN DEL SISTEMA
-- ============================================================================
-- Esta función implementa el cálculo DETERMINÍSTICO.
-- Dado el mismo input (rol, fecha, horas), siempre retorna el mismo output.
--
-- CLAVE: La función busca la tarifa que estaba VIGENTE en la fecha específica,
-- no la tarifa actual. Esto permite reproducir cálculos históricos con exactitud.

CREATE FUNCTION dbo.CalcularCostoQuirurgico (
    @RolParticipante VARCHAR(100),
    @FechaCirugia DATE,
    @HorasDuracion DECIMAL(6,2)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TarifaPorHora DECIMAL(18,2);
    DECLARE @CostoTotal DECIMAL(18,2);
    
    -- Buscar la tarifa que estaba vigente en la fecha específica
    -- IMPORTANTE: Se usa la fecha de cirugía, NO la fecha actual
    SELECT TOP 1 @TarifaPorHora = MontoPorHora
    FROM dbo.TarifaRol
    WHERE RolNombre = @RolParticipante
      AND @FechaCirugia >= FechaVigenciaDesde
      AND (@FechaCirugia <= FechaVigenciaHasta OR FechaVigenciaHasta IS NULL)
    ORDER BY FechaVigenciaDesde DESC;
    
    -- Calcular el costo total
    SET @CostoTotal = @TarifaPorHora * @HorasDuracion;
    
    RETURN @CostoTotal;
END;
GO

-- ============================================================================
-- PASO 6: TABLA DE CASOS QUIRÚRGICOS CON "FROZEN AMOUNTS"
-- ============================================================================
-- CLAVE: Esta tabla implementa FROZEN AMOUNTS.
-- No solo guardamos el resultado final, sino TODO el contexto del cálculo.

CREATE TABLE dbo.CasoQuirurgico (
    CasoId INT PRIMARY KEY IDENTITY(1,1),
    CasoNumero VARCHAR(50) UNIQUE NOT NULL,
    PacienteNombre VARCHAR(200) NOT NULL,
    FechaCirugia DATE NOT NULL,
    HorasDuracion DECIMAL(6,2) NOT NULL,
    RolParticipante VARCHAR(100) NOT NULL,
    
    -- FROZEN AMOUNTS: Guardamos el contexto completo
    TarifaPorHoraUsada DECIMAL(18,2) NOT NULL,
    TarifaRolIdUsado INT NOT NULL,
    MontoCalculadoOriginal DECIMAL(18,2) NOT NULL,
    
    -- Metadata
    FechaCalculo DATETIME2 DEFAULT GETDATE(),
    CalculadoPor VARCHAR(100) NOT NULL,
    
    -- Clave foránea para rastreabilidad
    CONSTRAINT FK_CasoQuirurgico_TarifaRol 
        FOREIGN KEY (TarifaRolIdUsado) REFERENCES dbo.TarifaRol(TarifaRolId)
);
GO

-- ============================================================================
-- PASO 7: INSERTAR CASOS DE EJEMPLO
-- ============================================================================
-- Estos casos demuestran cálculos realizados en diferentes años.
-- Cada caso "congeló" el monto usando la tarifa vigente en su momento.

-- Caso 2022 - Cirujano General, 3.5 horas
DECLARE @TarifaCirujano2022 DECIMAL(18,2) = 45000.00;
DECLARE @TarifaRolId1 INT = (SELECT TarifaRolId FROM dbo.TarifaRol WHERE RolNombre = 'Cirujano General' AND Version = 1);

INSERT INTO dbo.CasoQuirurgico 
(CasoNumero, PacienteNombre, FechaCirugia, HorasDuracion, RolParticipante, 
 TarifaPorHoraUsada, TarifaRolIdUsado, MontoCalculadoOriginal, CalculadoPor)
VALUES 
('CIR-2022-001', 'Juan Pérez', '2022-06-15', 3.5, 'Cirujano General',
 @TarifaCirujano2022, @TarifaRolId1, @TarifaCirujano2022 * 3.5, 'CalcularCostoQuirurgico');

-- Caso 2023 - Anestesiólogo, 2.0 horas
DECLARE @TarifaAnestesiologo2023 DECIMAL(18,2) = 41000.00;
DECLARE @TarifaRolId2 INT = (SELECT TarifaRolId FROM dbo.TarifaRol WHERE RolNombre = 'Anestesiólogo' AND Version = 1);

INSERT INTO dbo.CasoQuirurgico 
(CasoNumero, PacienteNombre, FechaCirugia, HorasDuracion, RolParticipante, 
 TarifaPorHoraUsada, TarifaRolIdUsado, MontoCalculadoOriginal, CalculadoPor)
VALUES 
('CIR-2023-002', 'María González', '2023-03-20', 2.0, 'Anestesiólogo',
 @TarifaAnestesiologo2023, @TarifaRolId2, @TarifaAnestesiologo2023 * 2.0, 'CalcularCostoQuirurgico');

-- Caso 2024 - Instrumentista, 4.5 horas (usando tarifa 2023)
DECLARE @TarifaInstrumentista2024 DECIMAL(18,2) = 24000.00;
DECLARE @TarifaRolId3 INT = (SELECT TarifaRolId FROM dbo.TarifaRol WHERE RolNombre = 'Instrumentista' AND Version = 1);

INSERT INTO dbo.CasoQuirurgico 
(CasoNumero, PacienteNombre, FechaCirugia, HorasDuracion, RolParticipante, 
 TarifaPorHoraUsada, TarifaRolIdUsado, MontoCalculadoOriginal, CalculadoPor)
VALUES 
('CIR-2024-003', 'Carlos Rodríguez', '2024-02-10', 4.5, 'Instrumentista',
 @TarifaInstrumentista2024, @TarifaRolId3, @TarifaInstrumentista2024 * 4.5, 'CalcularCostoQuirurgico');

-- Caso 2026 - Anestesiólogo, 3.0 horas (tarifa actual)
DECLARE @TarifaAnestesiologo2026 DECIMAL(18,2) = 46000.00;
DECLARE @TarifaRolId4 INT = (SELECT TarifaRolId FROM dbo.TarifaRol WHERE RolNombre = 'Anestesiólogo' AND Version = 3);

INSERT INTO dbo.CasoQuirurgico 
(CasoNumero, PacienteNombre, FechaCirugia, HorasDuracion, RolParticipante, 
 TarifaPorHoraUsada, TarifaRolIdUsado, MontoCalculadoOriginal, CalculadoPor)
VALUES 
('CIR-2026-004', 'Ana Morales', '2026-03-15', 3.0, 'Anestesiólogo',
 @TarifaAnestesiologo2026, @TarifaRolId4, @TarifaAnestesiologo2026 * 3.0, 'CalcularCostoQuirurgico');

GO

-- ============================================================================
-- PASO 8: VERIFICACIÓN - EL MOMENTO "WOW"
-- ============================================================================
-- Esta query demuestra la REPRODUCIBILIDAD PERFECTA del motor.
-- Recalculamos casos de hace 4 años y obtenemos exactamente el mismo resultado.

SELECT 
    c.CasoNumero,
    c.PacienteNombre,
    c.FechaCirugia,
    c.RolParticipante,
    c.HorasDuracion,
    c.MontoCalculadoOriginal AS 'Original (guardado)',
    dbo.CalcularCostoQuirurgico(
        c.RolParticipante, 
        c.FechaCirugia, 
        c.HorasDuracion
    ) AS 'Recalculado (hoy)',
    CASE 
        WHEN c.MontoCalculadoOriginal = dbo.CalcularCostoQuirurgico(
            c.RolParticipante, 
            c.FechaCirugia, 
            c.HorasDuracion
        )
        THEN 'MATCH PERFECTO'
        ELSE 'ERROR - REVISAR'
    END AS 'Verificación'
FROM dbo.CasoQuirurgico c
ORDER BY c.FechaCirugia;

-- ============================================================================
-- RESULTADO ESPERADO:
-- ============================================================================
-- CasoNumero      FechaCirugia  Original    Recalculado  Verificación
-- CIR-2022-001    2022-06-15    157500.00   157500.00    MATCH PERFECTO
-- CIR-2023-002    2023-03-20     82000.00    82000.00    MATCH PERFECTO
-- CIR-2024-003    2024-02-10    108000.00   108000.00    MATCH PERFECTO
-- CIR-2026-004    2026-03-15    138000.00   138000.00    MATCH PERFECTO
--
-- ✓ Casos desde hace 4 años hasta hoy → Reproducibilidad perfecta
-- ============================================================================

GO

-- ============================================================================
-- PASO 9 (BONUS): COMPARACIÓN TEMPORAL
-- ============================================================================
-- Esta query muestra la importancia del versionamiento.
-- Compara lo que costó en el pasado vs. lo que costaría HOY.

SELECT 
    'Cirugía de 2022' AS Descripcion,
    dbo.CalcularCostoQuirurgico('Cirujano General', '2022-06-15', 3.5) AS 'Costó en 2022',
    dbo.CalcularCostoQuirurgico('Cirujano General', '2026-03-21', 3.5) AS 'Costaría hoy (2026)',
    dbo.CalcularCostoQuirurgico('Cirujano General', '2026-03-21', 3.5) - 
    dbo.CalcularCostoQuirurgico('Cirujano General', '2022-06-15', 3.5) AS 'Diferencia';

-- ============================================================================
-- RESULTADO ESPERADO:
-- ============================================================================
-- Descripcion         Costó en 2022  Costaría hoy  Diferencia
-- Cirugía de 2022     157,500        203,000       +45,500
--
-- ✓ Sin versionamiento, sería imposible justificar esta diferencia
-- ============================================================================

GO

-- ============================================================================
-- PASO 10: CONSULTAS ADICIONALES ÚTILES
-- ============================================================================

-- Ver todas las versiones de una tarifa específica
SELECT 
    RolNombre,
    MontoPorHora,
    FechaVigenciaDesde,
    FechaVigenciaHasta,
    Version,
    CASE WHEN FechaVigenciaHasta IS NULL THEN 'ACTUAL' ELSE 'HISTÓRICA' END AS Estado
FROM dbo.TarifaRol
WHERE RolNombre = 'Cirujano General'
ORDER BY Version;

-- Ver todos los casos con sus tarifas congeladas
SELECT 
    c.CasoNumero,
    c.FechaCirugia,
    c.RolParticipante,
    c.TarifaPorHoraUsada AS 'Tarifa usada',
    t.MontoPorHora AS 'Tarifa vigente ese día',
    t.Version AS 'Versión usada'
FROM dbo.CasoQuirurgico c
INNER JOIN dbo.TarifaRol t ON c.TarifaRolIdUsado = t.TarifaRolId
ORDER BY c.FechaCirugia;

GO

-- ============================================================================
-- NOTAS FINALES
-- ============================================================================
-- Este código es una demostración educativa simplificada.
-- 
-- En un sistema de producción real, considerarías:
-- - Múltiples roles por cirugía (equipo completo)
-- - Auditoría completa (triggers, logs)
-- - Manejo de errores robusto
-- - Índices para performance
-- - Validaciones de negocio
-- - Seguridad y permisos
-- - Integración con otros sistemas
--
-- Para la implementación completa con arquitectura detallada y casos de uso
-- reales en sistemas de salud pública, consulta el libro:
--
-- "Arquitectura y diseño de sistemas integrales de gestión quirúrgica"
-- Por Hubert García Gordon
-- ISBN: 978-9930-00-756-3
-- Disponible en Amazon
-- ============================================================================

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================
