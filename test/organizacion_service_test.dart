import 'package:borrowapp/data/memory_repository.dart';
import 'package:borrowapp/models/enums.dart';
import 'package:borrowapp/services/auth_service.dart';
import 'package:borrowapp/services/organizacion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'crear organización genera código y deja al creador como administrador',
    () async {
      final repositorio = MemoryRepository();
      final auth = AuthService(repositorio);
      final organizaciones = OrganizacionService(repositorio);
      final usuario = await auth.registrar(
        nombre: 'Usuario de prueba',
        correo: 'organizacion@test.com',
        contrasena: '12345678',
      );

      final organizacion = await organizaciones.crear(
        usuarioId: usuario.id,
        nombre: 'Comunidad de prueba',
        tipo: TipoOrganizacion.universidad,
        puntoCentral: 'Biblioteca central',
        identificadorInterno: 'Código estudiantil',
      );

      expect(organizacion.codigo, hasLength(5));
      expect(
        await organizaciones.buscarPorCodigo(organizacion.codigo),
        equals(organizacion),
      );

      final membresia = await organizaciones.membresia(
        usuario.id,
        organizacion.id,
      );
      expect(membresia?.esAdministrador, isTrue);
      expect(membresia?.estado, EstadoMembresia.activo);
    },
  );
}
