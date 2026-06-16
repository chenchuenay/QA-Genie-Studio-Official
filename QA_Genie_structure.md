QA_Genie:
└── lib/
├── app/
│ ├── app.dart
│ ├── config/
│ │ └── app_config.dart
│ ├── router/
│ │ └── app_router.dart
│ ├── startup/
│ │ └── app_dependencies.dart
│ └── theme/
│ ├── app_colors.dart
│ ├── app_radius.dart
│ ├── app_spacing.dart
│ ├── app_text.dart
│ ├── app_theme.dart
│ └── premium_theme.dart
├── core/
│ ├── config/
│ │ └── app_environment.dart
│ ├── constants/
│ │ └── app_limits.dart
│ ├── database/
│ │ ├── database_service.dart
│ │ ├── dump_writer.dart
│ │ └── migrations/
│ │ └── schema_v1.dart
│ ├── error/
│ │ ├── exceptions.dart
│ │ ├── ui_error_service.dart
│ │ └── ui_error_store.dart
│ ├── forensics/
│ │ ├── forensics_provider.dart
│ │ ├── forensics_service.dart
│ │ ├── forensics_service_dev.dart
│ │ └── forensics_service_prod.dart
│ ├── network/
│ │ ├── api_client.dart
│ │ ├── cloud_authority_service.dart
│ │ ├── connectivity_service.dart
│ │ └── network_guard.dart
│ ├── security/
│ │ ├── anti_abuse_heuristics.dart
│ │ ├── pii_scrubber.dart
│ │ ├── security_bridge.dart
│ │ └── security_filter.dart
│ ├── state/
│ │ └── generation_state.dart
│ └── utils/
│ ├── device_utils.dart
│ ├── dialog_utils.dart
│ ├── finalized_test_case_adapter.dart
│ ├── id_generator.dart
│ ├── platform_utils.dart
│ ├── priority_utils.dart
│ ├── stable_hash.dart
│ └── test_data_factory.dart
├── data/
│ ├── datasources/
│ │ └── local/
│ │ └── local_db_source.dart
│ ├── dto/
│ │ └── generation_dto.dart
│ ├── models/
│ │ └── test_case_model.dart
│ └── repositories/
│ ├── export_repository.dart
│ └── suite_repository.dart
├── domain/
│ ├── entities/
│ │ ├── finalized_test_case.dart
│ │ ├── test_case.dart
│ │ ├── test_step.dart
│ │ └── test_suite.dart
│ ├── enums/
│ │ ├── case_source.dart
│ │ ├── execution_intent.dart
│ │ ├── export_format.dart
│ │ ├── generation_mode.dart
│ │ └── test_case_origin.dart
│ └── usecases/
│ ├── export_test_cases_use_case.dart
│ ├── export_validation_service.dart
│ ├── generate_test_cases_use_case.dart
│ ├── get_history_use_case.dart
│ └── save_suite_use_case.dart
├── engine/
│ ├── adapters/
│ │ └── working_case_adapter.dart
│ ├── business/
│ │ └── business_area.dart
│ ├── domains/
│ │ ├── commerce_domain.dart
│ │ ├── cross_domain.dart
│ │ ├── identity_domain.dart
│ │ ├── integration_domain.dart
│ │ ├── records_domain.dart
│ │ ├── scheduling_domain.dart
│ │ └── transaction_domain.dart
│ ├── fallback/
│ │ └── fallback_wrapper.dart
│ ├── forensics/
│ │ ├── error_capture_utils.dart
│ │ ├── models/
│ │ │ └── pipeline_event.dart
│ │ ├── pipeline_audit_logger.dart
│ │ ├── pipeline_audit_report.dart
│ │ ├── pipeline_observer.dart
│ │ └── trace_id_generator.dart
│ ├── generators/
│ │ ├── data_generator.dart
│ │ ├── expected_result_generator.dart
│ │ ├── flow_graph_generator.dart
│ │ ├── precondition_generator.dart
│ │ ├── step_generator.dart
│ │ └── title_generator.dart
│ ├── humanization/
│ │ └── qa_heuristics_engine.dart
│ ├── models/
│ │ ├── domain_context.dart
│ │ ├── generation_outcome.dart
│ │ ├── pipeline_models.dart
│ │ ├── scenario.dart
│ │ └── scenario_assignment.dart
│ ├── ontology/
│ │ ├── actions.dart
│ │ ├── constraints.dart
│ │ ├── domain_registry.dart
│ │ ├── entities.dart
│ │ ├── relationships.dart
│ │ └── states.dart
│ ├── orchestration/
│ │ ├── pipeline_orchestrator.dart
│ │ └── stages/
│ │ ├── ai_generation_stage.dart
│ │ ├── coverage_analysis_stage.dart
│ │ ├── fallback_stage.dart
│ │ ├── finalization_stage.dart
│ │ ├── parsing_stage.dart
│ │ ├── repair_stage.dart
│ │ └── validation_stage.dart
│ ├── orchestrator/
│ │ └── deterministic_engine.dart
│ ├── parsers/
│ │ ├── ai_response_parser.dart
│ │ ├── malformed_json_salvager.dart
│ │ ├── partial_case_extractor.dart
│ │ ├── response_classifier.dart
│ │ └── schema_normalizer.dart
│ ├── planners/
│ │ ├── constraint_parser.dart
│ │ ├── coverage_planner.dart
│ │ ├── domain_detector.dart
│ │ ├── prompt_planner.dart
│ │ └── scenario_planner.dart
│ ├── prompts/
│ │ ├── prompt_cache_manager.dart
│ │ ├── prompt_composer.dart
│ │ └── system_prompt.dart
│ ├── recovery/
│ │ └── ai_repair_engine.dart
│ ├── rules/
│ │ ├── constraint_rules.dart
│ │ └── domain_rules.dart
│ ├── scenarios/
│ │ ├── scenario_engine.dart
│ │ ├── scenario_factory.dart
│ │ └── scenario_registry.dart
│ ├── services/
│ │ └── generation_metrics.dart
│ ├── tests/
│ │ └── variant_regression_suite.dart
│ ├── utils/
│ │ └── pdf_text_sanitizer.dart
│ └── validators/
│ ├── coverage_validator.dart
│ ├── duplication_validator.dart
│ ├── export_safety_validator.dart
│ ├── realism_validator.dart
│ ├── semantic_validator.dart
│ └── structural_validator.dart
├── features/
│ ├── account/
│ │ └── ui/
│ │ └── account_screen.dart
│ ├── auth/
│ │ ├── services/
│ │ │ └── auth_service.dart
│ │ └── ui/
│ │ └── auth_dialog.dart
│ ├── beta/
│ │ ├── logic/
│ │ │ └── beta_manager.dart
│ │ └── ui/
│ │ └── beta_expired_screen.dart
│ ├── bugs/
│ │ └── ui/
│ │ └── bug_report_overlay.dart
│ ├── export/
│ │ ├── adapters/
│ │ │ ├── csv_adapter.dart
│ │ │ ├── excel_adapter.dart
│ │ │ ├── json_adapter.dart
│ │ │ └── pdf_adapter.dart
│ │ ├── common/
│ │ │ └── export_mapper.dart
│ │ ├── folder/
│ │ │ └── export_folder_service.dart
│ │ └── writers/
│ │ ├── file_writer.dart
│ │ └── share_service.dart
│ ├── forensics/
│ │ ├── diagnostics_persistence_service.dart
│ │ └── production_diagnostics_screen.dart
│ ├── generation/
│ │ └── ui/
│ │ ├── screens/
│ │ │ └── home_screen.dart
│ │ └── widgets/
│ │ └── master_table.dart
│ ├── legal/
│ │ ├── data/
│ │ │ └── legal_documents.dart
│ │ └── ui/
│ │ ├── about_screen.dart
│ │ ├── document_view_screen.dart
│ │ └── terms_privacy_policy.dart
│ ├── monetization/
│ │ ├── ads/
│ │ │ ├── ad_manager.dart
│ │ │ └── ad_units.dart
│ │ ├── logic/
│ │ │ └── usage_manager.dart
│ │ └── ui/
│ │ ├── rate_us_dialog.dart
│ │ ├── test_mode_screen.dart
│ │ ├── upgrade_coming_soon_screen.dart
│ │ └── upgrade_screen.dart
│ ├── suites/
│ │ └── ui/
│ │ └── screens/
│ │ ├── suite_preview_screen.dart
│ │ └── suites_screen.dart
│ ├── summary/
│ │ └── ui/
│ │ ├── summary_report_preview_screen.dart
│ │ └── summary_report_screen.dart
│ └── support/
│ └── ui/
│ └── report_issue_screen.dart
├── firebase/
│ ├── analytics/
│ │ └── analytics_service.dart
│ ├── app_check/
│ │ └── app_check_service.dart
│ ├── cloud_functions/
│ │ └── functions_service.dart
│ └── firebase_options.dart
├── main.dart
└── shared/
├── animations/
│ └── shimmer_loading.dart
├── badges/
│ └── pro_badge.dart
├── dialogs/
│ ├── ad_loading_dialog.dart
│ ├── export_bottom_sheet.dart
│ ├── export_preview_dialog.dart
│ ├── export_success_dialog.dart
│ ├── feedback_dialog.dart
│ └── guidelines_dialog.dart
├── effects/
│ └── press_effect.dart
├── navigation/
│ └── main_screen.dart
├── ui/
│ └── no_internet_screen.dart
└── widgets/
├── animated_dots.dart
├── native_ad_widget.dart
├── qa_button.dart
├── tier_icon.dart
└── watch_ad_dialog.dart

QA_Genie:
└── test/
└── forensic_tests/
├── headless/
│ ├── exports/
│ │ └── full_export_test.dart
│ ├── generation/
│ │ ├── ai_reintegration_pipeline_test.dart
│ │ ├── generation_pipeline_test.dart
│ │ └── live_mass_generation_test.dart
│ └── inputs/
│ └── generation_inputs.dart
├── live/
│ └── production_generation_test.dart
├── support/
│ ├── forensic_runner.dart
│ ├── live_http.dart
│ ├── production_forensic_runner.dart
│ └── test_pipeline_observer.dart
└── test_results/
├── export_files/

            └── gen_results/
