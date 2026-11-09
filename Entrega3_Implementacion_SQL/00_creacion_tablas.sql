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
    calleDireccion VARCHAR(50) NOT NULL,
    numDireccion INT NOT NULL CHECK (numDireccion > 0),
    fechaInauguracion DATE NOT NULL CHECK (fechaInauguracion <= CURRENT_DATE),
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
    dni VARCHAR(8) NOT NULL CHECK (dni ~ '^[0-9]{7,8}$'),
    nombre VARCHAR(30) NOT NULL,
    apellido VARCHAR(30) NOT NULL,
    calleDomicilio VARCHAR(50) NOT NULL,
    numDomicilio INT NOT NULL CHECK (numDomicilio > 0),
    fechaNacimiento DATE NOT NULL CHECK (fechaNacimiento <= CURRENT_DATE),
    numeroAsociado VARCHAR(20) NULL CHECK (numeroAsociado ~ '^[0-9]+$'),
    idObraSocial INT NULL,
    idBarrio INT NOT NULL,
    PRIMARY KEY (idPaciente),
    UNIQUE (dni),
    CHECK ((idObraSocial IS NULL) = (numeroAsociado IS NULL)),
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
    fechaNacimiento DATE NOT NULL CHECK (fechaNacimiento <= CURRENT_DATE),
    telefono VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    PRIMARY KEY (idProfesional),
    UNIQUE (matricula)
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
    descripcion VARCHAR(100) NOT NULL,
    idEspecializacionACargo INT NULL,
    PRIMARY KEY (idTipoServicio),
    FOREIGN KEY (idEspecializacionACargo) REFERENCES Especializacion(idEspecializacion)
);

CREATE TABLE RequisitoServicio (
    idRequisito INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    tipoProfesional TipoProfesional NOT NULL,
    idTipoServicio INT NOT NULL,
    idEspecializacion INT NULL,
    PRIMARY KEY (idRequisito),
    UNIQUE (idTipoServicio, tipoProfesional, idEspecializacion),
    FOREIGN KEY (idTipoServicio) REFERENCES TipoServicio(idTipoServicio),
    FOREIGN KEY (idEspecializacion) REFERENCES Especializacion(idEspecializacion)
);

CREATE TABLE Servicio (
    idServicio INT NOT NULL,
    idProfesional INT NOT NULL,
    idCentro INT NOT NULL,
    idTipoServicio INT NOT NULL,
    PRIMARY KEY (idServicio),
    UNIQUE (idCentro, idTipoServicio),
    FOREIGN KEY (idProfesional) REFERENCES Profesional(idProfesional),
    FOREIGN KEY (idCentro) REFERENCES CentroDeSalud(idCentro),
    FOREIGN KEY (idTipoServicio) REFERENCES TipoServicio(idTipoServicio)
);

CREATE TABLE AsignacionServicio (
    idAsignacion INT NOT NULL,
    idProfesional INT NOT NULL,
    idServicio INT NOT NULL,
    PRIMARY KEY (idAsignacion),
    UNIQUE (idProfesional, idServicio),
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
    CHECK (horaApertura < horaCierre),
    CHECK ((idCentro IS NULL) <> (idServicio IS NULL)),
    FOREIGN KEY (idCentro) REFERENCES CentroDeSalud(idCentro),
    FOREIGN KEY (idServicio) REFERENCES Servicio(idServicio)
);

CREATE TABLE Visita (
    idVisita INT NOT NULL,
    fechaVisita DATE NOT NULL CHECK (fechaVisita <= CURRENT_DATE),
    diagnostico VARCHAR(500) NOT NULL,
    tratamiento VARCHAR(500) NOT NULL,
    idProfesional INT NOT NULL,
    idPaciente INT NOT NULL,
    idServicio INT NOT NULL,
    PRIMARY KEY (idVisita),
    FOREIGN KEY (idProfesional) REFERENCES Profesional(idProfesional),
    FOREIGN KEY (idPaciente) REFERENCES Paciente(idPaciente),
    FOREIGN KEY (idServicio) REFERENCES Servicio(idServicio)
);

CREATE TABLE Internacion (
    idInternacion INT NOT NULL,
    fechaIngreso DATE NOT NULL CHECK (fechaIngreso <= CURRENT_DATE),
    fechaEgreso DATE NULL,
    idVisita INT NOT NULL,
    PRIMARY KEY (idInternacion),
    UNIQUE (idVisita),
    CHECK (fechaEgreso >= fechaIngreso),
    FOREIGN KEY (idVisita) REFERENCES Visita(idVisita)
);



  

