# Auto em Dia

**Seu carro cuidado, sem esquecer de nada.**

Aplicativo Android (Flutter) para proprietários de veículos controlarem
manutenção, quilometragem, gastos, lembretes e revisões.

---

## Sumário

- [Requisitos](#requisitos)
- [Stack](#stack)
- [Arquitetura](#arquitetura)
- [Configuração do Firebase](#configuração-do-firebase)
- [Regras de segurança](#regras-de-segurança)
- [Índices do Firestore](#índices-do-firestore)
- [Configuração do AdMob](#configuração-do-admob)
- [Configuração do Google Play Billing](#configuração-do-google-play-billing)
- [Rodando o app](#rodando-o-app)
- [Rodando os testes](#rodando-os-testes)
- [Gerando APK e AAB](#gerando-apk-e-aab)
- [Checklist de publicação](#checklist-de-publicação)

---

## Requisitos

- Flutter 3.44+ / Dart 3.12+
- Android Studio / Android SDK
- Conta Firebase (projeto criado) — **Auth, Firestore, Analytics, Crashlytics, Cloud Messaging**
- Conta AdMob (apenas para publicação)
- Conta Google Play Developer (para assinatura Premium)

## Stack

| Camada | Tecnologia |
|---|---|
| Linguagem/Toolkit | Flutter + Dart (Material 3) |
| Estado | Riverpod (NotifierProvider) |
| Navegação | go_router |
| Backend/DB/Auth | **Firebase** (Firestore, Firebase Auth) — plano gratuito (Spark) |
| Analytics / Crash | Firebase Analytics / Crashlytics |
| Push | Firebase Cloud Messaging |
| Foto do veículo | **Local no aparelho** (`path_provider` + `image_picker`), sem uso do Firebase Storage |
| Notificações locais | flutter_local_notifications |
| Anúncios | Google Mobile Ads (AdMob) |
| Assinatura | Google Play Billing (in_app_purchase) |
| Gráficos | fl_chart |

> **Nota:** a **foto do veículo é salva apenas localmente** no aparelho
> (em `path_provider` via `LocalPhotoService`), para manter o app no plano
> 100% gratuito (sem Firebase Storage). O campo `photo_path` no Firestore
> guarda apenas o caminho local (referência), sem hospedar o arquivo.

## Arquitetura

Organização por feature (Clean Architecture simplificada):

```
lib/
  app/              # bootstrap, tema, router, shell
  core/             # constantes, erros, serviços, utilitários
    constants/      # AppConstants + Env
    errors/         # AppFailure + mapeamento de erros Firebase
    services/       # FirebaseBootstrap, Storage, Analytics, Crashlytics,
                    #   NotificationService, AdMob, CalculationService
    utils/          # Validators, Formatters, SnackBar
  features/
    auth/           # login, cadastro, reset, Google (Firebase Auth)
    vehicle/        # CRUD veículo + upload foto
    dashboard/      # resumo agregado
    maintenance/    # CRUD manutenções + lembrete automático
    reminders/      # lembretes + notificações locais
    expenses/       # CRUD gastos + gráficos
    subscription/   # plano, Google Play Billing
    settings/       # hub "Mais", Meu Carro
  shared/           # providers (Firebase/Analytics), widgets
```

Fluxo de dados: **UI → Notifier (Riverpod) → Repository → Firebase**.
A UI nunca consulta o Firebase diretamente.

## Configuração do Firebase

### 1. Crie o projeto
No Firebase Console, crie um projeto e adicione um app Android com o package
**`com.autoemdia.app`**.

### 2. Configure Authentication
- Habilite **E-mail/Senha** em `Authentication > Sign-in method`.
- Para o **Google Sign-In**, adicione o provedor Google e configure o
  SHA-1/SHA-256 do seu keystore no Firebase (console > configurações do projeto).

### 3. Configurar o app
Instale o FlutterFire CLI e rode na raiz:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure --project=auto-em-dia
```

Isso gera o `firebase_options.dart` e confirma o `android/app/google-services.json`.

## Regras de segurança

### Firestore (equivalente ao RLS)
Publique o conteúdo de [`firestore.rules`](firestore.rules) no Firebase Console
em **Firestore Database > Regras** (ou via `firebase deploy --only firestore:rules`).

## Índices do Firestore

As queries compostas do app exigem índices. Rode:

```bash
firebase deploy --only firestore:indexes
```

Ou crie manualmente no Firebase Console (Firestore Database > Índices)
usando como referência [`firestore.indexes.json`](firestore.indexes.json).

## Configuração do AdMob

Durante desenvolvimento, o app usa **IDs de teste** do Google.

Antes de **publicar**:
1. Crie os IDs reais no console do AdMob.
2. Atualize `.env`:
   - `ADMOB_APP_ID_ANDROID`
   - `ADMOB_BANNER_ID_ANDROID`
3. Atualize o `android/app/src/main/AndroidManifest.xml` (valor de
   `com.google.android.gms.ads.APPLICATION_ID`).

> O banner só aparece para usuários do plano gratuito. Usuários Premium não veem anúncios.

## Configuração do Google Play Billing

1. Crie os produtos de assinatura no **Google Play Console**:
   - `premium_mensal` → R$ 9,90/mês
   - `premium_anual` → R$ 79,90/ano
2. Teste com uma conta de teste de licença antes de publicar.
3. A tela Premium carrega os preços **direto da loja**.

> Para builds, injete as variáveis via `--dart-define` (veja [.env.example](.env.example)).

## Rodando o app

```powershell
flutter pub get
flutterfire configure   # se ainda não rodou
flutter run             # ou com --dart-define-from-file=.env para AdMob/Billing
```

## Rodando os testes

```powershell
flutter analyze
flutter test
```

Cobertura:
- Validações (e-mail, senha, ano, quilometragem, dinheiro)
- Mapeamento de erros (Firebase Auth, FirebaseException, offline)
- Cálculos financeiros
- Serialização dos modelos Firestore

## Gerando APK e AAB

```powershell
# Requer google-services.json e firebase_options.dart configurados.
flutter build apk --release
flutter build appbundle --release
```

Saída:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## Checklist de publicação

- [ ] `flutter pub get` sem erros
- [ ] `flutter analyze` com **zero** errors
- [ ] `flutter test` passando
- [ ] `google-services.json` em `android/app/` (real, do Firebase Console)
- [ ] `flutterfire configure` executado (gerou `firebase_options.dart`)
- [ ] **Authentication** com E-mail/Senha (e Google) habilitados
- [ ] **Firestore rules** publicadas
- [ ] **Firestore indexes** criados (via `firebase deploy` ou console)
- [ ] **Storage rules** publicadas
- [ ] AdMob com IDs reais no `AndroidManifest.xml`
- [ ] Google Play Billing com os 2 produtos (`premium_mensal`, `premium_anual`)
- [ ] Ícone do app definido
- [ ] Keystore de produção configurada (ver `flutter.dev/to/android-deployment`)
- [ ] `flutter build appbundle --release` concluído
- [ ] Política de privacidade publicada em URL pública
