/// Constantes globais do aplicativo Auto em Dia.
abstract final class AppConstants {
  static const appName = 'Auto em Dia';
  static const appSlogan = 'Seu carro cuidado, sem esquecer de nada.';

  // --- Categorias de manutenção ---
  static const maintenanceCategories = <String>[
    'Óleo e filtros',
    'Freios',
    'Pneus',
    'Motor',
    'Suspensão',
    'Elétrica',
    'Ar-condicionado',
    'Transmissão',
    'Alinhamento',
    'Bateria',
    'Documentação',
    'Seguro',
    'Lavagem',
    'Outros',
  ];

  // --- Categorias de gastos ---
  static const expenseCategories = <String>[
    'Manutenção',
    'Combustível',
    'Seguro',
    'Documentação',
    'Lavagem',
    'Peças',
    'Outros',
  ];

  // --- Tipos de combustível ---
  static const fuelTypes = <String>[
    'Flex',
    'Gasolina',
    'Etanol',
    'Diesel',
    'GNV',
    'Híbrido',
    'Elétrico',
  ];

  // --- Limites do plano gratuito ---
  static const freePlanMaxVehicles = 1;
  static const premiumPlanMaxVehicles = 5;

  // --- Notificações ---
  static const notificationChannelId = 'auto_em_dia_lembretes';
  static const notificationChannelName = 'Lembretes';
  static const notificationChannelDescription =
      'Lembretes de manutenção e revisão do seu veículo.';

  // --- URLs institucionais ---
  // Substitua pelas URLs reais ao publicar (ex.: seu site).
  static const privacyPolicyUrl = 'https://autoemdia.com.br/privacidade';
  static const termsOfUseUrl = 'https://autoemdia.com.br/termos';

  // Antecedências (em dias) para notificação de lembrete por data.
  static const reminderNotifyDaysBefore = <int>[30, 7, 0];
  // Antecedência em km para lembrete por quilometragem.
  static const reminderNotifyKmBefore = 500;
}
