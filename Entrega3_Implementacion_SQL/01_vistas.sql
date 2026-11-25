CREATE OR REPLACE VIEW vw_servicios_disponibles AS
SELECT
    cs.idCentro,
    cs.nombre AS centro_salud,
    s.idServicio,
    ts.idTipoServicio,
    ts.nombre AS servicio,
    ts.descripcion,
    b.idBarrio,
    b.nombre AS barrio,
    c.idCiudad,
    c.nombre AS ciudad
FROM CentroDeSalud cs, Servicio s, TipoServicio ts, Barrio b, Ciudad c
WHERE cs.idCentro = s.idCentro
  AND s.idTipoServicio = ts.idTipoServicio
  AND cs.idBarrio = b.idBarrio
  AND b.idCiudad = c.idCiudad;

CREATE OR REPLACE VIEW vw_historial_visitas AS
SELECT
    p.idPaciente,
    p.dni,
    p.apellido || ', ' || p.nombre AS paciente_completo,
    v.fechaVisita,
    prof.apellido || ', ' || prof.nombre AS medico,
    ts.nombre AS servicio,
    v.diagnostico,
    v.tratamiento,
    v.idVisita,
    prof.idProfesional,
    cs.idCentro,
    cs.nombre AS centro_salud,
    b.idBarrio,
    b.nombre AS barrio,
    c.idCiudad,
    c.nombre AS ciudad
FROM Paciente p, Visita v, Profesional prof, Servicio s,
     TipoServicio ts, CentroDeSalud cs, Barrio b, Ciudad c
WHERE p.idPaciente = v.idPaciente
  AND v.idProfesional = prof.idProfesional
  AND v.idServicio = s.idServicio
  AND s.idTipoServicio = ts.idTipoServicio
  AND s.idCentro = cs.idCentro
  AND cs.idBarrio = b.idBarrio
  AND b.idCiudad = c.idCiudad;

CREATE OR REPLACE VIEW vw_pacientes_internados AS
SELECT
    i.idInternacion,
    p.idPaciente,
    p.dni,
    p.apellido || ', ' || p.nombre AS paciente_completo,
    i.fechaIngreso,
    cs.nombre AS centro_salud,
    (SELECT COUNT(*)
     FROM Visita v2
     WHERE v2.idPaciente = p.idPaciente
       AND v2.fechaVisita >= CURRENT_DATE - INTERVAL '6 months') AS atenciones_6_meses
FROM Internacion i, Visita v, Paciente p, Servicio s, CentroDeSalud cs
WHERE i.idVisita = v.idVisita
  AND v.idPaciente = p.idPaciente
  AND v.idServicio = s.idServicio
  AND s.idCentro = cs.idCentro
  AND i.fechaEgreso IS NULL;
