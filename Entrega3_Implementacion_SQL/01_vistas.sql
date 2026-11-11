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
FROM CentroDeSalud cs
JOIN Servicio s ON cs.idCentro = s.idCentro
JOIN TipoServicio ts ON s.idTipoServicio = ts.idTipoServicio
JOIN Barrio b ON cs.idBarrio = b.idBarrio
JOIN Ciudad c ON b.idCiudad = c.idCiudad;

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
FROM Paciente p
JOIN Visita v ON p.idPaciente = v.idPaciente
JOIN Profesional prof ON v.idProfesional = prof.idProfesional
JOIN Servicio s ON v.idServicio = s.idServicio
JOIN TipoServicio ts ON s.idTipoServicio = ts.idTipoServicio
JOIN CentroDeSalud cs ON s.idCentro = cs.idCentro
JOIN Barrio b ON cs.idBarrio = b.idBarrio
JOIN Ciudad c ON b.idCiudad = c.idCiudad;

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
FROM Internacion i
JOIN Visita v ON i.idVisita = v.idVisita
JOIN Paciente p ON v.idPaciente = p.idPaciente
JOIN Servicio s ON v.idServicio = s.idServicio
JOIN CentroDeSalud cs ON s.idCentro = cs.idCentro
WHERE i.fechaEgreso IS NULL;
