import 'app_state.dart';

class AdminTexts {
  final String uploadTitle;
  final String errorLabel;
  final String noPerms;
  final String moodsLabel; // with max note
  final String tapToSelect;
  final String stepsCompletedLabel;
  final String of;
  final String publish;
  final String stepLabelPrefix;
  final String verseLabel;
  final String paragraphsLabel;
  final String paragraphLabel;
  final String deleteLabel;
  final String cannotDeleteLabel;
  final String prayerRequiredLabel;
  final String farewellFixedLabel;
  final String markStepComplete;
  final String addParagraph;

  final String Function(String langName) stepCompletedFor;
  final String Function(String langName) completeMissingFor;

  const AdminTexts({
    required this.uploadTitle,
    required this.errorLabel,
    required this.noPerms,
    required this.moodsLabel,
    required this.tapToSelect,
    required this.stepsCompletedLabel,
    required this.of,
    required this.publish,
    required this.stepLabelPrefix,
    required this.verseLabel,
    required this.paragraphsLabel,
    required this.paragraphLabel,
    required this.deleteLabel,
    required this.cannotDeleteLabel,
    required this.prayerRequiredLabel,
    required this.farewellFixedLabel,
    required this.markStepComplete,
    required this.addParagraph,
    required this.stepCompletedFor,
    required this.completeMissingFor,
  });
}

AdminTexts adminTextsOf(AppLang lang) {
  switch (lang) {
    case AppLang.en:
      return AdminTexts(
        uploadTitle: 'Upload daily food',
        errorLabel: 'Error',
        noPerms: 'You do not have permission to access this panel.',
        moodsLabel: 'Moods (max. 3)',
        tapToSelect: 'Tap to select',
        stepsCompletedLabel: 'Completed steps',
        of: 'of',
        publish: 'Publish',
        stepLabelPrefix: 'Step: ',
        verseLabel: 'Verse',
        paragraphsLabel: 'Paragraphs (Description)',
        paragraphLabel: 'Paragraph',
        deleteLabel: 'Delete',
        cannotDeleteLabel: 'Cannot delete',
        prayerRequiredLabel: 'Prayer (required)',
        farewellFixedLabel: 'Farewell (fixed)',
        markStepComplete: 'Mark step as completed',
        addParagraph: 'Add paragraph',
        stepCompletedFor: (name) => 'Step $name completed ✓',
        completeMissingFor: (name) =>
            'Complete Verse, at least 1 paragraph and the Prayer in $name',
      );
    case AppLang.pt:
      return AdminTexts(
        uploadTitle: 'Enviar alimento diário',
        errorLabel: 'Erro',
        noPerms: 'Você não tem permissão para acessar este painel.',
        moodsLabel: 'Moods (máx. 3)',
        tapToSelect: 'Toque para selecionar',
        stepsCompletedLabel: 'Passos concluídos',
        of: 'de',
        publish: 'Publicar',
        stepLabelPrefix: 'Passo: ',
        verseLabel: 'Versículo',
        paragraphsLabel: 'Parágrafos (Descrição)',
        paragraphLabel: 'Parágrafo',
        deleteLabel: 'Excluir',
        cannotDeleteLabel: 'Não é possível excluir',
        prayerRequiredLabel: 'Oração (obrigatória)',
        farewellFixedLabel: 'Despedida (fixa)',
        markStepComplete: 'Marcar passo como concluído',
        stepCompletedFor: (name) => 'Passo $name concluído ✓',
        completeMissingFor: (name) =>
            'Complete Versículo, pelo menos 1 parágrafo e a Oração em $name',
      );
    case AppLang.it:
      return AdminTexts(
        uploadTitle: 'Carica cibo quotidiano',
        errorLabel: 'Errore',
        noPerms: 'Non hai i permessi per accedere a questo pannello.',
        moodsLabel: 'Moods (max 3)',
        tapToSelect: 'Tocca per selezionare',
        stepsCompletedLabel: 'Passi completati',
        of: 'di',
        publish: 'Pubblica',
        stepLabelPrefix: 'Passo: ',
        verseLabel: 'Versetto',
        paragraphsLabel: 'Paragrafi (Descrizione)',
        paragraphLabel: 'Paragrafo',
        deleteLabel: 'Elimina',
        cannotDeleteLabel: 'Impossibile eliminare',
        prayerRequiredLabel: 'Preghiera (obbligatoria)',
        farewellFixedLabel: 'Saluto (fisso)',
        markStepComplete: 'Segna passo come completato',
        addParagraph: 'Aggiungi paragrafo',
        stepCompletedFor: (name) => 'Passo $name completato ✓',
        completeMissingFor: (name) =>
            'Completa Versetto, almeno 1 paragrafo e la Preghiera in $name',
      );
    case AppLang.es:
      return AdminTexts(
        uploadTitle: 'Subir alimento diario',
        errorLabel: 'Error',
        noPerms: 'No tenés permisos para acceder a este panel.',
        moodsLabel: 'Moods (máx. 3)',
        tapToSelect: 'Toca para seleccionar',
        stepsCompletedLabel: 'Pasos completados',
        of: 'de',
        publish: 'Publicar',
        stepLabelPrefix: 'Paso: ',
        verseLabel: 'Versículo',
        paragraphsLabel: 'Párrafos (Descripción)',
        paragraphLabel: 'Párrafo',
        deleteLabel: 'Eliminar',
        cannotDeleteLabel: 'No se puede eliminar',
        prayerRequiredLabel: 'Oración (obligatoria)',
        farewellFixedLabel: 'Despedida (fija)',
        markStepComplete: 'Marcar paso como completado',
        addParagraph: 'Agregar p�rrafo',
        stepCompletedFor: (name) => 'Paso $name completado ✓',
        completeMissingFor: (name) =>
            'Completá Versículo, al menos 1 párrafo y la Oración en $name',
      );
  }
}


