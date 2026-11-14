-- ============================================================
-- trg_servicio_medico_a_cargo
-- Tabla: Servicio | BEFORE INSERT OR UPDATE
-- El profesional a cargo debe ser Medico y, si el tipo de servicio
-- exige una especializacion a cargo, debe tenerla.
-- ============================================================
DROP TRIGGER IF EXISTS trg_servicio_medico_a_cargo ON Servicio;

CREATE OR REPLACE FUNCTION func_servicio_medico_a_cargo() RETURNS TRIGGER AS
$$
DECLARE
    tipo TipoProfesional;
    espRequerida INT;
BEGIN
    SELECT tipoProfesional INTO tipo
    FROM Profesional
    WHERE idProfesional = NEW.idProfesional;

    IF tipo IS NULL OR tipo <> 'Medico' THEN
        RAISE EXCEPTION 'El profesional % no puede estar a cargo del servicio: debe ser Medico', NEW.idProfesional;
    END IF;

    SELECT idEspecializacionACargo INTO espRequerida
    FROM TipoServicio
    WHERE idTipoServicio = NEW.idTipoServicio;

    IF espRequerida IS NOT NULL AND NOT EXISTS (
        SELECT 1
        FROM ProfesionalEspecializacion
        WHERE idProfesional = NEW.idProfesional
          AND idEspecializacion = espRequerida
    ) THEN
        RAISE EXCEPTION 'El medico % no tiene la especializacion % que exige este tipo de servicio', NEW.idProfesional, espRequerida;
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER trg_servicio_medico_a_cargo
BEFORE INSERT OR UPDATE ON Servicio
FOR EACH ROW EXECUTE PROCEDURE func_servicio_medico_a_cargo();

-- ============================================================
-- trg_asignacion_especializacion
-- Tabla: AsignacionServicio | BEFORE INSERT OR UPDATE
-- El profesional asignado como asistente no puede ser el medico a cargo
-- del mismo servicio y debe cumplir algun requisito del tipo de servicio
-- para su tipo de profesional (medico o enfermero): si el requisito exige
-- especializacion, debe tenerla.
-- ============================================================
DROP TRIGGER IF EXISTS trg_asignacion_especializacion ON AsignacionServicio;
CREATE OR REPLACE FUNCTION func_asignacion_especializacion() RETURNS TRIGGER AS
$$
DECLARE
    tipoServicio INT;
    aCargo INT;
    tipo TipoProfesional;
BEGIN
    SELECT idTipoServicio, idProfesional INTO tipoServicio, aCargo
    FROM Servicio
    WHERE idServicio = NEW.idServicio;

    IF NEW.idProfesional = aCargo THEN
        RAISE EXCEPTION 'El profesional % ya es el medico a cargo del servicio %: no puede ser asistente', NEW.idProfesional, NEW.idServicio;
    END IF;

    SELECT tipoProfesional INTO tipo
    FROM Profesional
    WHERE idProfesional = NEW.idProfesional;

    IF NOT EXISTS (
        SELECT 1
        FROM RequisitoServicio r
        WHERE r.idTipoServicio = tipoServicio
          AND r.tipoProfesional = tipo
          AND (r.idEspecializacion IS NULL
               OR EXISTS (SELECT 1
                          FROM ProfesionalEspecializacion pe
                          WHERE pe.idProfesional = NEW.idProfesional
                            AND pe.idEspecializacion = r.idEspecializacion))
    ) THEN
        RAISE EXCEPTION 'El profesional % no cumple ningun requisito del servicio %', NEW.idProfesional, NEW.idServicio;
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER trg_asignacion_especializacion
BEFORE INSERT OR UPDATE ON AsignacionServicio
FOR EACH ROW EXECUTE PROCEDURE func_asignacion_especializacion();
-- ============================================================
-- trg_visita_valida
-- Tabla: Visita | BEFORE INSERT OR UPDATE
-- La fecha de la visita no puede ser futura, el profesional que atiende
-- debe ser Medico y debe estar asignado al servicio o ser el medico a
-- cargo del mismo.
-- ============================================================
DROP TRIGGER IF EXISTS trg_visita_valida ON Visita;
CREATE OR REPLACE FUNCTION func_visita_valida() RETURNS TRIGGER AS
$$
DECLARE
    tipo TipoProfesional;
