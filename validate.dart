// Standalone validator for template.json files.
// Run with: dart run validate.dart

import 'dart:convert';
import 'dart:io';

const validFieldTypes = {
  'integer',
  'float',
  'text',
  'boolean',
  'datetime',
  'enumerated',
  'dimension',
  'reference',
  'location',
  'group',
  'multiEnum',
};

const validUiElements = {
  'slider',
  'textField',
  'textArea',
  'stepper',
  'chips',
  'dropdown',
  'radio',
  'toggleSwitch',
  'checkbox',
  'datePicker',
  'timePicker',
  'datetimePicker',
  'searchField',
  'locationPicker',
  'timer',
};

int main() {
  final templatesDir = Directory('templates');
  if (!templatesDir.existsSync()) {
    stderr.writeln('ERROR: templates/ directory not found. '
        'Run this script from the quanitya-templates/ directory.');
    return 1;
  }

  final errors = <String>[];
  var passed = 0;
  var failed = 0;

  final dirs = templatesDir
      .listSync()
      .whereType<Directory>()
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (dirs.isEmpty) {
    stderr.writeln('WARNING: No template directories found.');
    return 1;
  }

  for (final dir in dirs) {
    final slug = dir.uri.pathSegments
        .where((s) => s.isNotEmpty)
        .last;
    final file = File('${dir.path}/template.json');

    if (!file.existsSync()) {
      errors.add('[$slug] Missing template.json');
      failed++;
      continue;
    }

    final templateErrors = _validateTemplate(slug, file);
    if (templateErrors.isEmpty) {
      stdout.writeln('PASS  $slug');
      passed++;
    } else {
      stdout.writeln('FAIL  $slug');
      for (final e in templateErrors) {
        stdout.writeln('      - $e');
      }
      errors.addAll(templateErrors);
      failed++;
    }
  }

  stdout.writeln('');
  stdout.writeln('Results: $passed passed, $failed failed');

  return failed > 0 ? 1 : 0;
}

List<String> _validateTemplate(String slug, File file) {
  final errors = <String>[];

  // Parse JSON
  final Map<String, dynamic> json;
  try {
    json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  } catch (e) {
    return ['[$slug] Invalid JSON: $e'];
  }

  // Top-level required fields
  if (json['version'] is! String) {
    errors.add('[$slug] Missing or invalid "version" (expected String)');
  }

  // Author
  final author = json['author'];
  if (author is! Map<String, dynamic>) {
    errors.add('[$slug] Missing or invalid "author" (expected object)');
  } else {
    if (author['name'] is! String || (author['name'] as String).isEmpty) {
      errors.add('[$slug] author.name is required');
    }
  }

  // Template
  final template = json['template'];
  if (template is! Map<String, dynamic>) {
    errors.add('[$slug] Missing or invalid "template" (expected object)');
    return errors; // Can't validate further
  }

  if (template['id'] is! String || (template['id'] as String).isEmpty) {
    errors.add('[$slug] template.id is required');
  }
  if (template['name'] is! String || (template['name'] as String).isEmpty) {
    errors.add('[$slug] template.name is required');
  }
  if (template['updatedAt'] is! String) {
    errors.add('[$slug] template.updatedAt is required');
  }

  // Fields
  final fields = template['fields'];
  if (fields is! List) {
    errors.add('[$slug] template.fields is required (expected array)');
    return errors;
  }

  if (fields.isEmpty) {
    errors.add('[$slug] template.fields must not be empty');
  }

  for (var i = 0; i < fields.length; i++) {
    final field = fields[i];
    if (field is! Map<String, dynamic>) {
      errors.add('[$slug] fields[$i] is not an object');
      continue;
    }
    errors.addAll(_validateField(slug, 'fields[$i]', field, allowGroup: true));
  }

  // Aesthetics (optional but validate structure if present)
  final aesthetics = json['aesthetics'];
  if (aesthetics != null) {
    if (aesthetics is! Map<String, dynamic>) {
      errors.add('[$slug] aesthetics must be an object if present');
    } else {
      errors.addAll(_validateAesthetics(slug, aesthetics));
    }
  }

  return errors;
}

