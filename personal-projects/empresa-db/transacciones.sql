-- PROCEDIMIENTOS ALMACENADOS Y TRANSACCIONES

-- PROCEDIMIENTOS ALMACENADOS

DELIMITER //
CREATE PROCEDURE AgregarEmpleado(IN _nombre VARCHAR(255), IN _apellido VARCHAR(255), IN _email VARCHAR(255), IN _depto_id INT)
BEGIN
	INSERT INTO Empleados(nombre, apellido, email, depto_id) VALUES (_nombre, _apellido, _email, _depto_id);
END //


DELIMITER ;

SELECT * FROM empleados;

CALL AgregarEmpleado('Elena', 'Torres','elena.torres@email.com',3);

SELECT * FROM empleados;

-- TRANSACCIONES

BEGIN;
SAVEPOINT PreValidacion;
INSERT INTO AsignacionesDeProyectos (proyecto_id, empleado_id, horas_asignadas) VALUES (5,1,10);
INSERT INTO AsignacionesDeProyectos (proyecto_id, empleado_id, horas_asignadas) VALUES (5,2,15);
-- Imagina que aquí hay mas inserciones
-- Aqui iría el código para validar el total de horas
-- Si el total excede, podemos revertir a nuestro SAVEPOINT
ROLLBACK TO PreValidacion;

-- PROCEDIMIENTOS ALMACENADOS Y TRANSACCIONES

DELIMITER //

CREATE PROCEDURE AsignarHorasAProyecto(IN proyectoId INT, IN empleadoId INT, IN horasAsignadas INT)
BEGIN
    DECLARE horasTotales INT DEFAULT 0;  -- variables
    DECLARE horasMaximas INT DEFAULT 100; -- variables
    
    -- Iniciar una transacción
    START TRANSACTION;
    
    -- Establecer un punto de guardado
    SAVEPOINT PreValidacion;
    
    -- Calcular el total actual de horas asignadas al proyecto
    SELECT SUM(horas_asignadas) INTO horasTotales 
    FROM AsignacionesDeProyectos 
    WHERE proyecto_id = proyectoId;
    
    -- Asumiendo que SUM() puede devolver NULL si no hay filas, lo convertimos a 0
    SET horasTotales = IFNULL(horasTotales, 0) + horasAsignadas;
    
    -- Verificar si el total excede las horas máximas permitidas
    IF horasTotales > horasMaximas THEN
        -- Revertir a SAVEPOINT si se excede el total de horas
        ROLLBACK TO PreValidacion;
        -- Aunque el ROLLBACK TO SAVEPOINT mantiene la transacción activa, decidimos terminar la operación con un mensaje de error.
        SELECT 'Error: La asignación excede el total de horas permitidas para el proyecto.' AS mensaje;
    ELSE
        -- Insertar la nueva asignación si el total está dentro del límite
        INSERT INTO AsignacionesDeProyectos (proyecto_id, empleado_id, horas_asignadas) 
        VALUES (proyectoId, empleadoId, horasAsignadas);
        
        -- Confirmar la transacción si todas las operaciones fueron exitosas
        COMMIT;
    END IF;
END //

DELIMITER ;

CALL AsignarHorasAProyecto(1,1,5);

SELECT * FROM AsignacionesDeProyectos WHERE proyecto_id = 1 AND empleado_id = 1;

CALL AsignarHorasAProyecto(1,1,10);

SELECT * FROM AsignacionesDeProyectos WHERE proyecto_id = 1 AND empleado_id = 1;

-- Error de Asignación de Horas

CALL AsignarHorasAProyecto(1,1,90);

SELECT * FROM AsignacionesDeProyectos WHERE proyecto_id = 1 AND empleado_id = 1;
