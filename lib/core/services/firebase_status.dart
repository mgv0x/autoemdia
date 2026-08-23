/// Estado global indicando se o Firebase foi inicializado com sucesso.
/// Definido em `main.dart` após `Firebase.initializeApp()`.
class FirebaseStatus {
  FirebaseStatus._();
  static bool initialized = false;
}
