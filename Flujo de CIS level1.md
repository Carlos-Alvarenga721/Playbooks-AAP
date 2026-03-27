## Flujo de Demo — CIS Level 1

Cuando el usuario accede al portal, el sistema ejecuta automáticamente
en background un playbook que deja el servidor en estado inseguro,
simulando un entorno real con vulnerabilidades.

El usuario entonces ejecuta el workflow que hicimos antes y desde el portal se ejecutan:

1. **Auditoría CIS** → detecta y lista todos los controles fallidos
2. **Remediación CIS** → corrige automáticamente cada vulnerabilidad
3. **Reporte** → genera y envía por email el comparativo antes/después hacia el correo del usuario que se logueo dentro del portal.

El resultado es una demostración en vivo donde el evaluador ve
el problema real y la solución automatizada en menos de 5 minutos.

para la parte del break playbook yo ya defini que se ejecutara en segundo plano, pero todo esto tiene que ir de la mano con la autenticacion del usuario dentro del portal, porque el flujo que tengo pensando es que el portal o pagina web en palabras mas simples, tiene que tener un login (el cual pienso hacerlo con Google, poder acceder a la pagina web por medio del correo electronico de google) en el que el usuario luego de ingresar sus  crendenciales y poder acceder correctamente. Le mostrara la interfaz del home donde tenga los botones o casos de uso (serian el CIS level#1 y la gestion de usuarios con Active Directory y BD en el RHEL target que tambien es importante aclarar, este servidor se vera involucrado en ambas tareas de automatizacion para mi POC).

 Ahora mi duda actual es esta:
Yo entonces deberia de empezar a realizar que exactamente? la pagina web? el logueo con Google para que esa parte este lista y luego ver como hago para que al ingrear las credenciales el usuario, este break playbook se ejecute en segundo plano ya con toda la logica del ingreso de usuario.

o deberia de primero hacer el break  playbook para ver si funciona, y ya despues hago el logueo y autenticacion y empiezo a ponerle mano al codigo de la pagina web o que procede? esa es mi duda mas que todo