class Account {
  const Account({required this.id, required this.name, required this.email, this.avatarUrl});

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();
}

/// Contas conectadas neste dispositivo e qual delas está ativa.
class AccountSession {
  const AccountSession({required this.accounts, required this.activeAccountId});

  final List<Account> accounts;
  final String activeAccountId;

  Account get activeAccount => accounts.firstWhere((a) => a.id == activeAccountId);
  int get activeIndex => accounts.indexWhere((a) => a.id == activeAccountId);
}

enum AuthProvider { google, email }
