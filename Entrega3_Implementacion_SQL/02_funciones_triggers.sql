CREATE OR REPLACE FUNCTION fn_validar_visita() 
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.diagnostico IS NULL OR NEW.diagnostico = '' THEN
        RAISE EXCEPTION 'El diagnóstico de la visita no puede estar vacío.';
    END IF;
    
    IF NEW.fechaVisita > CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de la visita no puede ser posterior a la fecha actual.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_visita
BEFORE INSERT OR UPDATE ON Visita
FOR EACH ROW 
EXECUTE PROCEDURE fn_validar_visita();
