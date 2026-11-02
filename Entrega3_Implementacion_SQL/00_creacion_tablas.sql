CREATE TYPE TipoProfesional AS ENUM ('Medico', 'Enfermero');
CREATE TYPE DiaSemana AS ENUM ('Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo');

CREATE TABLE Departamento (
    idDepartamento INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    PRIMARY KEY (idDepartamento)
);

CREATE TABLE Ciudad (
    idCiudad INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    idDepartamento INT NOT NULL,
    PRIMARY KEY (idCiudad),
    FOREIGN KEY (idDepartamento) REFERENCES Departamento(idDepartamento)
);

CREATE TABLE Barrio (
    idBarrio INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    idCiudad INT NOT NULL,
    PRIMARY KEY (idBarrio),
    FOREIGN KEY (idCiudad) REFERENCES Ciudad(idCiudad)
);

CREATE TABLE CentroDeSalud (
    idCentro INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    calleDireccion VARCHAR(50),
    numDireccion INT,
    fechaInauguracion DATE,
    idBarrio INT NOT NULL,
    PRIMARY KEY (idCentro),
    FOREIGN KEY (idBarrio) REFERENCES Barrio(idBarrio)
);

CREATE TABLE ObraSocial (
    idObraSocial INT NOT NULL,
    nombre VARCHAR(30) NOT NULL,
    PRIMARY KEY (idObraSocial)
);

CREATE TABLE Paciente (
    idPaciente INT NOT NULL,
    dni VARCHAR(8) NOT NULL,
    nombres VARCHAR(30) NOT NULL,
    apellidos VARCHAR(30) NOT NULL,
    calleDomicilio VARCHAR(50),
    numDomicilio INT,
    fechaNacimiento DATE,
    numeroAsociado VARCHAR(20) NULL,
    idObraSocial INT NULL,
    idBarrio INT NOT NULL,
    PRIMARY KEY (idPaciente),
    CONSTRAINT uk_paciente_dni UNIQUE (dni),
    FOREIGN KEY (idObraSocial) REFERENCES ObraSocial(idObraSocial),
    FOREIGN KEY (idBarrio) REFERENCES Barrio(idBarrio)
);

CREATE TABLE Especializacion (
    idEspecializacion INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    PRIMARY KEY (idEspecializacion)
);

CREATE TABLE Profesional (
    idProfesional INT NOT NULL,
    tipoProfesional TipoProfesional NOT NULL,
    nombre VARCHAR(30) NOT NULL,
    apellido VARCHAR(30) NOT NULL,
    matricula VARCHAR(30) NOT NULL,
    fechaNacimiento DATE,
    telefono VARCHAR(20),
    email VARCHAR(100),
    PRIMARY KEY (idProfesional),
    CONSTRAINT uk_profesional_matricula UNIQUE (matricula)
);

CREATE TABLE ProfesionalEspecializacion (
    idProfesional INT NOT NULL,
    idEspecializacion INT NOT NULL,
    PRIMARY KEY (idProfesional, idEspecializacion),
    FOREIGN KEY (idProfesional) REFERENCES Profesional(idProfesional),
    FOREIGN KEY (idEspecializacion) REFERENCES Especializacion(idEspecializacion)
);

CREATE TABLE TipoServicio (
    idTipoServicio INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    descripcion VARCHAR(100),
    idEspecializacionACargo INT NULL,
    PRIMARY KEY (idTipoServicio),
    FOREIGN KEY (idEspecializacionACargo) REFERENCES Especializacion(idEspecializacion)
);

CREATE TABLE RequisitoServicio (
    idRequisito INT NOT NULL,
    cantidad INT NOT NULL,
    tipoProfesional TipoProfesional NOT NULL,
    idTipoServicio INT NOT NULL,
    idEspecializacion INT NULL,
    PRIMARY KEY (idRequisito),
    FOREIGN KEY (idTipoServicio) REFERENCES TipoServicio(idTipoServicio),
    FOREIGN KEY (idEspecializacion) REFERENCES Especializacion(idEspecializacion)
);

CREATE TABLE Servicio (
    idServicio INT NOT NULL,
    idMedicoACargo INT NOT NULL,
    idCentro INT NOT NULL,
    idTipoServicio INT NOT NULL,
    PRIMARY KEY (idServicio),
    CONSTRAINT uk_centro_tiposervicio UNIQUE (idCentro, idTipoServicio),
    FOREIGN KEY (idMedicoACargo) REFERENCES Profesional(idProfesional),
    FOREIGN KEY (idCentro) REFERENCES CentroDeSalud(idCentro),
    FOREIGN KEY (idTipoServicio) REFERENCES TipoServicio(idTipoServicio)
);

CREATE TABLE AsignacionServicio (
    idAsignacion INT NOT NULL,
    idProfesional INT NOT NULL,
    idServicio INT NOT NULL,
    PRIMARY KEY (idAsignacion),
    CONSTRAINT uk_servicio_profesional UNIQUE (idServicio, idProfesional),
    FOREIGN KEY (idProfesional) REFERENCES Profesional(idProfesional),
    FOREIGN KEY (idServicio) REFERENCES Servicio(idServicio)
);

CREATE TABLE HorarioAtencion (
    idHorario INT NOT NULL,
    diaSemana DiaSemana NOT NULL,
    horaApertura TIME NOT NULL,
    horaCierre TIME NOT NULL,
    idCentro INT NULL,
    idServicio INT NULL,
    PRIMARY KEY (idHorario),
    FOREIGN KEY (idCentro) REFERENCES CentroDeSalud(idCentro),
    FOREIGN KEY (idServicio) REFERENCES Servicio(idServicio)
);

CREATE TABLE Visita (
    idVisita INT NOT NULL,
    fechaVisita DATE NOT NULL,
    diagnostico VARCHAR(500),
    tratamiento VARCHAR(500),
    idMedico INT NOT NULL,
    idPaciente INT NOT NULL,
    idServicio INT NOT NULL,
    PRIMARY KEY (idVisita),
    FOREIGN KEY (idMedico) REFERENCES Profesional(idProfesional),
    FOREIGN KEY (idPaciente) REFERENCES Paciente(idPaciente),
    FOREIGN KEY (idServicio) REFERENCES Servicio(idServicio)
);

CREATE TABLE Internacion (
    idInternacion INT NOT NULL,
    fechaIngreso DATE NOT NULL,
    fechaEgreso DATE NULL,
    idVisita INT NOT NULL,
    PRIMARY KEY (idInternacion),
    CONSTRAINT uk_internacion_visita UNIQUE (idVisita),
    FOREIGN KEY (idVisita) REFERENCES Visita(idVisita)
);
