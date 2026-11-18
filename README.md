# BorrowApp

Una aplicación móvil para el préstamo y alquiler de objetos entre miembros de comunidades cerradas (universidades, empresas, conjuntos residenciales). Permite gestionar necesidades, ofertas, préstamos con confirmación cruzada, reportes y sanciones administrativas. El desarrollo utiliza Flutter y una API REST (FastAPI) con PostgreSQL, integrando un modelo de organizaciones múltiples y membresías independientes para gestionar roles y estados de usuario.

## Enlaces del proyecto

* **Aplicación móvil (APK):** [Descargar versión Android](https://n9.cl/borrowapp_android)
* **Panel de administración web:** [Abrir panel web](https://borrowappadmin.netlify.app/)
* **API REST y documentación (Swagger):** [Api](https://borrowapp.onrender.com/docs)


## Stack y despliegue

* **App móvil:** Flutter (Dart)
* **Panel administrativo:** HTML, CSS y JavaScript 
* **Backend:** FastAPI + SQLAlchemy (desplegado en Render)
* **Base de datos:** PostgreSQL (alojada en Supabase)