List<String> _validateField(
  String slug,
  String path,
  Map<String, dynamic> field, {
  bool allowGroup = false,
}) {
  final errors = <String>[];

  // Required field properties
  if (field['id'] is! String || (field['id'] as String).isEmpty) {
    errors.add('[$slug] $path.id is required');
  }
  if (field['label'] is! String || (field['label'] as String).isEmpty) {
    errors.add('[$slug] $path.label is required');
  }
  if (field['isDeleted'] is! bool) {
    errors.add('[$slug] $path.isDeleted is required (expected bool)');
  }
  if (field['isList'] is! bool) {
    errors.add('[$slug] $path.isList is required (expected bool)');
  }

  // Type validation
  final type = field['type'];
  if (type is! String || !validFieldTypes.contains(type)) {
    errors.add('[$slug] $path.type "$type" is not a valid FieldEnum. '
        'Valid: ${validFieldTypes.join(', ')}');
  }

  // UI element validation (optional)
  final uiElement = field['uiElement'];
  if (uiElement != null && uiElement is String) {
    if (!validUiElements.contains(uiElement)) {
      errors.add('[$slug] $path.uiElement "$uiElement" is not valid. '
          'Valid: ${validUiElements.join(', ')}');
    }
  }

  // Type-specific requirements
  if (type == 'enumerated' || type == 'multiEnum') {
    final options = field['options'];
    if (options is! List || options.isEmpty) {
      errors.add(
          '[$slug] $path: $type type requires non-empty "options" list');
    }
  }

  if (type == 'dimension') {
    if (field['unit'] == null) {
      errors.add('[$slug] $path: dimension type requires "unit"');
    }
  }

  if (type == 'group') {
    if (!allowGroup) {
      errors.add('[$slug] $path: nested group fields are not allowed');
    }
    final subFields = field['subFields'];
    if (subFields is! List || subFields.isEmpty) {
      errors.add(
          '[$slug] $path: group type requires non-empty "subFields" list');
    } else {
      for (var i = 0; i < subFields.length; i++) {
        final sub = subFields[i];
        if (sub is! Map<String, dynamic>) {
          errors.add('[$slug] $path.subFields[$i] is not an object');
          continue;
        }
        errors.addAll(
          _validateField(slug, '$path.subFields[$i]', sub, allowGroup: false),
        );
      }
    }
  }

  return errors;
}

List<String> _validateAesthetics(
    String slug, Map<String, dynamic> aesthetics) {
  final errors = <String>[];

  if (aesthetics['id'] is! String) {
    errors.add('[$slug] aesthetics.id is required');
  }
  if (aesthetics['templateId'] is! String) {
    errors.add('[$slug] aesthetics.templateId is required');
  }

  final palette = aesthetics['palette'];
  if (palette is! Map<String, dynamic>) {
    errors.add('[$slug] aesthetics.palette is required (expected object)');
  } else {
    final accents = palette['accents'];
    if (accents is! List || accents.isEmpty) {
      errors.add('[$slug] aesthetics.palette.accents must be a non-empty list');
    }
    final tones = palette['tones'];
    if (tones is! List || tones.isEmpty) {
      errors.add('[$slug] aesthetics.palette.tones must be a non-empty list');
    }
  }

  final fontConfig = aesthetics['fontConfig'];
  if (fontConfig is! Map<String, dynamic>) {
    errors.add('[$slug] aesthetics.fontConfig is required (expected object)');
  } else {
    if (fontConfig['titleWeight'] is! int) {
      errors.add('[$slug] aesthetics.fontConfig.titleWeight must be int');
    }
    if (fontConfig['subtitleWeight'] is! int) {
      errors.add('[$slug] aesthetics.fontConfig.subtitleWeight must be int');
    }
    if (fontConfig['bodyWeight'] is! int) {
      errors.add('[$slug] aesthetics.fontConfig.bodyWeight must be int');
    }
  }

  if (aesthetics['colorMappings'] is! Map) {
    errors.add('[$slug] aesthetics.colorMappings is required (expected object)');
  }

  return errors;
}
