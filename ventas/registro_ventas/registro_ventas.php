<?php 


$titulo = "Registro ventas - Punto de Venta";
$css = "estilosregistroventas.css";

$ruta = "";
while (!(file_exists ($ruta . "index.php"))) {
    $ruta = "../" . $ruta;
}


include_once $ruta . "includes/header.php";

include_once $ruta . "db/conexion.php";


// validar que usuario tenga permiso para acceder a pagina
if ($_SESSION['permisos']['caja'] !='t') {
    header('Location: '.$ruta);
 }


?>

<?php

if (isset($_REQUEST['nav'])) {
    if ($_REQUEST['nav'] == 'si'){
        include $ruta . "includes/nav.php"; 
    } 
}

?>

<?php 
$id_ap = 0;

if(isset($_REQUEST['id'])) {
    $id_ap = $_REQUEST['id'];
}
?>

<input type="hidden" id="id_ap" value="<?php echo $id_ap?>">


<?php
// asignar a inputs ocultos datos pasados
foreach ($_REQUEST as $key => $value) {
?>
<input class="filtro" type="hidden" id="<?php echo $key?>" value="<?php echo $value?>">

<?php } ?>




<?php 

if (isset($_REQUEST['sb'])) {
    if ($_REQUEST['sb'] != 'no'){
        include $ruta . "includes/sidebarinicio.php"; 
    } 
} else {
    include $ruta . "includes/sidebarinicio.php"; 
}

?>



<div id="contenedor" class="container lam">


    <h1><i class="fas fa-file-invoice-dollar"></i> Ventas pagadas</h1>
    <h5><?php if ($id_ap != 0) {echo 'Caja ID: '.$id_ap;} ?></h5>
    <div id="filtros">
        
    <form action="">
        
                    <div class="form-row">
                        <?php if ($id_ap == 0)  {?>
                            <div class="form-group col">
                                <label for="inputFecha">Fecha</label>
                                <input type="date" class="form-control" id="inputFecha" placeholder="">
                            </div>
                        <?php } ?>
                            <div class="form-group col">
                                <label for="inputMediodePago">Medio de pago</label>
                                <select id="inputMediodePago" class="form-control filtros">
                                    <option selected>Seleccione...</option>
                                </select>
                            </div>
                            <div class="form-group col">
                                <label for="inputCajero">Cajero/a</label>
                                <select id="inputCajero" class="form-control filtros">
                                    <option selected>Seleccione...</option>
                                </select>
                            </div>
                            <div class="form-group col">
                                <label for="inputVendedor">Vendedor/a</label>
                                <select id="inputVendedor" class="form-control filtros">
                                    <option selected>Seleccione...</option>
                                </select>
                            </div>
                    </div>
    </form>

            <!-- TODO -->
        </div>



    <div class="row">
        <!-- <div class="col"></div> -->



        <div id="div-tbl-ventas" class="col">
            <table class="table table-hover">
                <thead>

                <!-- // id_venta,
        // id_venta_temp,   para ver detalle
        // id_diario,
        // id_apertura,
        // fecha,
        // monto_venta,
        // id_tipo_pago,
        // nombre_tipo_pago,
        // id_usuario_venta_temp,
        // nombre_usuario_venta_temp,
        // hora_venta_temp,
        // id_usuario_pago,
        // nombre_usuario_pago,
        // hora_pago -->
                    <tr>
                    <th scope="col">Caja</th>
                    <th scope="col">Venta</th>
                    <th scope="col">ID diario</th>
                    <th scope="col">Fecha</th>
                    <th scope="col">Hora pago</th>
                    <th scope="col">M. de pago</th>
                    <th scope="col">Cajero/a</th>
                    <th scope="col">Vendedor/a</th>
                    <th scope="col">Total venta</th>
                    <th scope="col">Acciones</th>
                    </tr>
                </thead>
                <tbody id="tbody_registro_ventas">
                    <!-- <tr>
                    <th scope="row">1</th>
                    <td>Mark</td>
                    <td>Otto</td>
                    <td>@mdo</td>
                    <td>@mdo</td>
                    <td>@mdo</td>
                    <td>@mdo</td>
                    <td>@mdo</td>
                    </tr> -->
                </tbody>
            </table>
        </div>
    
        <!-- <div class="col"></div> -->
    </div>







</div>










<?php include_once $ruta . "includes/footer.php" ?>