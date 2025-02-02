PGDMP                         x            puntodeventa_produccion     11.7 (Ubuntu 11.7-2.pgdg16.04+1)     11.7 (Ubuntu 11.7-2.pgdg16.04+1) �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                       false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                       false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                       false            �           1262    16384    puntodeventa_produccion    DATABASE     �   CREATE DATABASE puntodeventa_produccion WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'es_CL.UTF-8' LC_CTYPE = 'es_CL.UTF-8';
 '   DROP DATABASE puntodeventa_produccion;
             postgres    false            �            1255    16415 *   fn_caja_apertura_i(date, integer, integer)    FUNCTION       CREATE FUNCTION public.fn_caja_apertura_i(date, integer, integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE

	__fecha			 	ALIAS FOR $1;
	__efectivo	 		ALIAS FOR $2;
	__id_usuario 		ALIAS FOR $3;
    
    
    
BEGIN


    INSERT INTO 
      public.caja_apertura
    (
      fecha,
      efectivo,
      id_usuario,
      time_creado,
      cerrado
    )
    VALUES (
      __fecha,
      __efectivo,
      __id_usuario,
      now(),
      'f'
    );
    
    RETURN '0';


END;
$_$;
 A   DROP FUNCTION public.fn_caja_apertura_i(date, integer, integer);
       public       postgres    false            �            1255    16416 ~   fn_caja_cierre_i(integer, integer, integer, integer, integer, integer, integer, integer, character varying, character varying)    FUNCTION     �  CREATE FUNCTION public.fn_caja_cierre_i(integer, integer, integer, integer, integer, integer, integer, integer, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE

	__id_apertura				ALIAS FOR $1;
	__efectivo_apertura			ALIAS FOR $2;
	__efectivo_cierre			ALIAS FOR $3;
	__ventas_efectivo			ALIAS FOR $4;
	__ventas_tarjetas			ALIAS FOR $5;
	__entrega	 				ALIAS FOR $6;
    __gastos	 				ALIAS FOR $7;
	__id_usuario 				ALIAS FOR $8;
	__user_autoriza				ALIAS FOR $9;
	__pass_usuario__autoriza 	ALIAS FOR $10;

    
    _id_cierre INTEGER;
    
    _usuario RECORD;
    
BEGIN


SELECT 
  id_usuario,
  tipo_usuario
INTO _usuario
FROM 
  public.usuario 
WHERE usuario = __user_autoriza 
AND password = __pass_usuario__autoriza;

-- _usuario.id_usuario
-- _usuario.tipo_usuario



IF (_usuario.id_usuario IS NULL) THEN
	-- RETURN 'E01-DB'; --usuario y/o contraseña incorrecta
    RETURN 'Usuario y/o contraseña incorrecta';
END IF;

IF (_usuario.tipo_usuario != 'admin') THEN
	-- RETURN 'E02-DB'; --usuario no es administrador
    RETURN 'Usuario ingresado no es administrador'; --usuario no es administrador
END IF;



    INSERT INTO 
      public.caja_cierre
    (
      id_apertura,
      efectivo_apertura,
      efectivo_cierre,
      ventas_efectivo,
      ventas_tarjetas,
      entrega,
      gastos,
      id_usuario,
      time_cierre,
      id_usuario_autoriza
    )
    VALUES (
      __id_apertura,
      __efectivo_apertura,
      __efectivo_cierre,
      __ventas_efectivo,
      __ventas_tarjetas,
      __entrega,
      __gastos,
      __id_usuario,
      now(),
      _usuario.id_usuario
    ) RETURNING id_cierre INTO _id_cierre;

    UPDATE 
      public.caja_apertura 
    SET 
      cerrado = 't'
    WHERE 
      id_apertura = __id_apertura
    ;
    
    --anular ventas impagas
    UPDATE 
      public.venta_temporal 
    SET 
      anulado = 't'
    WHERE 
        id_apertura = __id_apertura AND
        pagado IS NOT TRUE;
    
    
    
    --ALTER SEQUENCE public.venta_temporal_id_diario_seq RESTART;
    
    RETURN _id_cierre;

END;
$_$;
 �   DROP FUNCTION public.fn_caja_cierre_i(integer, integer, integer, integer, integer, integer, integer, integer, character varying, character varying);
       public       postgres    false            �            1255    16417 &   fn_dinero_custodia_d(integer, integer)    FUNCTION     $  CREATE FUNCTION public.fn_dinero_custodia_d(integer, integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE

  _id_dinero_custodia 		ALIAS FOR $1;
  _id_usuario 				ALIAS FOR $2;
  
  __id_dinero_custodia_r 	INTEGER;
  
BEGIN

    UPDATE 
      public.dinero_custodia 
    SET 
      eliminado = 't',
      id_usuario_d = _id_usuario,
      time_eliminado = now()
    WHERE 
      id_dinero_custodia = _id_dinero_custodia
    RETURNING id_dinero_custodia INTO __id_dinero_custodia_r;

    
    IF (__id_dinero_custodia_r IS NULL) THEN
    	RETURN '1'; --no se encontró id de custodia
    ELSE
    	RETURN '2'; --eliminado correctamente
  	END IF;
  
    EXCEPTION
    WHEN others THEN
		RETURN '0'; --'Error al eliminar dinero en custodia.';
END;
$_$;
 =   DROP FUNCTION public.fn_dinero_custodia_d(integer, integer);
       public       postgres    false                       1255    16418 9   fn_dinero_custodia_i(character varying, integer, integer)    FUNCTION     �  CREATE FUNCTION public.fn_dinero_custodia_i(character varying, integer, integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
  _nombre 				ALIAS FOR $1;
  _monto_inicial 		ALIAS FOR $2;
  _id_usuario 			ALIAS FOR $3;
  
  __id_dinero_custodia 	INTEGER;
  __id_movimiento 		INTEGER;
  
BEGIN


  INSERT INTO 
    public.dinero_custodia
  (
    nombre,
    id_usuario_i,
    time_creado
  )
  VALUES (
    _nombre,
    _id_usuario,
    now()
  ) 
  RETURNING id_dinero_custodia INTO __id_dinero_custodia;


IF (_monto_inicial > 0) THEN
	INSERT INTO 
      public.dinero_custodia_movimientos
    (
      id_dinero_custodia,
      monto,
      comentario,
      id_usuario_i,
      time_creado
    )
    VALUES (
      __id_dinero_custodia,
      _monto_inicial,
      'Monto inicial',
      _id_usuario,
      now()
    )RETURNING id_movimiento INTO __id_movimiento;
    
    RETURN '2'; --'Dinero en custodia y movimiento de monto inicial agregado correctamente.';

ELSE
	RETURN '1'; --'Dinero en custodia agregado correctamente.';

END IF;



EXCEPTION
    WHEN others THEN
		RETURN '0'; --'Error al agregar dinero en custodia.';

END;
$_$;
 P   DROP FUNCTION public.fn_dinero_custodia_i(character varying, integer, integer);
       public       postgres    false                       1255    16419 "   fn_gastos_caja_d(integer, integer)    FUNCTION     )  CREATE FUNCTION public.fn_gastos_caja_d(integer, integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE

  __id_gasto 	ALIAS FOR $1;
  __id_usuario 	ALIAS FOR $2;
  
  _id_gasto_r 				INTEGER;
  _id_movimiento_custodia 	INTEGER;
  
BEGIN

    
UPDATE 
  public.gastos_caja 
SET 
  eliminado = 't',
  id_usuario_d = __id_usuario,
  time_eliminado = now()
WHERE 
  id_gasto = __id_gasto
RETURNING id_gasto INTO _id_gasto_r
;

IF (_id_gasto_r IS NULL) THEN
	RETURN '0'; --error
END IF;

SELECT id_movimiento_custodia INTO _id_movimiento_custodia
FROM public.gastos_caja
WHERE id_gasto = __id_gasto;


IF (_id_movimiento_custodia IS NULL) THEN
	RETURN '1'; --gasto borrado. sin mov en custodia asociado
ELSE
	UPDATE 
      public.dinero_custodia_movimientos 
    SET
      eliminado = 't',
      id_usuario_d = __id_usuario,
      time_eliminado = now()
    WHERE 
      id_movimiento = _id_movimiento_custodia
	;
    RETURN '2'; --gasto y mov en custodia asociado borrados
END IF;


    
END;
$_$;
 9   DROP FUNCTION public.fn_gastos_caja_d(integer, integer);
       public       postgres    false                       1255    16420 b   fn_gastos_caja_i(integer, integer, character varying, integer, boolean, integer, integer, integer)    FUNCTION     �  CREATE FUNCTION public.fn_gastos_caja_i(integer, integer, character varying, integer, boolean, integer, integer, integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE

    _id_apertura           ALIAS FOR $1;
    _id_tipo_gasto         ALIAS FOR $2;
    _descripcion           ALIAS FOR $3;
    _monto                 ALIAS FOR $4;
    _dinero_en_custodia    ALIAS FOR $5;
    _id_dinero_custodia    ALIAS FOR $6;
    _id_usuario_i          ALIAS FOR $7;
    _id_mov_custodia       ALIAS FOR $8;
    
    __id_gasto_retornado VARCHAR := 0;

BEGIN

IF (_dinero_en_custodia = 't') THEN

  INSERT INTO 
    public.gastos_caja
  (
    id_apertura,
    id_tipo_gasto,
    descripcion,
    monto,
    dinero_en_custodia,
    id_dinero_custodia,
    id_usuario_i,
    time_creado,
    id_movimiento_custodia
  )
  VALUES (
    _id_apertura,
    _id_tipo_gasto,
    _descripcion,
    _monto,
    't',
    _id_dinero_custodia,
    _id_usuario_i,
    now(),
    _id_mov_custodia
  )
  RETURNING gastos_caja.id_gasto INTO __id_gasto_retornado;
   
ELSE

  INSERT INTO 
    public.gastos_caja
  (
    id_apertura,
    id_tipo_gasto,
    descripcion,
    monto,
    dinero_en_custodia,
    id_usuario_i,
    time_creado
  )
  VALUES (
    _id_apertura,
    _id_tipo_gasto,
    _descripcion,
    _monto,
    'f',
    _id_usuario_i,
    now()
  )
  RETURNING gastos_caja.id_gasto INTO __id_gasto_retornado;
  
END IF;

IF (__id_gasto_retornado IS NOT NULL) THEN
  RETURN '1'; --'Dinero en custodia agregado correctamente.';
ELSE
  RETURN '2'; --'Error.';
END IF;

--EXCEPTION
--WHEN others THEN
--    RETURN '0'; --'Error al agregar gasto.';

END;
$_$;
 y   DROP FUNCTION public.fn_gastos_caja_i(integer, integer, character varying, integer, boolean, integer, integer, integer);
       public       postgres    false                       1255    16421 T   fn_gastos_caja_i_sin_custodia(integer, integer, character varying, integer, integer)    FUNCTION     �  CREATE FUNCTION public.fn_gastos_caja_i_sin_custodia(integer, integer, character varying, integer, integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE

--funcion gasto sin dinero en custodia asociado

    _id_apertura           ALIAS FOR $1;
    _id_tipo_gasto         ALIAS FOR $2;
    _descripcion           ALIAS FOR $3;
    _monto                 ALIAS FOR $4;
    _id_usuario_i          ALIAS FOR $5;

BEGIN

  INSERT INTO 
    public.gastos_caja
  (
    id_apertura,
    id_tipo_gasto,
    descripcion,
    monto,
    id_usuario_i,
    time_creado
  )
  VALUES (
    id_apertura,
    id_tipo_gasto,
    descripcion,
    monto,
    id_usuario_i,
    now()
  )
  RETURNING id_gasto;





END;
$_$;
 k   DROP FUNCTION public.fn_gastos_caja_i_sin_custodia(integer, integer, character varying, integer, integer);
       public       postgres    false                       1255    16422 G   fn_gastos_caja_u(integer, integer, character varying, integer, integer)    FUNCTION     F  CREATE FUNCTION public.fn_gastos_caja_u(integer, integer, character varying, integer, integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$
DECLARE

	__id_gasto	 		ALIAS FOR $1;
	__id_apertura 		ALIAS FOR $2;
	__descripcion 		ALIAS FOR $3;
	__monto 			ALIAS FOR $4;
	__id_usuario 		ALIAS FOR $5;
    
BEGIN

    UPDATE 
      public.gastos_caja 
    SET 
      id_apertura = __id_apertura,
      descripcion = __descripcion,
      monto = __monto,
      id_usuario = __id_usuario,
      "time" = now()
    WHERE 
      id_gasto = __id_gasto
    ;

END;
$_$;
 ^   DROP FUNCTION public.fn_gastos_caja_u(integer, integer, character varying, integer, integer);
       public       postgres    false                       1255    16423    fn_id_diario_actual()    FUNCTION     �   CREATE FUNCTION public.fn_id_diario_actual() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
  
BEGIN

	RETURN currval('public.venta_temporal_id_venta_temp_seq');
  
END;
$$;
 ,   DROP FUNCTION public.fn_id_diario_actual();
       public       postgres    false                       1255    16424 %   fn_movimiento_dec_d(integer, integer)    FUNCTION       CREATE FUNCTION public.fn_movimiento_dec_d(integer, integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
  _id_movimiento 		ALIAS FOR $1;
  _id_usuario 			ALIAS FOR $2;
  
  __id_movimiento_r 	INTEGER;
BEGIN

	UPDATE 
      public.dinero_custodia_movimientos 
    SET 
      eliminado = 't',
      id_usuario_d = _id_usuario,
      time_eliminado = now()
    WHERE 
      id_movimiento = _id_movimiento
    RETURNING id_movimiento INTO __id_movimiento_r;
    
    
    IF (__id_movimiento_r IS NULL) THEN
    	RETURN '1'; --no se encontró id de movimiento
    ELSE
    	RETURN '2'; --eliminado correctamente
  	END IF;
  
    EXCEPTION
    WHEN others THEN
		RETURN '0'; --'Error al eliminar movimiento de dinero en custodia.';
END;
$_$;
 <   DROP FUNCTION public.fn_movimiento_dec_d(integer, integer);
       public       postgres    false                       1255    16425 J   fn_movimiento_dec_i(integer, integer, character varying, integer, boolean)    FUNCTION     k  CREATE FUNCTION public.fn_movimiento_dec_i(integer, integer, character varying, integer, boolean) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE

  _id_dinero_custodia 	ALIAS FOR $1;
  _monto		 		ALIAS FOR $2;
  _comentario 			ALIAS FOR $3;
  _id_usuario 			ALIAS FOR $4;
  _gasto	 			ALIAS FOR $5;
  
  __id_movimiento 		INTEGER;
  
BEGIN
	INSERT INTO 
      public.dinero_custodia_movimientos
    (
      id_dinero_custodia,
      monto,
      comentario,
      id_usuario_i,
      time_creado,
      gasto
    )
    VALUES (
      _id_dinero_custodia,
      _monto,
      _comentario,
      _id_usuario,
      now(),
      _gasto
    )RETURNING id_movimiento INTO __id_movimiento;
    
    --RETURN '1'; --'Movimiento de dinero en custodia agregado correctamente.';
    IF (__id_movimiento IS NOT NULL) THEN
    	RETURN __id_movimiento; --'Movimiento de dinero en custodia agregado correctamente.';
    ELSE
    	RETURN '0';
    END IF;
    
    EXCEPTION
    WHEN others THEN
		RETURN '0'; --'Error al agregar movimiento de dinero en custodia.';
        
END;
$_$;
 a   DROP FUNCTION public.fn_movimiento_dec_i(integer, integer, character varying, integer, boolean);
       public       postgres    false                        1255    16426     fn_producto_d(character varying)    FUNCTION     �  CREATE FUNCTION public.fn_producto_d(character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
  _codigodebarras ALIAS FOR $1;
  
  __existe VARCHAR;
  
BEGIN
	IF (_codigodebarras IS NULL) THEN
    	RETURN '1'; -- codigo nulo
    END IF;
    
    SELECT COUNT(a.idproducto) INTO __existe
    FROM public.producto AS a
    WHERE a.codigodebarras = _codigodebarras
    LIMIT 1;
    
    IF (__existe = '0') THEN
    	RETURN '2'; -- no existe codigo
    END IF;
    
    
	--DELETE FROM public.producto WHERE codigodebarras = _codigodebarras;
    UPDATE 
      public.producto 
    SET 
      activo = FALSE
    WHERE 
      codigodebarras = _codigodebarras
    ;
    RETURN '0';
    
END;
$_$;
 7   DROP FUNCTION public.fn_producto_d(character varying);
       public       postgres    false            	           1255    16427 k   fn_producto_iu(character varying, character varying, integer, character varying, integer, integer, boolean)    FUNCTION     b  CREATE FUNCTION public.fn_producto_iu(nombre character varying, codigo character varying, precio integer, imagen character varying, idcat integer, idun integer, cambioimagen boolean) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE

	_nombreproducto		ALIAS FOR $1;
    _codigodebarras		ALIAS FOR $2;
    _precio				ALIAS FOR $3;
    _imagen				ALIAS FOR $4;
    _idcategoria		ALIAS FOR $5;
    _idunidad			ALIAS FOR $6;
    _cambioimagen		ALIAS FOR $7;

    __existe VARCHAR;

BEGIN

	SELECT COUNT(a.idproducto) INTO __existe
    FROM public.producto AS a
    WHERE a.codigodebarras = _codigodebarras
    LIMIT 1;
    
    IF (__existe = '0') THEN
    
    	INSERT INTO 
          public.producto
        (
          nombreproducto,
          codigodebarras,
          precio,
          imagen,
          idcategoria,
          idunidad
        )
        VALUES (
          _nombreproducto,
          _codigodebarras,
          _precio,
          _imagen,
          _idcategoria,
          _idunidad
        );
        RETURN '0';

    END IF;
	
    IF (__existe = '1') THEN
    
    	IF (_cambioimagen = TRUE) THEN
    
            UPDATE 
              public.producto 
            SET 
              nombreproducto = _nombreproducto,
              precio = _precio,
              idcategoria = _idcategoria,
              idunidad = _idunidad,
              imagen = _imagen,
              activo = true
            WHERE 
              codigodebarras = _codigodebarras
            ;
            RETURN '1';
            
        ELSE
        
        	UPDATE 
              public.producto 
            SET 
              nombreproducto = _nombreproducto,
              precio = _precio,
              idcategoria = _idcategoria,
              idunidad = _idunidad,
              activo = true
            WHERE 
              codigodebarras = _codigodebarras
            ;
            RETURN '1';
            
            
        END IF;

    END IF;
    
    --RETURN '2';
    
EXCEPTION
    WHEN others THEN
		RETURN '2';

END;
$_$;
 �   DROP FUNCTION public.fn_producto_iu(nombre character varying, codigo character varying, precio integer, imagen character varying, idcat integer, idun integer, cambioimagen boolean);
       public       postgres    false            
           1255    16428 2   fn_promocion_i(integer, integer, integer, integer)    FUNCTION     &  CREATE FUNCTION public.fn_promocion_i(integer, integer, integer, integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$
DECLARE

	__id_producto	 	ALIAS FOR $1;
	__cantidad	 		ALIAS FOR $2;
	__tipo_descuento	ALIAS FOR $3;
	__descuento 		ALIAS FOR $4;

BEGIN

    INSERT INTO 
      public.promociones
    (
      idproducto,
      cantidad,
      tipo_descuento,
      descuento,
      activo
    )
    VALUES (
      __id_producto,
      __cantidad,
      __tipo_descuento,
      __descuento,
      't'
    );


END;
$_$;
 I   DROP FUNCTION public.fn_promocion_i(integer, integer, integer, integer);
       public       postgres    false                       1255    16429 N   fn_promocion_u(integer, integer, integer, integer, integer, character varying)    FUNCTION     �  CREATE FUNCTION public.fn_promocion_u(integer, integer, integer, integer, integer, character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$
DECLARE

	__id_promocion	 	ALIAS FOR $1;
	__id_producto	 	ALIAS FOR $2;
	__cantidad	 		ALIAS FOR $3;
	__tipo_descuento	ALIAS FOR $4;
	__descuento 		ALIAS FOR $5;
    __activo 			ALIAS FOR $6;

BEGIN

    UPDATE 
      public.promociones 
    SET 
      idproducto 		= __id_producto,
      cantidad 			= __cantidad,
      tipo_descuento 	= __tipo_descuento,
      descuento 		= __descuento,
      activo 			= __activo
    WHERE 
      id_promocion 		= __id_promocion
    ;

END;
$_$;
 e   DROP FUNCTION public.fn_promocion_u(integer, integer, integer, integer, integer, character varying);
       public       postgres    false                       1255    16430 X   fn_usuario_i(character varying, character varying, character varying, character varying)    FUNCTION     j  CREATE FUNCTION public.fn_usuario_i(character varying, character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE

  __nombre 			ALIAS FOR $1;
  __usuario 		ALIAS FOR $2;
  __password 		ALIAS FOR $3;
  __tipo_usuario 	ALIAS FOR $4;

  _id_usuario 		VARCHAR;
  
BEGIN

SELECT 
  id_usuario INTO _id_usuario
FROM 
  public.usuario 
  WHERE usuario = __usuario;
  
IF (_id_usuario IS NOT NULL) THEN
	RETURN 'Usuario ya existe'; -- usuario ya existe
END IF;




INSERT INTO 
  public.usuario
(
  nombre,
  usuario,
  password,
  tipo_usuario
)
VALUES (
  __nombre,
  __usuario,
  __password,
  __tipo_usuario
  ) RETURNING id_usuario INTO _id_usuario;


RETURN _id_usuario;

  EXCEPTION
  WHEN OTHERS THEN
    RETURN 'Error al agregar usuario';
    
    
END;
$_$;
 o   DROP FUNCTION public.fn_usuario_i(character varying, character varying, character varying, character varying);
       public       postgres    false                       1255    16431    fn_venta_detalle_d(integer)    FUNCTION     "  CREATE FUNCTION public.fn_venta_detalle_d(id_detalle integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$
DECLARE

	__id_detalle 	ALIAS FOR $1;

BEGIN
    
    DELETE FROM 
      public.venta_detalle 
    WHERE 
      venta_detalle.id_detalle = __id_detalle
    ;

END;
$_$;
 =   DROP FUNCTION public.fn_venta_detalle_d(id_detalle integer);
       public       postgres    false                       1255    16432 H   fn_venta_detalle_i(integer, integer, numeric, integer, integer, integer)    FUNCTION       CREATE FUNCTION public.fn_venta_detalle_i(integer, integer, numeric, integer, integer, integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$
DECLARE

	__id_venta_temp 	ALIAS FOR $1;
	__id_producto 		ALIAS FOR $2;
	__cantidad 			ALIAS FOR $3;
	__id_usuario 		ALIAS FOR $4;
	__monto 			ALIAS FOR $5;
	__id_promocion 		ALIAS FOR $6;

BEGIN

	IF (__id_promocion = 0) THEN
    	__id_promocion = NULL;
    END IF;

    INSERT INTO 
      public.venta_detalle
    (
      id_venta_temp,
      idproducto,
      cantidad,
      id_usuario,
      "time",
  	  monto,
      id_promocion
    )
    VALUES (
      __id_venta_temp,
      __id_producto,
      __cantidad,
      __id_usuario,
      now(),
      __monto,
      __id_promocion
    );

END;
$_$;
 _   DROP FUNCTION public.fn_venta_detalle_i(integer, integer, numeric, integer, integer, integer);
       public       postgres    false                       1255    16433 Q   fn_venta_detalle_u(integer, integer, integer, numeric, integer, integer, integer)    FUNCTION     �  CREATE FUNCTION public.fn_venta_detalle_u(integer, integer, integer, numeric, integer, integer, integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$
DECLARE

	__id_detalle 		ALIAS FOR $1;
	__id_venta_temp 	ALIAS FOR $2;
	__id_producto 		ALIAS FOR $3;
	__cantidad 			ALIAS FOR $4;
	__id_usuario 		ALIAS FOR $5;
	__monto 			ALIAS FOR $6;
	__id_promocion 		ALIAS FOR $7;

BEGIN

    UPDATE 
      public.venta_detalle 
    SET 
      id_venta_temp = __id_venta_temp,
      idproducto = __id_producto,
      cantidad = __cantidad,
      id_usuario = __id_usuario,
      monto = __monto,
      id_promocion = __id_promocion
    WHERE 
      id_detalle = __id_detalle
    ;

END;
$_$;
 h   DROP FUNCTION public.fn_venta_detalle_u(integer, integer, integer, numeric, integer, integer, integer);
       public       postgres    false                       1255    16434 7   fn_venta_i(integer, integer, integer, integer, integer)    FUNCTION     �  CREATE FUNCTION public.fn_venta_i(integer, integer, integer, integer, integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE

	__id_venta_temp 	ALIAS FOR $1;
	__id_apertura 		ALIAS FOR $2;
	__monto_venta 		ALIAS FOR $3;
	__id_tipo_pago 		ALIAS FOR $4;
	__id_usuario 		ALIAS FOR $5;
    
BEGIN

    INSERT INTO 
      public.venta
    (
      id_venta_temp,
      id_apertura,
      monto_venta,
      id_tipo_pago,
      id_usuario,
	  time_creado
    )
    VALUES (
      __id_venta_temp,
      __id_apertura,
      __monto_venta,
      __id_tipo_pago,
      __id_usuario,
      now()
    );

RETURN '0';

END;
$_$;
 N   DROP FUNCTION public.fn_venta_i(integer, integer, integer, integer, integer);
       public       postgres    false                       1255    16435 !   fn_venta_temporal_anular(integer)    FUNCTION     l  CREATE FUNCTION public.fn_venta_temporal_anular(integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	__id_venta_temp 	ALIAS FOR $1;
	_existe VARCHAR;
BEGIN

  UPDATE 
  public.venta_temporal 
SET 
  anulado = 't'
WHERE 
  id_venta_temp = __id_venta_temp
  RETURNING id_venta_temp INTO _existe
;

RETURN _existe;

END;
$_$;
 8   DROP FUNCTION public.fn_venta_temporal_anular(integer);
       public       postgres    false                       1255    16436    fn_venta_temporal_d(integer)    FUNCTION     �  CREATE FUNCTION public.fn_venta_temporal_d(integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$
DECLARE

  	__id_venta_temp 	ALIAS FOR $1;
  
BEGIN

    DELETE FROM 
      public.venta_detalle 
    WHERE 
      id_venta_temp = __id_venta_temp
    ;

    DELETE FROM 
      public.venta_temporal 
    WHERE 
      id_venta_temp = __id_venta_temp
    ;
    


END;
$_$;
 3   DROP FUNCTION public.fn_venta_temporal_d(integer);
       public       postgres    false                       1255    16437    fn_venta_temporal_i(integer)    FUNCTION     �  CREATE FUNCTION public.fn_venta_temporal_i(integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE

	_id_usuario ALIAS FOR $1;
  
BEGIN

	INSERT INTO public.venta_temporal(id_usuario) VALUES (_id_usuario);

	RETURN currval('public.venta_temporal_id_venta_temp_seq');
    
    --RETURN QUERY SELECT currval('public.venta_temporal_id_venta_temp_seq') as id_venta_temporal, currval('public.venta_temporal_id_diario_seq') as id_diario;

END;
$_$;
 3   DROP FUNCTION public.fn_venta_temporal_i(integer);
       public       postgres    false                       1255    16438 7   fn_venta_temporal_i_letra_id_diario(character, integer)    FUNCTION     �  CREATE FUNCTION public.fn_venta_temporal_i_letra_id_diario(character, integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE

	_letra_id_diario 	ALIAS FOR $1;
	_id_usuario 		ALIAS FOR $2;
    
    id_diario_alfa VARCHAR;
  
BEGIN

	INSERT INTO public.venta_temporal(id_usuario, letra_id_diario, id_apertura) 
    VALUES (_id_usuario, _letra_id_diario, 
                                          (
                                              SELECT 
                                              id_apertura
                                            FROM 
                                              public.caja_apertura 
                                            WHERE cerrado IS NOT TRUE
                                          )
    
    );
    
    RETURN currval('public.venta_temporal_id_venta_temp_seq');
    
    --SELECT letra_id_diario || '-' || id_diario 
    --INTO id_diario_alfa
    --FROM 
    --    public.venta_temporal 
    --    WHERE id_venta_temp = (SELECT 
    --    MAX(id_venta_temp)
    --FROM 
    --    public.venta_temporal);
    --    
	--RETURN id_diario_alfa;

	
    
    
    
END;
$_$;
 N   DROP FUNCTION public.fn_venta_temporal_i_letra_id_diario(character, integer);
       public       postgres    false                       1255    16439     fn_venta_temporal_pagar(integer)    FUNCTION     v  CREATE FUNCTION public.fn_venta_temporal_pagar(integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
  _id_venta_temporal ALIAS FOR $1;
  
  __existe VARCHAR;
BEGIN

SELECT * INTO __existe
FROM public.venta_temporal 
WHERE pagado IS NOT TRUE
AND id_venta_temp = _id_venta_temporal
LIMIT 1;

IF __existe IS NULL THEN
  RETURN '1'; -- NO SE PUEDE ACTUALIZAR
END IF;



  UPDATE 
    public.venta_temporal 
  SET
    pagado = 't',
    anulado = 'f',
    time_pagado = now()
  WHERE 
    id_venta_temp = _id_venta_temporal
  ;
  


RETURN '0'; -- registro actualizado

END;
$_$;
 7   DROP FUNCTION public.fn_venta_temporal_pagar(integer);
       public       postgres    false                       1255    16440    fn_verificar_caja_apertura()    FUNCTION     �  CREATE FUNCTION public.fn_verificar_caja_apertura() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
	_existe VARCHAR;
BEGIN
        
SELECT 
  id_apertura 
  INTO _existe
FROM 
  public.caja_apertura 
  WHERE cerrado IS NOT TRUE
  LIMIT 1;
  
IF _existe IS NOT NULL THEN
	RETURN _existe; -- id_apertura
END IF;

RETURN '0'; -- no hay caja abierta
  
  
END;
$$;
 3   DROP FUNCTION public.fn_verificar_caja_apertura();
       public       postgres    false                       1255    16441 #   fn_verificar_caja_apertura(integer)    FUNCTION       CREATE FUNCTION public.fn_verificar_caja_apertura(integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	__id_apertura		ALIAS FOR $1;
	__existe VARCHAR;
BEGIN

IF (__id_apertura IS NULL) THEN
	RETURN '2'; -- id apertura nulo
END IF;
        
SELECT 
  id_apertura 
  INTO __existe
FROM 
  public.caja_apertura 
  WHERE cerrado IS NOT TRUE
  AND id_apertura = __id_apertura
  LIMIT 1;
  
IF __existe IS NOT NULL THEN
	RETURN '1'; -- HAY CAJA ABIERTA
END IF;

RETURN '0';


END;
$_$;
 :   DROP FUNCTION public.fn_verificar_caja_apertura(integer);
       public       postgres    false            �            1259    16442    caja_apertura    TABLE     �   CREATE TABLE public.caja_apertura (
    id_apertura integer NOT NULL,
    fecha date NOT NULL,
    efectivo integer NOT NULL,
    id_usuario integer NOT NULL,
    time_creado timestamp without time zone NOT NULL,
    cerrado boolean NOT NULL
);
 !   DROP TABLE public.caja_apertura;
       public         postgres    false            �            1259    16445    caja_apertura_id_apertura_seq    SEQUENCE     �   CREATE SEQUENCE public.caja_apertura_id_apertura_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.caja_apertura_id_apertura_seq;
       public       postgres    false    196            �           0    0    caja_apertura_id_apertura_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE public.caja_apertura_id_apertura_seq OWNED BY public.caja_apertura.id_apertura;
            public       postgres    false    197            �            1259    16447    caja_cierre    TABLE     �  CREATE TABLE public.caja_cierre (
    id_cierre integer NOT NULL,
    id_apertura integer NOT NULL,
    efectivo_apertura integer NOT NULL,
    efectivo_cierre integer NOT NULL,
    ventas_efectivo integer NOT NULL,
    ventas_tarjetas integer NOT NULL,
    entrega integer NOT NULL,
    gastos integer NOT NULL,
    id_usuario integer NOT NULL,
    time_cierre timestamp without time zone NOT NULL,
    id_usuario_autoriza integer NOT NULL
);
    DROP TABLE public.caja_cierre;
       public         postgres    false            �            1259    16450    caja_cierre_id_cierre_seq    SEQUENCE     �   CREATE SEQUENCE public.caja_cierre_id_cierre_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.caja_cierre_id_cierre_seq;
       public       postgres    false    198            �           0    0    caja_cierre_id_cierre_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE public.caja_cierre_id_cierre_seq OWNED BY public.caja_cierre.id_cierre;
            public       postgres    false    199            �            1259    16452 	   categoria    TABLE     y   CREATE TABLE public.categoria (
    idcategoria smallint NOT NULL,
    nombrecategoria character varying(30) NOT NULL
);
    DROP TABLE public.categoria;
       public         postgres    false            �            1259    16455    dinero_custodia    TABLE     2  CREATE TABLE public.dinero_custodia (
    id_dinero_custodia integer NOT NULL,
    nombre character varying NOT NULL,
    id_usuario_i integer NOT NULL,
    time_creado timestamp without time zone NOT NULL,
    eliminado boolean,
    id_usuario_d integer,
    time_eliminado timestamp without time zone
);
 #   DROP TABLE public.dinero_custodia;
       public         postgres    false            �            1259    16461 &   dinero_custodia_id_dinero_custodia_seq    SEQUENCE     �   CREATE SEQUENCE public.dinero_custodia_id_dinero_custodia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 =   DROP SEQUENCE public.dinero_custodia_id_dinero_custodia_seq;
       public       postgres    false    201            �           0    0 &   dinero_custodia_id_dinero_custodia_seq    SEQUENCE OWNED BY     q   ALTER SEQUENCE public.dinero_custodia_id_dinero_custodia_seq OWNED BY public.dinero_custodia.id_dinero_custodia;
            public       postgres    false    202            �            1259    16463    dinero_custodia_movimientos    TABLE     �  CREATE TABLE public.dinero_custodia_movimientos (
    id_movimiento integer NOT NULL,
    id_dinero_custodia integer NOT NULL,
    monto integer NOT NULL,
    comentario character varying,
    id_usuario_i integer NOT NULL,
    time_creado timestamp without time zone NOT NULL,
    eliminado boolean,
    id_usuario_d integer,
    time_eliminado timestamp without time zone,
    gasto boolean
);
 /   DROP TABLE public.dinero_custodia_movimientos;
       public         postgres    false            �            1259    16469 -   dinero_custodia_movimientos_id_movimiento_seq    SEQUENCE     �   CREATE SEQUENCE public.dinero_custodia_movimientos_id_movimiento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 D   DROP SEQUENCE public.dinero_custodia_movimientos_id_movimiento_seq;
       public       postgres    false    203            �           0    0 -   dinero_custodia_movimientos_id_movimiento_seq    SEQUENCE OWNED BY        ALTER SEQUENCE public.dinero_custodia_movimientos_id_movimiento_seq OWNED BY public.dinero_custodia_movimientos.id_movimiento;
            public       postgres    false    204            �            1259    16471    gastos_caja    TABLE     �  CREATE TABLE public.gastos_caja (
    id_gasto integer NOT NULL,
    id_apertura integer NOT NULL,
    id_tipo_gasto integer NOT NULL,
    descripcion character varying NOT NULL,
    monto integer NOT NULL,
    dinero_en_custodia boolean,
    id_dinero_custodia integer,
    id_usuario_i integer NOT NULL,
    time_creado timestamp without time zone NOT NULL,
    eliminado boolean,
    id_usuario_d integer,
    time_eliminado timestamp without time zone,
    id_movimiento_custodia integer
);
    DROP TABLE public.gastos_caja;
       public         postgres    false            �            1259    16477    gastos_caja_id_gasto_seq    SEQUENCE     �   CREATE SEQUENCE public.gastos_caja_id_gasto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.gastos_caja_id_gasto_seq;
       public       postgres    false    205            �           0    0    gastos_caja_id_gasto_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.gastos_caja_id_gasto_seq OWNED BY public.gastos_caja.id_gasto;
            public       postgres    false    206            �            1259    16479    perfiles_usuario    TABLE     �  CREATE TABLE public.perfiles_usuario (
    tipo_usuario character varying NOT NULL,
    caja boolean,
    meson boolean,
    mantenedor_productos boolean,
    mantenedor_usuarios boolean,
    tipo_usuario_completo character varying
);
ALTER TABLE ONLY public.perfiles_usuario ALTER COLUMN tipo_usuario SET STATISTICS 0;
ALTER TABLE ONLY public.perfiles_usuario ALTER COLUMN caja SET STATISTICS 0;
ALTER TABLE ONLY public.perfiles_usuario ALTER COLUMN meson SET STATISTICS 0;
 $   DROP TABLE public.perfiles_usuario;
       public         postgres    false            �            1259    16485    producto    TABLE     T  CREATE TABLE public.producto (
    idproducto integer NOT NULL,
    nombreproducto character varying NOT NULL,
    codigodebarras character varying(30) NOT NULL,
    precio integer NOT NULL,
    imagen character varying(100),
    idcategoria smallint DEFAULT 99,
    idunidad smallint DEFAULT 1,
    activo boolean DEFAULT true NOT NULL
);
    DROP TABLE public.producto;
       public         postgres    false            �            1259    16494    producto_id_seq    SEQUENCE     �   CREATE SEQUENCE public.producto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.producto_id_seq;
       public       postgres    false    208            �           0    0    producto_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.producto_id_seq OWNED BY public.producto.idproducto;
            public       postgres    false    209            �            1259    16496    promociones    TABLE       CREATE TABLE public.promociones (
    id_promocion integer NOT NULL,
    idproducto integer NOT NULL,
    cantidad integer NOT NULL,
    tipo_descuento integer NOT NULL,
    descuento integer NOT NULL,
    activo boolean NOT NULL,
    descripcion_promo character varying(50) NOT NULL
);
    DROP TABLE public.promociones;
       public         postgres    false            �            1259    16499    promociones_id_promocion_seq    SEQUENCE     �   CREATE SEQUENCE public.promociones_id_promocion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.promociones_id_promocion_seq;
       public       postgres    false    210            �           0    0    promociones_id_promocion_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.promociones_id_promocion_seq OWNED BY public.promociones.id_promocion;
            public       postgres    false    211            �            1259    16501 
   tipo_gasto    TABLE     y   CREATE TABLE public.tipo_gasto (
    id_tipo_gasto integer NOT NULL,
    nombre_tipo_gasto character varying NOT NULL
);
    DROP TABLE public.tipo_gasto;
       public         postgres    false            �            1259    16507    tipo_gasto_id_tipo_gasto_seq    SEQUENCE     �   CREATE SEQUENCE public.tipo_gasto_id_tipo_gasto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.tipo_gasto_id_tipo_gasto_seq;
       public       postgres    false    212            �           0    0    tipo_gasto_id_tipo_gasto_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.tipo_gasto_id_tipo_gasto_seq OWNED BY public.tipo_gasto.id_tipo_gasto;
            public       postgres    false    213            �            1259    16509 	   tipo_pago    TABLE     {   CREATE TABLE public.tipo_pago (
    id_tipo_pago integer NOT NULL,
    nombre_tipo_pago character varying(100) NOT NULL
);
    DROP TABLE public.tipo_pago;
       public         postgres    false            �            1259    16512    tipo_pago_id_tipo_pago_seq    SEQUENCE     �   CREATE SEQUENCE public.tipo_pago_id_tipo_pago_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.tipo_pago_id_tipo_pago_seq;
       public       postgres    false    214            �           0    0    tipo_pago_id_tipo_pago_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.tipo_pago_id_tipo_pago_seq OWNED BY public.tipo_pago.id_tipo_pago;
            public       postgres    false    215            �            1259    16514    unidad    TABLE     �   CREATE TABLE public.unidad (
    idunidad smallint NOT NULL,
    nombreunidad character varying(30) NOT NULL,
    nombrelargo character varying
);
    DROP TABLE public.unidad;
       public         postgres    false            �            1259    16520    usuario    TABLE       CREATE TABLE public.usuario (
    id_usuario integer NOT NULL,
    nombre character varying(30) NOT NULL,
    usuario character varying(20) NOT NULL,
    password character varying NOT NULL,
    tipo_usuario character varying(10) NOT NULL,
    activo boolean DEFAULT true NOT NULL
);
    DROP TABLE public.usuario;
       public         postgres    false            �            1259    16527    usuario_Cod_usuario_seq    SEQUENCE     �   CREATE SEQUENCE public."usuario_Cod_usuario_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public."usuario_Cod_usuario_seq";
       public       postgres    false    217            �           0    0    usuario_Cod_usuario_seq    SEQUENCE OWNED BY     T   ALTER SEQUENCE public."usuario_Cod_usuario_seq" OWNED BY public.usuario.id_usuario;
            public       postgres    false    218            �            1259    16529    venta    TABLE     |  CREATE TABLE public.venta (
    id_venta integer NOT NULL,
    id_venta_temp integer NOT NULL,
    id_apertura integer NOT NULL,
    monto_venta integer NOT NULL,
    id_tipo_pago integer NOT NULL,
    id_usuario integer NOT NULL,
    time_creado timestamp without time zone NOT NULL,
    anulado boolean,
    id_usuario_d integer,
    time_anulado timestamp without time zone
);
    DROP TABLE public.venta;
       public         postgres    false            �            1259    16532    venta_detalle    TABLE     9  CREATE TABLE public.venta_detalle (
    id_detalle integer NOT NULL,
    id_venta_temp integer NOT NULL,
    idproducto integer NOT NULL,
    cantidad numeric(10,5) NOT NULL,
    id_usuario integer NOT NULL,
    "time" timestamp without time zone NOT NULL,
    monto integer NOT NULL,
    id_promocion integer
);
 !   DROP TABLE public.venta_detalle;
       public         postgres    false            �            1259    16535    venta_detalle_id_detalle_seq    SEQUENCE     �   CREATE SEQUENCE public.venta_detalle_id_detalle_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.venta_detalle_id_detalle_seq;
       public       postgres    false    220            �           0    0    venta_detalle_id_detalle_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.venta_detalle_id_detalle_seq OWNED BY public.venta_detalle.id_detalle;
            public       postgres    false    221            �            1259    16537    venta_id_venta_seq    SEQUENCE     �   CREATE SEQUENCE public.venta_id_venta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.venta_id_venta_seq;
       public       postgres    false    219            �           0    0    venta_id_venta_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE public.venta_id_venta_seq OWNED BY public.venta.id_venta;
            public       postgres    false    222            �            1259    16539    venta_temporal    TABLE     o  CREATE TABLE public.venta_temporal (
    id_venta_temp integer NOT NULL,
    id_diario integer NOT NULL,
    id_usuario integer NOT NULL,
    time_creado timestamp without time zone DEFAULT now() NOT NULL,
    pagado boolean,
    time_pagado timestamp without time zone,
    anulado boolean DEFAULT false,
    letra_id_diario character(1),
    id_apertura integer
);
 "   DROP TABLE public.venta_temporal;
       public         postgres    false            �            1259    16544    venta_temporal_id_diario_seq    SEQUENCE     �   CREATE SEQUENCE public.venta_temporal_id_diario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99
    CACHE 1
    CYCLE;
 3   DROP SEQUENCE public.venta_temporal_id_diario_seq;
       public       postgres    false    223            �           0    0    venta_temporal_id_diario_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.venta_temporal_id_diario_seq OWNED BY public.venta_temporal.id_diario;
            public       postgres    false    224            �            1259    16546     venta_temporal_id_venta_temp_seq    SEQUENCE     �   CREATE SEQUENCE public.venta_temporal_id_venta_temp_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 7   DROP SEQUENCE public.venta_temporal_id_venta_temp_seq;
       public       postgres    false    223            �           0    0     venta_temporal_id_venta_temp_seq    SEQUENCE OWNED BY     e   ALTER SEQUENCE public.venta_temporal_id_venta_temp_seq OWNED BY public.venta_temporal.id_venta_temp;
            public       postgres    false    225            �            1259    16548    vw_custodia    VIEW     �   CREATE VIEW public.vw_custodia AS
 SELECT dinero_custodia.id_dinero_custodia AS id_custodia,
    dinero_custodia.nombre
   FROM public.dinero_custodia
  WHERE (dinero_custodia.eliminado IS NOT TRUE);
    DROP VIEW public.vw_custodia;
       public       postgres    false    201    201    201            �            1259    16552    vw_datos_apertura    VIEW     1  CREATE VIEW public.vw_datos_apertura AS
 SELECT ca.id_apertura,
    ca.fecha,
    ca.efectivo,
    ca.time_creado,
    ca.cerrado,
    ca.id_usuario,
    u.nombre AS usuario
   FROM (public.caja_apertura ca
     JOIN public.usuario u ON ((ca.id_usuario = u.id_usuario)))
  WHERE (ca.cerrado IS NOT TRUE);
 $   DROP VIEW public.vw_datos_apertura;
       public       postgres    false    196    196    196    196    217    217    196    196            �            1259    16556    vw_detalle_venta_temp    VIEW     �  CREATE VIEW public.vw_detalle_venta_temp AS
 SELECT vd.id_detalle,
    vd.id_venta_temp,
    p.codigodebarras AS codigo,
    p.nombreproducto AS nombre,
    p.precio,
    vd.cantidad,
    vd.monto,
    p.idproducto,
    u.nombreunidad AS unidad,
    p.idunidad,
    vd.id_promocion AS idpromocion,
    (((vt.letra_id_diario)::text || '-'::text) || vt.id_diario) AS id_diario,
    vt.pagado,
    vt.anulado
   FROM (((public.producto p
     JOIN public.venta_detalle vd ON ((p.idproducto = vd.idproducto)))
     JOIN public.unidad u ON ((u.idunidad = p.idunidad)))
     JOIN public.venta_temporal vt ON ((vd.id_venta_temp = vt.id_venta_temp)));
 (   DROP VIEW public.vw_detalle_venta_temp;
       public       postgres    false    208    223    223    223    223    223    220    220    220    220    220    216    220    208    208    208    208    216            �            1259    16561    vw_dinero_custodia_movimientos    VIEW     �  CREATE VIEW public.vw_dinero_custodia_movimientos AS
 SELECT dcm.id_movimiento,
    dc.id_dinero_custodia,
    dc.nombre AS nombre_custodia,
    dcm.monto AS monto_movimiento,
    dcm.comentario,
    dcm.id_usuario_i AS id_usuario,
    u.nombre AS nombre_usuario,
    to_char(dcm.time_creado, 'DD-MM-YYYY'::text) AS fecha_movimiento,
    to_char(dcm.time_creado, 'HH24:MI:SS'::text) AS hora_movimiento,
    dcm.eliminado,
    dcm.gasto
   FROM ((public.dinero_custodia_movimientos dcm
     JOIN public.usuario u ON ((dcm.id_usuario_i = u.id_usuario)))
     RIGHT JOIN public.dinero_custodia dc ON ((dcm.id_dinero_custodia = dc.id_dinero_custodia)));
 1   DROP VIEW public.vw_dinero_custodia_movimientos;
       public       postgres    false    217    217    203    203    203    203    203    201    203    203    203    201            �            1259    16566    vw_dinero_en_custodia    VIEW     h  CREATE VIEW public.vw_dinero_en_custodia AS
 SELECT dc.id_dinero_custodia,
    dc.nombre AS nombre_dinero_en_custodia,
    ( SELECT COALESCE(sum(dinero_custodia_movimientos.monto), (0)::bigint) AS sum
           FROM public.dinero_custodia_movimientos
          WHERE ((dinero_custodia_movimientos.eliminado IS NOT TRUE) AND (dinero_custodia_movimientos.id_dinero_custodia = dc.id_dinero_custodia))) AS saldo,
    dc.id_usuario_i AS id_usuario,
    u.nombre AS nombre_usuario,
    dc.time_creado,
    dc.eliminado
   FROM (public.dinero_custodia dc
     JOIN public.usuario u ON ((dc.id_usuario_i = u.id_usuario)));
 (   DROP VIEW public.vw_dinero_en_custodia;
       public       postgres    false    201    217    217    203    203    203    201    201    201    201            �            1259    16571    vw_efectivo_apertura    VIEW     �   CREATE VIEW public.vw_efectivo_apertura AS
 SELECT caja_apertura.id_apertura,
    caja_apertura.efectivo
   FROM public.caja_apertura
  WHERE (caja_apertura.cerrado IS NOT TRUE);
 '   DROP VIEW public.vw_efectivo_apertura;
       public       postgres    false    196    196    196            �            1259    16575 	   vw_gastos    VIEW     /  CREATE VIEW public.vw_gastos AS
 SELECT gc.id_apertura,
    gc.id_gasto,
    gc.id_tipo_gasto,
    gc.descripcion,
    gc.monto,
    gc.dinero_en_custodia,
    gc.id_dinero_custodia,
    u.usuario AS username_ingreso,
    u.nombre AS usuario_ingreso,
    gc.eliminado,
    to_char((gc.time_creado)::timestamp with time zone, 'DD-MM-YYYY'::text) AS fecha,
    to_char(gc.time_creado, 'HH24:MI:SS'::text) AS hora,
    gc.id_movimiento_custodia AS id_mov_custodia
   FROM (public.gastos_caja gc
     JOIN public.usuario u ON ((gc.id_usuario_i = u.id_usuario)));
    DROP VIEW public.vw_gastos;
       public       postgres    false    205    205    217    217    217    205    205    205    205    205    205    205    205    205            �            1259    16580    vw_total_gastos    VIEW     �   CREATE VIEW public.vw_total_gastos AS
 SELECT gastos_caja.id_apertura,
    sum(gastos_caja.monto) AS total_gastos
   FROM public.gastos_caja
  WHERE (gastos_caja.eliminado IS NOT TRUE)
  GROUP BY gastos_caja.id_apertura, gastos_caja.eliminado;
 "   DROP VIEW public.vw_total_gastos;
       public       postgres    false    205    205    205            �            1259    16584 	   vw_ventas    VIEW     �  CREATE VIEW public.vw_ventas AS
 SELECT v.id_venta,
    v.id_venta_temp,
    vt.id_diario,
    v.id_apertura,
    ca.fecha,
    to_char((ca.fecha)::timestamp with time zone, 'DD-MM-YYYY'::text) AS fecha2,
    v.monto_venta,
    tp.id_tipo_pago,
    tp.nombre_tipo_pago,
    vt.id_usuario AS id_usuario_venta_temp,
    um.nombre AS nombre_usuario_venta_temp,
    to_char(vt.time_creado, 'HH24:MI:SS'::text) AS hora_venta_temp,
    v.id_usuario AS id_usuario_pago,
    uv.nombre AS nombre_usuario_pago,
    to_char(v.time_creado, 'HH24:MI:SS'::text) AS hora_pago
   FROM (((((public.venta v
     JOIN public.venta_temporal vt ON ((v.id_venta_temp = vt.id_venta_temp)))
     JOIN public.tipo_pago tp ON ((v.id_tipo_pago = tp.id_tipo_pago)))
     JOIN public.usuario uv ON ((v.id_usuario = uv.id_usuario)))
     JOIN public.usuario um ON ((vt.id_usuario = um.id_usuario)))
     JOIN public.caja_apertura ca ON ((v.id_apertura = ca.id_apertura)));
    DROP VIEW public.vw_ventas;
       public       postgres    false    214    196    223    223    223    223    219    219    219    219    219    219    219    217    217    214    196            �            1259    16589 
   vw_ventas2    VIEW     �  CREATE VIEW public.vw_ventas2 AS
 SELECT v.id_venta,
    v.id_venta_temp,
    (((vt.letra_id_diario)::text || '-'::text) || vt.id_diario) AS id_diario,
    v.id_apertura,
    ca.fecha,
    to_char((ca.fecha)::timestamp with time zone, 'DD-MM-YYYY'::text) AS fecha2,
    v.monto_venta,
    tp.id_tipo_pago,
    tp.nombre_tipo_pago,
    vt.id_usuario AS id_usuario_venta_temp,
    um.nombre AS nombre_usuario_venta_temp,
    to_char(vt.time_creado, 'HH24:MI:SS'::text) AS hora_venta_temp,
    v.id_usuario AS id_usuario_pago,
    uv.nombre AS nombre_usuario_pago,
    to_char(v.time_creado, 'HH24:MI:SS'::text) AS hora_pago,
    v.anulado,
    v.id_usuario_d,
    ud.nombre AS nombre_usuario_d,
    to_char(v.time_anulado, 'DD-MM-YYYY'::text) AS fecha_anulado,
    to_char(v.time_anulado, 'HH24:MI:SS'::text) AS hora_anulado
   FROM ((((((public.venta v
     JOIN public.venta_temporal vt ON ((v.id_venta_temp = vt.id_venta_temp)))
     JOIN public.tipo_pago tp ON ((v.id_tipo_pago = tp.id_tipo_pago)))
     JOIN public.usuario uv ON ((v.id_usuario = uv.id_usuario)))
     JOIN public.usuario um ON ((vt.id_usuario = um.id_usuario)))
     JOIN public.caja_apertura ca ON ((v.id_apertura = ca.id_apertura)))
     LEFT JOIN public.usuario ud ON ((v.id_usuario_d = ud.id_usuario)));
    DROP VIEW public.vw_ventas2;
       public       postgres    false    196    196    219    223    223    223    219    219    219    219    219    214    223    214    217    217    219    219    223    219    219            �            1259    16594    vw_ventas_temporales_anuladas    VIEW     (  CREATE VIEW public.vw_ventas_temporales_anuladas AS
SELECT
    NULL::integer AS id_venta_temp,
    NULL::text AS id_diario,
    NULL::integer AS id_usuario,
    NULL::character varying(30) AS nombre_usuario,
    NULL::text AS time_creado,
    NULL::boolean AS anulado,
    NULL::bigint AS total;
 0   DROP VIEW public.vw_ventas_temporales_anuladas;
       public       postgres    false            �            1259    16598    vw_ventas_temporales_anuladas2    VIEW     d  CREATE VIEW public.vw_ventas_temporales_anuladas2 AS
SELECT
    NULL::integer AS id_venta_temp,
    NULL::text AS id_diario,
    NULL::integer AS id_usuario,
    NULL::character varying(30) AS nombre_usuario,
    NULL::text AS time_creado,
    NULL::boolean AS anulado,
    NULL::bigint AS total,
    NULL::integer AS id_apertura,
    NULL::text AS fecha;
 1   DROP VIEW public.vw_ventas_temporales_anuladas2;
       public       postgres    false            �            1259    16602    vw_ventas_temporales_impagas    VIEW     j  CREATE VIEW public.vw_ventas_temporales_impagas AS
 SELECT venta_temporal.id_venta_temp,
    venta_temporal.id_diario,
    venta_temporal.anulado
   FROM public.venta_temporal
  WHERE ((venta_temporal.pagado IS NOT TRUE) AND (venta_temporal.time_creado >= CURRENT_DATE) AND (venta_temporal.time_creado < (CURRENT_DATE + 1)))
  ORDER BY venta_temporal.id_diario;
 /   DROP VIEW public.vw_ventas_temporales_impagas;
       public       postgres    false    223    223    223    223    223            �            1259    16606    vw_ventas_temporales_impagas2    VIEW     �  CREATE VIEW public.vw_ventas_temporales_impagas2 AS
 SELECT venta_temporal.id_venta_temp,
    (((venta_temporal.letra_id_diario)::text || '-'::text) || venta_temporal.id_diario) AS id_diario,
    venta_temporal.anulado
   FROM public.venta_temporal
  WHERE ((venta_temporal.pagado IS NOT TRUE) AND (venta_temporal.id_apertura = ( SELECT caja_apertura.id_apertura
           FROM public.caja_apertura
          WHERE (caja_apertura.cerrado IS NOT TRUE))))
  ORDER BY venta_temporal.id_venta_temp;
 0   DROP VIEW public.vw_ventas_temporales_impagas2;
       public       postgres    false    223    223    223    223    223    223    196    196            �            1259    16610    vw_ventas_totales    VIEW     �   CREATE VIEW public.vw_ventas_totales AS
 SELECT venta.id_apertura,
    venta.id_tipo_pago,
    sum(venta.monto_venta) AS total_ventas
   FROM public.venta
  GROUP BY venta.id_apertura, venta.id_tipo_pago;
 $   DROP VIEW public.vw_ventas_totales;
       public       postgres    false    219    219    219            �           2604    16614    caja_apertura id_apertura    DEFAULT     �   ALTER TABLE ONLY public.caja_apertura ALTER COLUMN id_apertura SET DEFAULT nextval('public.caja_apertura_id_apertura_seq'::regclass);
 H   ALTER TABLE public.caja_apertura ALTER COLUMN id_apertura DROP DEFAULT;
       public       postgres    false    197    196            �           2604    16615    caja_cierre id_cierre    DEFAULT     ~   ALTER TABLE ONLY public.caja_cierre ALTER COLUMN id_cierre SET DEFAULT nextval('public.caja_cierre_id_cierre_seq'::regclass);
 D   ALTER TABLE public.caja_cierre ALTER COLUMN id_cierre DROP DEFAULT;
       public       postgres    false    199    198            �           2604    16616 "   dinero_custodia id_dinero_custodia    DEFAULT     �   ALTER TABLE ONLY public.dinero_custodia ALTER COLUMN id_dinero_custodia SET DEFAULT nextval('public.dinero_custodia_id_dinero_custodia_seq'::regclass);
 Q   ALTER TABLE public.dinero_custodia ALTER COLUMN id_dinero_custodia DROP DEFAULT;
       public       postgres    false    202    201            �           2604    16617 )   dinero_custodia_movimientos id_movimiento    DEFAULT     �   ALTER TABLE ONLY public.dinero_custodia_movimientos ALTER COLUMN id_movimiento SET DEFAULT nextval('public.dinero_custodia_movimientos_id_movimiento_seq'::regclass);
 X   ALTER TABLE public.dinero_custodia_movimientos ALTER COLUMN id_movimiento DROP DEFAULT;
       public       postgres    false    204    203            �           2604    16618    gastos_caja id_gasto    DEFAULT     |   ALTER TABLE ONLY public.gastos_caja ALTER COLUMN id_gasto SET DEFAULT nextval('public.gastos_caja_id_gasto_seq'::regclass);
 C   ALTER TABLE public.gastos_caja ALTER COLUMN id_gasto DROP DEFAULT;
       public       postgres    false    206    205            �           2604    16619    producto idproducto    DEFAULT     r   ALTER TABLE ONLY public.producto ALTER COLUMN idproducto SET DEFAULT nextval('public.producto_id_seq'::regclass);
 B   ALTER TABLE public.producto ALTER COLUMN idproducto DROP DEFAULT;
       public       postgres    false    209    208            �           2604    16620    promociones id_promocion    DEFAULT     �   ALTER TABLE ONLY public.promociones ALTER COLUMN id_promocion SET DEFAULT nextval('public.promociones_id_promocion_seq'::regclass);
 G   ALTER TABLE public.promociones ALTER COLUMN id_promocion DROP DEFAULT;
       public       postgres    false    211    210            �           2604    16621    tipo_gasto id_tipo_gasto    DEFAULT     �   ALTER TABLE ONLY public.tipo_gasto ALTER COLUMN id_tipo_gasto SET DEFAULT nextval('public.tipo_gasto_id_tipo_gasto_seq'::regclass);
 G   ALTER TABLE public.tipo_gasto ALTER COLUMN id_tipo_gasto DROP DEFAULT;
       public       postgres    false    213    212            �           2604    16622    tipo_pago id_tipo_pago    DEFAULT     �   ALTER TABLE ONLY public.tipo_pago ALTER COLUMN id_tipo_pago SET DEFAULT nextval('public.tipo_pago_id_tipo_pago_seq'::regclass);
 E   ALTER TABLE public.tipo_pago ALTER COLUMN id_tipo_pago DROP DEFAULT;
       public       postgres    false    215    214            �           2604    16623    usuario id_usuario    DEFAULT     {   ALTER TABLE ONLY public.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('public."usuario_Cod_usuario_seq"'::regclass);
 A   ALTER TABLE public.usuario ALTER COLUMN id_usuario DROP DEFAULT;
       public       postgres    false    218    217            �           2604    16624    venta id_venta    DEFAULT     p   ALTER TABLE ONLY public.venta ALTER COLUMN id_venta SET DEFAULT nextval('public.venta_id_venta_seq'::regclass);
 =   ALTER TABLE public.venta ALTER COLUMN id_venta DROP DEFAULT;
       public       postgres    false    222    219            �           2604    16625    venta_detalle id_detalle    DEFAULT     �   ALTER TABLE ONLY public.venta_detalle ALTER COLUMN id_detalle SET DEFAULT nextval('public.venta_detalle_id_detalle_seq'::regclass);
 G   ALTER TABLE public.venta_detalle ALTER COLUMN id_detalle DROP DEFAULT;
       public       postgres    false    221    220            �           2604    16626    venta_temporal id_venta_temp    DEFAULT     �   ALTER TABLE ONLY public.venta_temporal ALTER COLUMN id_venta_temp SET DEFAULT nextval('public.venta_temporal_id_venta_temp_seq'::regclass);
 K   ALTER TABLE public.venta_temporal ALTER COLUMN id_venta_temp DROP DEFAULT;
       public       postgres    false    225    223            �           2604    16627    venta_temporal id_diario    DEFAULT     �   ALTER TABLE ONLY public.venta_temporal ALTER COLUMN id_diario SET DEFAULT nextval('public.venta_temporal_id_diario_seq'::regclass);
 G   ALTER TABLE public.venta_temporal ALTER COLUMN id_diario DROP DEFAULT;
       public       postgres    false    224    223            ~          0    16442    caja_apertura 
   TABLE DATA               g   COPY public.caja_apertura (id_apertura, fecha, efectivo, id_usuario, time_creado, cerrado) FROM stdin;
    public       postgres    false    196   [      �          0    16447    caja_cierre 
   TABLE DATA               �   COPY public.caja_cierre (id_cierre, id_apertura, efectivo_apertura, efectivo_cierre, ventas_efectivo, ventas_tarjetas, entrega, gastos, id_usuario, time_cierre, id_usuario_autoriza) FROM stdin;
    public       postgres    false    198   2[      �          0    16452 	   categoria 
   TABLE DATA               A   COPY public.categoria (idcategoria, nombrecategoria) FROM stdin;
    public       postgres    false    200   O[      �          0    16455    dinero_custodia 
   TABLE DATA               �   COPY public.dinero_custodia (id_dinero_custodia, nombre, id_usuario_i, time_creado, eliminado, id_usuario_d, time_eliminado) FROM stdin;
    public       postgres    false    201   �[      �          0    16463    dinero_custodia_movimientos 
   TABLE DATA               �   COPY public.dinero_custodia_movimientos (id_movimiento, id_dinero_custodia, monto, comentario, id_usuario_i, time_creado, eliminado, id_usuario_d, time_eliminado, gasto) FROM stdin;
    public       postgres    false    203   \      �          0    16471    gastos_caja 
   TABLE DATA               �   COPY public.gastos_caja (id_gasto, id_apertura, id_tipo_gasto, descripcion, monto, dinero_en_custodia, id_dinero_custodia, id_usuario_i, time_creado, eliminado, id_usuario_d, time_eliminado, id_movimiento_custodia) FROM stdin;
    public       postgres    false    205   ,\      �          0    16479    perfiles_usuario 
   TABLE DATA               �   COPY public.perfiles_usuario (tipo_usuario, caja, meson, mantenedor_productos, mantenedor_usuarios, tipo_usuario_completo) FROM stdin;
    public       postgres    false    207   I\      �          0    16485    producto 
   TABLE DATA               }   COPY public.producto (idproducto, nombreproducto, codigodebarras, precio, imagen, idcategoria, idunidad, activo) FROM stdin;
    public       postgres    false    208   �\      �          0    16496    promociones 
   TABLE DATA                  COPY public.promociones (id_promocion, idproducto, cantidad, tipo_descuento, descuento, activo, descripcion_promo) FROM stdin;
    public       postgres    false    210   �\      �          0    16501 
   tipo_gasto 
   TABLE DATA               F   COPY public.tipo_gasto (id_tipo_gasto, nombre_tipo_gasto) FROM stdin;
    public       postgres    false    212   ]      �          0    16509 	   tipo_pago 
   TABLE DATA               C   COPY public.tipo_pago (id_tipo_pago, nombre_tipo_pago) FROM stdin;
    public       postgres    false    214   G]      �          0    16514    unidad 
   TABLE DATA               E   COPY public.unidad (idunidad, nombreunidad, nombrelargo) FROM stdin;
    public       postgres    false    216   y]      �          0    16520    usuario 
   TABLE DATA               ^   COPY public.usuario (id_usuario, nombre, usuario, password, tipo_usuario, activo) FROM stdin;
    public       postgres    false    217   �]      �          0    16529    venta 
   TABLE DATA               �   COPY public.venta (id_venta, id_venta_temp, id_apertura, monto_venta, id_tipo_pago, id_usuario, time_creado, anulado, id_usuario_d, time_anulado) FROM stdin;
    public       postgres    false    219   ^      �          0    16532    venta_detalle 
   TABLE DATA               �   COPY public.venta_detalle (id_detalle, id_venta_temp, idproducto, cantidad, id_usuario, "time", monto, id_promocion) FROM stdin;
    public       postgres    false    220   .^      �          0    16539    venta_temporal 
   TABLE DATA               �   COPY public.venta_temporal (id_venta_temp, id_diario, id_usuario, time_creado, pagado, time_pagado, anulado, letra_id_diario, id_apertura) FROM stdin;
    public       postgres    false    223   K^      �           0    0    caja_apertura_id_apertura_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.caja_apertura_id_apertura_seq', 1, false);
            public       postgres    false    197            �           0    0    caja_cierre_id_cierre_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.caja_cierre_id_cierre_seq', 1, false);
            public       postgres    false    199            �           0    0 &   dinero_custodia_id_dinero_custodia_seq    SEQUENCE SET     U   SELECT pg_catalog.setval('public.dinero_custodia_id_dinero_custodia_seq', 1, false);
            public       postgres    false    202            �           0    0 -   dinero_custodia_movimientos_id_movimiento_seq    SEQUENCE SET     \   SELECT pg_catalog.setval('public.dinero_custodia_movimientos_id_movimiento_seq', 1, false);
            public       postgres    false    204            �           0    0    gastos_caja_id_gasto_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.gastos_caja_id_gasto_seq', 1, false);
            public       postgres    false    206            �           0    0    producto_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.producto_id_seq', 1, false);
            public       postgres    false    209            �           0    0    promociones_id_promocion_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.promociones_id_promocion_seq', 1, false);
            public       postgres    false    211            �           0    0    tipo_gasto_id_tipo_gasto_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.tipo_gasto_id_tipo_gasto_seq', 1, false);
            public       postgres    false    213            �           0    0    tipo_pago_id_tipo_pago_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.tipo_pago_id_tipo_pago_seq', 1, false);
            public       postgres    false    215            �           0    0    usuario_Cod_usuario_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public."usuario_Cod_usuario_seq"', 1, false);
            public       postgres    false    218            �           0    0    venta_detalle_id_detalle_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.venta_detalle_id_detalle_seq', 1, false);
            public       postgres    false    221            �           0    0    venta_id_venta_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.venta_id_venta_seq', 1, false);
            public       postgres    false    222            �           0    0    venta_temporal_id_diario_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.venta_temporal_id_diario_seq', 1, false);
            public       postgres    false    224            �           0    0     venta_temporal_id_venta_temp_seq    SEQUENCE SET     O   SELECT pg_catalog.setval('public.venta_temporal_id_venta_temp_seq', 1, false);
            public       postgres    false    225            �           2606    16629    caja_apertura caja_apertura_pk 
   CONSTRAINT     e   ALTER TABLE ONLY public.caja_apertura
    ADD CONSTRAINT caja_apertura_pk PRIMARY KEY (id_apertura);
 H   ALTER TABLE ONLY public.caja_apertura DROP CONSTRAINT caja_apertura_pk;
       public         postgres    false    196            �           2606    16631    caja_cierre caja_cierre_pk 
   CONSTRAINT     _   ALTER TABLE ONLY public.caja_cierre
    ADD CONSTRAINT caja_cierre_pk PRIMARY KEY (id_cierre);
 D   ALTER TABLE ONLY public.caja_cierre DROP CONSTRAINT caja_cierre_pk;
       public         postgres    false    198            �           2606    16633    categoria categoria_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (idcategoria);
 B   ALTER TABLE ONLY public.categoria DROP CONSTRAINT categoria_pkey;
       public         postgres    false    200            �           2606    16635 3   dinero_custodia_movimientos dinero_custodia_movi_pk 
   CONSTRAINT     |   ALTER TABLE ONLY public.dinero_custodia_movimientos
    ADD CONSTRAINT dinero_custodia_movi_pk PRIMARY KEY (id_movimiento);
 ]   ALTER TABLE ONLY public.dinero_custodia_movimientos DROP CONSTRAINT dinero_custodia_movi_pk;
       public         postgres    false    203            �           2606    16637 "   dinero_custodia dinero_custodia_pk 
   CONSTRAINT     p   ALTER TABLE ONLY public.dinero_custodia
    ADD CONSTRAINT dinero_custodia_pk PRIMARY KEY (id_dinero_custodia);
 L   ALTER TABLE ONLY public.dinero_custodia DROP CONSTRAINT dinero_custodia_pk;
       public         postgres    false    201            �           2606    16639    gastos_caja gastos_caja_pk 
   CONSTRAINT     ^   ALTER TABLE ONLY public.gastos_caja
    ADD CONSTRAINT gastos_caja_pk PRIMARY KEY (id_gasto);
 D   ALTER TABLE ONLY public.gastos_caja DROP CONSTRAINT gastos_caja_pk;
       public         postgres    false    205            �           2606    16641 &   perfiles_usuario perfiles_usuario_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY public.perfiles_usuario
    ADD CONSTRAINT perfiles_usuario_pkey PRIMARY KEY (tipo_usuario);
 P   ALTER TABLE ONLY public.perfiles_usuario DROP CONSTRAINT perfiles_usuario_pkey;
       public         postgres    false    207            �           2606    16643 $   producto producto_codigodebarras_key 
   CONSTRAINT     i   ALTER TABLE ONLY public.producto
    ADD CONSTRAINT producto_codigodebarras_key UNIQUE (codigodebarras);
 N   ALTER TABLE ONLY public.producto DROP CONSTRAINT producto_codigodebarras_key;
       public         postgres    false    208            �           2606    16645    producto producto_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.producto
    ADD CONSTRAINT producto_pkey PRIMARY KEY (idproducto);
 @   ALTER TABLE ONLY public.producto DROP CONSTRAINT producto_pkey;
       public         postgres    false    208            �           2606    16647    promociones promociones_pk 
   CONSTRAINT     b   ALTER TABLE ONLY public.promociones
    ADD CONSTRAINT promociones_pk PRIMARY KEY (id_promocion);
 D   ALTER TABLE ONLY public.promociones DROP CONSTRAINT promociones_pk;
       public         postgres    false    210            �           2606    16649    tipo_gasto tipo_gasto_pk 
   CONSTRAINT     a   ALTER TABLE ONLY public.tipo_gasto
    ADD CONSTRAINT tipo_gasto_pk PRIMARY KEY (id_tipo_gasto);
 B   ALTER TABLE ONLY public.tipo_gasto DROP CONSTRAINT tipo_gasto_pk;
       public         postgres    false    212            �           2606    16651    tipo_pago tipo_pago_pk 
   CONSTRAINT     ^   ALTER TABLE ONLY public.tipo_pago
    ADD CONSTRAINT tipo_pago_pk PRIMARY KEY (id_tipo_pago);
 @   ALTER TABLE ONLY public.tipo_pago DROP CONSTRAINT tipo_pago_pk;
       public         postgres    false    214            �           2606    16653    unidad unidad_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.unidad
    ADD CONSTRAINT unidad_pkey PRIMARY KEY (idunidad);
 <   ALTER TABLE ONLY public.unidad DROP CONSTRAINT unidad_pkey;
       public         postgres    false    216            �           2606    16655    usuario usuario_User_key 
   CONSTRAINT     X   ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT "usuario_User_key" UNIQUE (usuario);
 D   ALTER TABLE ONLY public.usuario DROP CONSTRAINT "usuario_User_key";
       public         postgres    false    217            �           2606    16658    usuario usuario_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);
 >   ALTER TABLE ONLY public.usuario DROP CONSTRAINT usuario_pkey;
       public         postgres    false    217            �           2606    16660    venta_detalle venta_detalle_pk 
   CONSTRAINT     d   ALTER TABLE ONLY public.venta_detalle
    ADD CONSTRAINT venta_detalle_pk PRIMARY KEY (id_detalle);
 H   ALTER TABLE ONLY public.venta_detalle DROP CONSTRAINT venta_detalle_pk;
       public         postgres    false    220            �           2606    16662    venta venta_pk 
   CONSTRAINT     R   ALTER TABLE ONLY public.venta
    ADD CONSTRAINT venta_pk PRIMARY KEY (id_venta);
 8   ALTER TABLE ONLY public.venta DROP CONSTRAINT venta_pk;
       public         postgres    false    219            �           2606    16664     venta_temporal venta_temporal_pk 
   CONSTRAINT     i   ALTER TABLE ONLY public.venta_temporal
    ADD CONSTRAINT venta_temporal_pk PRIMARY KEY (id_venta_temp);
 J   ALTER TABLE ONLY public.venta_temporal DROP CONSTRAINT venta_temporal_pk;
       public         postgres    false    223            y           2618    16597 %   vw_ventas_temporales_anuladas _RETURN    RULE     f  CREATE OR REPLACE VIEW public.vw_ventas_temporales_anuladas AS
 SELECT venta_temporal.id_venta_temp,
    (((venta_temporal.letra_id_diario)::text || '-'::text) || venta_temporal.id_diario) AS id_diario,
    venta_temporal.id_usuario,
    usuario.nombre AS nombre_usuario,
    to_char(venta_temporal.time_creado, 'HH24:MI:SS'::text) AS time_creado,
    venta_temporal.anulado,
    sum(venta_detalle.monto) AS total
   FROM ((public.venta_temporal
     JOIN public.usuario ON ((venta_temporal.id_usuario = usuario.id_usuario)))
     JOIN public.venta_detalle ON ((venta_temporal.id_venta_temp = venta_detalle.id_venta_temp)))
  WHERE ((venta_temporal.pagado IS NOT TRUE) AND (venta_temporal.time_creado >= CURRENT_DATE) AND (venta_temporal.time_creado < (CURRENT_DATE + 1)))
  GROUP BY venta_temporal.id_venta_temp, usuario.nombre
  ORDER BY venta_temporal.id_venta_temp;
 3  CREATE OR REPLACE VIEW public.vw_ventas_temporales_anuladas AS
SELECT
    NULL::integer AS id_venta_temp,
    NULL::text AS id_diario,
    NULL::integer AS id_usuario,
    NULL::character varying(30) AS nombre_usuario,
    NULL::text AS time_creado,
    NULL::boolean AS anulado,
    NULL::bigint AS total;
       public       postgres    false    223    217    217    220    220    223    223    223    223    223    223    3036    236            z           2618    16601 &   vw_ventas_temporales_anuladas2 _RETURN    RULE     d  CREATE OR REPLACE VIEW public.vw_ventas_temporales_anuladas2 AS
 SELECT venta_temporal.id_venta_temp,
    (((venta_temporal.letra_id_diario)::text || '-'::text) || venta_temporal.id_diario) AS id_diario,
    venta_temporal.id_usuario,
    usuario.nombre AS nombre_usuario,
    to_char(venta_temporal.time_creado, 'HH24:MI:SS'::text) AS time_creado,
    venta_temporal.anulado,
    sum(venta_detalle.monto) AS total,
    venta_temporal.id_apertura,
    to_char(venta_temporal.time_creado, 'DD-MM-YYYY'::text) AS fecha
   FROM ((public.venta_temporal
     JOIN public.usuario ON ((venta_temporal.id_usuario = usuario.id_usuario)))
     JOIN public.venta_detalle ON ((venta_temporal.id_venta_temp = venta_detalle.id_venta_temp)))
  WHERE (venta_temporal.pagado IS NOT TRUE)
  GROUP BY venta_temporal.id_venta_temp, usuario.nombre
  ORDER BY venta_temporal.id_venta_temp;
 o  CREATE OR REPLACE VIEW public.vw_ventas_temporales_anuladas2 AS
SELECT
    NULL::integer AS id_venta_temp,
    NULL::text AS id_diario,
    NULL::integer AS id_usuario,
    NULL::character varying(30) AS nombre_usuario,
    NULL::text AS time_creado,
    NULL::boolean AS anulado,
    NULL::bigint AS total,
    NULL::integer AS id_apertura,
    NULL::text AS fecha;
       public       postgres    false    223    220    223    223    223    220    223    223    3036    223    223    217    217    237            �           2606    16667 $   caja_cierre caja_apert_caja_cierr_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.caja_cierre
    ADD CONSTRAINT caja_apert_caja_cierr_fk FOREIGN KEY (id_apertura) REFERENCES public.caja_apertura(id_apertura);
 N   ALTER TABLE ONLY public.caja_cierre DROP CONSTRAINT caja_apert_caja_cierr_fk;
       public       postgres    false    198    3002    196            �           2606    16672 $   gastos_caja caja_apert_gastos_caj_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.gastos_caja
    ADD CONSTRAINT caja_apert_gastos_caj_fk FOREIGN KEY (id_apertura) REFERENCES public.caja_apertura(id_apertura);
 N   ALTER TABLE ONLY public.gastos_caja DROP CONSTRAINT caja_apert_gastos_caj_fk;
       public       postgres    false    205    196    3002            �           2606    16677    venta caja_apertura_venta_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.venta
    ADD CONSTRAINT caja_apertura_venta_fk FOREIGN KEY (id_apertura) REFERENCES public.caja_apertura(id_apertura);
 F   ALTER TABLE ONLY public.venta DROP CONSTRAINT caja_apertura_venta_fk;
       public       postgres    false    3002    196    219            �           2606    16682    producto categoria_producto_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.producto
    ADD CONSTRAINT categoria_producto_fk FOREIGN KEY (idcategoria) REFERENCES public.categoria(idcategoria);
 H   ALTER TABLE ONLY public.producto DROP CONSTRAINT categoria_producto_fk;
       public       postgres    false    208    200    3006            �           2606    16687 4   dinero_custodia_movimientos dinero_cus_dinero_cus_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.dinero_custodia_movimientos
    ADD CONSTRAINT dinero_cus_dinero_cus_fk FOREIGN KEY (id_dinero_custodia) REFERENCES public.dinero_custodia(id_dinero_custodia);
 ^   ALTER TABLE ONLY public.dinero_custodia_movimientos DROP CONSTRAINT dinero_cus_dinero_cus_fk;
       public       postgres    false    201    203    3008            �           2606    16692 $   gastos_caja dinero_cus_gastos_caj_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.gastos_caja
    ADD CONSTRAINT dinero_cus_gastos_caj_fk FOREIGN KEY (id_dinero_custodia) REFERENCES public.dinero_custodia(id_dinero_custodia);
 N   ALTER TABLE ONLY public.gastos_caja DROP CONSTRAINT dinero_cus_gastos_caj_fk;
       public       postgres    false    205    3008    201            �           2606    16697 #   promociones producto_promociones_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.promociones
    ADD CONSTRAINT producto_promociones_fk FOREIGN KEY (idproducto) REFERENCES public.producto(idproducto);
 M   ALTER TABLE ONLY public.promociones DROP CONSTRAINT producto_promociones_fk;
       public       postgres    false    3018    208    210            �           2606    16702 '   venta_detalle producto_venta_detalle_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.venta_detalle
    ADD CONSTRAINT producto_venta_detalle_fk FOREIGN KEY (idproducto) REFERENCES public.producto(idproducto);
 Q   ALTER TABLE ONLY public.venta_detalle DROP CONSTRAINT producto_venta_detalle_fk;
       public       postgres    false    208    220    3018            �           2606    16707 (   venta_detalle promocion_venta_detalle_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.venta_detalle
    ADD CONSTRAINT promocion_venta_detalle_fk FOREIGN KEY (id_promocion) REFERENCES public.promociones(id_promocion);
 R   ALTER TABLE ONLY public.venta_detalle DROP CONSTRAINT promocion_venta_detalle_fk;
       public       postgres    false    220    3020    210            �           2606    16712 %   gastos_caja tipo_gasto_gastos_caja_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.gastos_caja
    ADD CONSTRAINT tipo_gasto_gastos_caja_fk FOREIGN KEY (id_tipo_gasto) REFERENCES public.tipo_gasto(id_tipo_gasto);
 O   ALTER TABLE ONLY public.gastos_caja DROP CONSTRAINT tipo_gasto_gastos_caja_fk;
       public       postgres    false    205    212    3022            �           2606    16717    venta tipo_pago_venta_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.venta
    ADD CONSTRAINT tipo_pago_venta_fk FOREIGN KEY (id_tipo_pago) REFERENCES public.tipo_pago(id_tipo_pago);
 B   ALTER TABLE ONLY public.venta DROP CONSTRAINT tipo_pago_venta_fk;
       public       postgres    false    214    219    3024            �           2606    16722 &   caja_apertura usuario_caja_apertura_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.caja_apertura
    ADD CONSTRAINT usuario_caja_apertura_fk FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario);
 P   ALTER TABLE ONLY public.caja_apertura DROP CONSTRAINT usuario_caja_apertura_fk;
       public       postgres    false    196    3030    217            �           2606    16727 "   caja_cierre usuario_caja_cierre_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.caja_cierre
    ADD CONSTRAINT usuario_caja_cierre_fk FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario);
 L   ALTER TABLE ONLY public.caja_cierre DROP CONSTRAINT usuario_caja_cierre_fk;
       public       postgres    false    3030    217    198            �           2606    16732 1   dinero_custodia_movimientos usuario_di_cus_mov_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.dinero_custodia_movimientos
    ADD CONSTRAINT usuario_di_cus_mov_fk FOREIGN KEY (id_usuario_i) REFERENCES public.usuario(id_usuario);
 [   ALTER TABLE ONLY public.dinero_custodia_movimientos DROP CONSTRAINT usuario_di_cus_mov_fk;
       public       postgres    false    3030    203    217            �           2606    16737 3   dinero_custodia_movimientos usuario_di_cus_mov_fk_1    FK CONSTRAINT     �   ALTER TABLE ONLY public.dinero_custodia_movimientos
    ADD CONSTRAINT usuario_di_cus_mov_fk_1 FOREIGN KEY (id_usuario_d) REFERENCES public.usuario(id_usuario);
 ]   ALTER TABLE ONLY public.dinero_custodia_movimientos DROP CONSTRAINT usuario_di_cus_mov_fk_1;
       public       postgres    false    3030    217    203            �           2606    16742 *   dinero_custodia usuario_dinero_custodia_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.dinero_custodia
    ADD CONSTRAINT usuario_dinero_custodia_fk FOREIGN KEY (id_usuario_i) REFERENCES public.usuario(id_usuario);
 T   ALTER TABLE ONLY public.dinero_custodia DROP CONSTRAINT usuario_dinero_custodia_fk;
       public       postgres    false    201    3030    217            �           2606    16747 ,   dinero_custodia usuario_dinero_custodia_fk_1    FK CONSTRAINT     �   ALTER TABLE ONLY public.dinero_custodia
    ADD CONSTRAINT usuario_dinero_custodia_fk_1 FOREIGN KEY (id_usuario_d) REFERENCES public.usuario(id_usuario);
 V   ALTER TABLE ONLY public.dinero_custodia DROP CONSTRAINT usuario_dinero_custodia_fk_1;
       public       postgres    false    201    3030    217            �           2606    16752 "   gastos_caja usuario_gastos_caja_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.gastos_caja
    ADD CONSTRAINT usuario_gastos_caja_fk FOREIGN KEY (id_usuario_i) REFERENCES public.usuario(id_usuario);
 L   ALTER TABLE ONLY public.gastos_caja DROP CONSTRAINT usuario_gastos_caja_fk;
       public       postgres    false    205    217    3030            �           2606    16757 $   gastos_caja usuario_gastos_caja_fk_1    FK CONSTRAINT     �   ALTER TABLE ONLY public.gastos_caja
    ADD CONSTRAINT usuario_gastos_caja_fk_1 FOREIGN KEY (id_usuario_d) REFERENCES public.usuario(id_usuario);
 N   ALTER TABLE ONLY public.gastos_caja DROP CONSTRAINT usuario_gastos_caja_fk_1;
       public       postgres    false    205    217    3030            �           2606    16762    usuario usuario_perfil_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_perfil_fk FOREIGN KEY (tipo_usuario) REFERENCES public.perfiles_usuario(tipo_usuario);
 C   ALTER TABLE ONLY public.usuario DROP CONSTRAINT usuario_perfil_fk;
       public       postgres    false    217    3014    207            �           2606    16767 &   venta_detalle usuario_venta_detalle_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.venta_detalle
    ADD CONSTRAINT usuario_venta_detalle_fk FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario);
 P   ALTER TABLE ONLY public.venta_detalle DROP CONSTRAINT usuario_venta_detalle_fk;
       public       postgres    false    217    3030    220            �           2606    16772    venta usuario_venta_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.venta
    ADD CONSTRAINT usuario_venta_fk FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario);
 @   ALTER TABLE ONLY public.venta DROP CONSTRAINT usuario_venta_fk;
       public       postgres    false    3030    217    219            �           2606    16777 (   venta_temporal usuario_venta_temporal_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.venta_temporal
    ADD CONSTRAINT usuario_venta_temporal_fk FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario);
 R   ALTER TABLE ONLY public.venta_temporal DROP CONSTRAINT usuario_venta_temporal_fk;
       public       postgres    false    217    223    3030            �           2606    16782 &   venta_detalle venta_temp_venta_deta_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.venta_detalle
    ADD CONSTRAINT venta_temp_venta_deta_fk FOREIGN KEY (id_venta_temp) REFERENCES public.venta_temporal(id_venta_temp);
 P   ALTER TABLE ONLY public.venta_detalle DROP CONSTRAINT venta_temp_venta_deta_fk;
       public       postgres    false    220    223    3036            �           2606    16787    venta venta_temporal_venta_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.venta
    ADD CONSTRAINT venta_temporal_venta_fk FOREIGN KEY (id_venta_temp) REFERENCES public.venta_temporal(id_venta_temp);
 G   ALTER TABLE ONLY public.venta DROP CONSTRAINT venta_temporal_venta_fk;
       public       postgres    false    223    219    3036            ~      x������ � �      �      x������ � �      �   �   x�-�M
�0F�3��5�Z�.=��i:�@H ]x��Ŝw��>�N��XpG�D�{�F�9�5\�W8	6p����������_�Ved
j�V�^�@'��T0��sd�n%롩�J����@��́���0���_�ND��~4�      �      x������ � �      �      x������ � �      �      x������ � �      �   A   x�KL����,�BG/���(1%��+7�8?�3�($��$�Z�ȕ���ΉY �=... &�W      �   =   x�3�(�O)M.�W��W��+K�+I,�LL��4 N��|�^A^:��%�g	W� \��      �      x������ � �      �   3   x�3�HL�W((�/KMM�/J-�2��%&%f%B�,9�K��b���� ���      �   "   x�3�tMKM.�,��2�I,�J-I����� i�2      �   #   x�3��N����2�,HL���8K��B1z\\\ ��A      �   U   x�3�tOL*�L�QK�J,�L/S�F�&��)��y�%\F���ŕ�� ,����7��M,JO,�,I��� ����� ]1z\\\ ^@l      �      x������ � �      �      x������ � �      �      x������ � �     