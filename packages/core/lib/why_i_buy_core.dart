/// Shared by the Why I Buy mobile app and web admin: Lab 2 design tokens and
/// components, Firestore models and the services for the shared collections.
library;

// Design system (Lab 2 tokens and components)
export 'src/theme/app_colors.dart';
export 'src/theme/app_dimens.dart';
export 'src/theme/app_text_styles.dart';
export 'src/widgets/app_button.dart';
export 'src/widgets/app_text_field.dart';
export 'src/widgets/confirm_dialog.dart';
export 'src/widgets/section_card.dart';
export 'src/widgets/states/empty_view.dart';
export 'src/widgets/states/error_view.dart';
export 'src/widgets/states/loading_view.dart';
export 'src/widgets/states/state_view.dart';
export 'src/widgets/states/ui_state_builder.dart';

// Models
export 'src/models/announcement.dart';
export 'src/models/app_role.dart';
export 'src/models/firestore_fields.dart';
export 'src/models/inbox_message.dart';
export 'src/models/sale_event.dart';
export 'src/models/sale_suggestion.dart';
export 'src/models/ui_state.dart';

// Firestore services
export 'src/services/announcement_service.dart';
export 'src/services/firestore_errors.dart';
export 'src/services/inbox_service.dart';
export 'src/services/role_service.dart';
export 'src/services/sale_event_service.dart';
export 'src/services/sale_suggestion_service.dart';
export 'src/services/shared_paths.dart';
