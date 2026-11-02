CREATE OR REPLACE VIEW vw_servicios_disponibles AS
SELECT 
    cs.idCentro,
    cs.nombre AS centro_salud,
    ts.idTipoServicio,
    ts.nombre AS servicio,
    ts.descripcion
FROM CentroDeSalud cs
JOIN Servicio s ON cs.idCentro = s.idCentro
JOIN TipoServicio ts ON s.idTipoServicio = ts.idTipoServicio;

CREATE OR REPLACE VIEW vw_historial_visitas AS
SELECT 
    p.idPaciente,
    p.dni,
    p.apellidos || ', ' || p.nombres AS paciente_completo,
    v.fechaVisita,
    prof.apellido || ', ' || prof.nombre AS medico,
    ts.nombre AS servicio,
    v.diagnostico,
    v.tratamiento
FROM Paciente p
JOIN Visita v ON p.idPaciente = v.idPaciente
JOIN Profesional prof ON v.idMedico = prof.idProfesional
JOIN Servicio s ON v.idServicio = s.idServicio
JOIN TipoServicio ts ON s.idTipoServicio = ts.idTipoServicio;

CREATE OR REPLACE VIEW vw_pacientes_internados AS
SELECT 
    i.idInternacion,
    p.dni,
    p.apellidos || ', ' || p.nombres AS paciente_completo,
    i.fechaIngreso,
    cs.nombre AS centro_salud
FROM Internacion i
JOIN Visita v ON i.idVisita = v.idVisita
JOIN Paciente p ON v.idPaciente = p.idPaciente
JOIN Servicio s ON v.idServicio = s.idServicio
JOIN CentroDeSalud cs ON s.idCentro = cs.idCentro
WHERE i.fechaEgreso IS NULL;