BEGIN
    IF NEW.fechaVisita > CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de la visita (%) no puede ser futura', NEW.fechaVisita;
    END IF;

    SELECT tipoProfesional INTO tipo
    FROM Profesional
    WHERE idProfesional = NEW.idProfesional;

    IF tipo IS NULL OR tipo <> 'Medico' THEN
        RAISE EXCEPTION 'El profesional % no puede atender la visita: debe ser Medico', NEW.idProfesional;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Servicio
                   WHERE idServicio = NEW.idServicio
                     AND idProfesional = NEW.idProfesional)
       AND NOT EXISTS (SELECT 1 FROM AsignacionServicio
                       WHERE idServicio = NEW.idServicio
                         AND idProfesional = NEW.idProfesional) THEN
        RAISE EXCEPTION 'El profesional % no esta a cargo ni asignado al servicio %', NEW.idProfesional, NEW.idServicio;
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER trg_visita_valida
BEFORE INSERT OR UPDATE ON Visita
FOR EACH ROW EXECUTE PROCEDURE func_visita_valida();
-- ============================================================
-- trg_internacion_valida
-- Tabla: Internacion | BEFORE INSERT OR UPDATE
-- La fecha de egreso (si existe) no puede ser anterior a la de ingreso y
-- el paciente de la visita no puede tener otra internacion abierta.
-- ============================================================
DROP TRIGGER IF EXISTS trg_internacion_valida ON Internacion;
CREATE OR REPLACE FUNCTION func_internacion_valida() RETURNS TRIGGER AS
$$
DECLARE
    paciente INT;
BEGIN
    IF NEW.fechaEgreso IS NOT NULL AND NEW.fechaEgreso < NEW.fechaIngreso THEN
        RAISE EXCEPTION 'La fecha de egreso (%) no puede ser anterior a la de ingreso (%)', NEW.fechaEgreso, NEW.fechaIngreso;
    END IF;

    SELECT idPaciente INTO paciente
    FROM Visita
    WHERE idVisita = NEW.idVisita;

    IF NEW.fechaEgreso IS NULL AND EXISTS (
        SELECT 1
        FROM Internacion
        WHERE fechaEgreso IS NULL
          AND idInternacion <> NEW.idInternacion
          AND idVisita IN (SELECT idVisita
                           FROM Visita
                           WHERE idPaciente = paciente)
    ) THEN
        RAISE EXCEPTION 'El paciente % ya tiene una internacion abierta', paciente;
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER trg_internacion_valida
BEFORE INSERT OR UPDATE ON Internacion
FOR EACH ROW EXECUTE PROCEDURE func_internacion_valida();

-- ============================================================
-- trg_horario_servicio
-- Tabla: HorarioAtencion | BEFORE INSERT OR UPDATE OR DELETE
-- 1) el horario de un servicio debe quedar dentro de algun horario de su
--    centro el mismo dia de la semana,
-- 2) al modificar o borrar el horario de un centro, ningun servicio del
--    centro puede quedar fuera del horario ese dia.
-- En un INSERT no existe OLD y en un DELETE no existe NEW (sus valores
-- son NULL), por eso se pregunta si cada uno tiene datos antes de usarlo.
-- ============================================================
DROP TRIGGER IF EXISTS trg_horario_servicio ON HorarioAtencion;
CREATE OR REPLACE FUNCTION func_horario_servicio() RETURNS TRIGGER AS
$$
DECLARE
    centro INT;
BEGIN
    IF NEW.idServicio IS NOT NULL THEN
        SELECT idCentro INTO centro
        FROM Servicio
        WHERE idServicio = NEW.idServicio;

        IF NOT EXISTS (SELECT 1 FROM HorarioAtencion
                       WHERE idCentro = centro
                         AND diaSemana = NEW.diaSemana) THEN
            RAISE EXCEPTION 'El centro % no atiende el dia %: no se puede cargar horario al servicio %', centro, NEW.diaSemana, NEW.idServicio;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM HorarioAtencion
                       WHERE idCentro = centro
                         AND diaSemana = NEW.diaSemana
                         AND horaApertura <= NEW.horaApertura
                         AND NEW.horaCierre <= horaCierre) THEN
            RAISE EXCEPTION 'El horario del servicio % queda fuera del horario del centro % el dia %', NEW.idServicio, centro, NEW.diaSemana;
        END IF;
    END IF;

    IF OLD.idCentro IS NOT NULL THEN
        IF EXISTS (
            SELECT 1
            FROM HorarioAtencion hs
            WHERE hs.diaSemana = OLD.diaSemana
              AND hs.idServicio IN (SELECT idServicio
                                    FROM Servicio
                                    WHERE idCentro = OLD.idCentro)
              AND NOT EXISTS (
                    SELECT 1
                    FROM HorarioAtencion hc
                    WHERE hc.idCentro = OLD.idCentro
                      AND hc.diaSemana = OLD.diaSemana
                      AND hc.idHorario <> OLD.idHorario
                      AND hc.horaApertura <= hs.horaApertura
                      AND hs.horaCierre <= hc.horaCierre)
              AND NOT COALESCE(NEW.idCentro = OLD.idCentro
                               AND NEW.diaSemana = OLD.diaSemana
                               AND NEW.horaApertura <= hs.horaApertura
                               AND hs.horaCierre <= NEW.horaCierre, FALSE)
        ) THEN
            RAISE EXCEPTION 'No se puede modificar ni borrar el horario %: algun servicio del centro % quedaria fuera del horario el dia %', OLD.idHorario, OLD.idCentro, OLD.diaSemana;
        END IF;
    END IF;

    IF NEW IS NULL THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER trg_horario_servicio
BEFORE INSERT OR UPDATE OR DELETE ON HorarioAtencion
FOR EACH ROW EXECUTE PROCEDURE func_horario_servicio();










