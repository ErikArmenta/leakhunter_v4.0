import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_users_provider.dart';
import '../models/app_user.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminUsersProvider.notifier).reloadUsers());
  }

  void _showUserDialog({AppUser? user}) {
    final isEditing = user != null;
    final emailController = TextEditingController(text: user?.email ?? '');
    final nameController = TextEditingController(text: user?.name ?? '');
    final passwordController = TextEditingController();
    final roles = ['Admin Principal', 'Supervisor', 'Inspector'];
    
    String selectedRole = 'Inspector';
    if (user != null && user.role.isNotEmpty) {
      final normalizedMatches = roles.where((r) => r.toLowerCase() == user.role.trim().toLowerCase()).toList();
      if (normalizedMatches.isNotEmpty) {
        selectedRole = normalizedMatches.first;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF161a22),
          title: Text(isEditing ? 'Editar Usuario' : 'Nuevo Empleado', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Nombre Completo', labelStyle: TextStyle(color: Colors.grey)),
                ),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  enabled: !isEditing, // Email no editable en Supabase por defecto facilmente
                  decoration: InputDecoration(labelText: 'Correo', labelStyle: const TextStyle(color: Colors.grey), helperText: isEditing ? 'El correo no se puede cambiar aquí.' : null, helperStyle: const TextStyle(color: Colors.orange)),
                ),
                TextField(
                  controller: passwordController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: InputDecoration(labelText: isEditing ? 'Nueva Contraseña (Opcional)' : 'Contraseña', labelStyle: const TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  dropdownColor: const Color(0xFF1d2129),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Rol', labelStyle: TextStyle(color: Colors.grey)),
                  items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) {
                    if (val != null) setStateDialog(() => selectedRole = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () async {
                final email = emailController.text.trim();
                final name = nameController.text.trim();
                final pwd = passwordController.text.trim();
                
                if (name.isEmpty || (!isEditing && (email.isEmpty || pwd.isEmpty))) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor completa todos los campos requeridos.')));
                   return;
                }

                Navigator.pop(ctx);
                
                if (isEditing) {
                  await ref.read(adminUsersProvider.notifier).updateUser(
                    user.id,
                    name: name,
                    role: selectedRole,
                    password: pwd.isNotEmpty ? pwd : null,
                  );
                } else {
                  await ref.read(adminUsersProvider.notifier).createUser(
                    email: email,
                    password: pwd,
                    role: selectedRole,
                    name: name,
                  );
                }
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161a22),
        title: const Text('Confirmar Eliminación', style: TextStyle(color: Colors.redAccent)),
        content: Text('¿Estás seguro que deseas eliminar el acceso a:\n\n${user.name} (${user.email})?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(adminUsersProvider.notifier).deleteUser(user.id);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0e1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161a22),
        title: const Text('Gestión de Usuarios (Admin)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminUsersProvider.notifier).reloadUsers(),
          ),
        ],
      ),
      body: state.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text("No hay usuarios.", style: TextStyle(color: Colors.white54)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (ctx, i) {
              final u = users[i];
              return Card(
                color: const Color(0xFF1d2129),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: u.role == 'Admin Principal' ? Colors.redAccent : (u.role == 'Supervisor' ? Colors.orange : Colors.blue),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.email, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text("Rol: ${u.role}", style: const TextStyle(color: Colors.cyan)),
                      if (u.lastSignInAt != null)
                        Text("Último acceso: ${DateFormat('dd MMM yyyy, HH:mm').format(u.lastSignInAt!)}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () => _showUserDialog(user: u),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _confirmDelete(u),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Crear Usuario'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
