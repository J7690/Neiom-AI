import 'package:supabase_flutter/supabase_flutter.dart';

class VisualDocumentsService {
  final SupabaseClient _client;

  VisualDocumentsService(this._client);

  factory VisualDocumentsService.instance() {
    return VisualDocumentsService(Supabase.instance.client);
  }

  Future<Map<String, dynamic>> createProject({
    required String name,
    String? ownerId,
    List<dynamic>? tags,
  }) async {
    final response = await _client.functions.invoke(
      'visual-documents',
      body: {
        'action': 'create_project',
        'name': name,
        if (ownerId != null) 'ownerId': ownerId,
        if (tags != null) 'tags': tags,
      },
    );

    if (response.status >= 400) {
      throw Exception(
        'createProject failed with status ${response.status}: ${response.data}',
      );
    }

    final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final project = data['project'];
    if (project is! Map) {
      throw Exception('Missing project in createProject response');
    }
    return project.cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> listProjects() async {
    final response = await _client.functions.invoke(
      'visual-documents',
      body: const {
        'action': 'list_projects',
      },
    );

    if (response.status >= 400) {
      throw Exception(
        'listProjects failed with status ${response.status}: ${response.data}',
      );
    }

    final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final projects = data['projects'];
    if (projects is! List) {
      return const <Map<String, dynamic>>[];
    }
    return projects
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> listDocuments({String? projectId}) async {
    final response = await _client.functions.invoke(
      'visual-documents',
      body: {
        'action': 'list_documents',
        if (projectId != null) 'projectId': projectId,
      },
    );

    if (response.status >= 400) {
      throw Exception(
        'listDocuments failed with status ${response.status}: ${response.data}',
      );
    }

    final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final docs = data['documents'];
    if (docs is! List) {
      return const <Map<String, dynamic>>[];
    }
    return docs
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> createDocument({
    required String projectId,
    String? title,
    int? width,
    int? height,
    int? dpi,
    String? backgroundColor,
  }) async {
    final response = await _client.functions.invoke(
      'visual-documents',
      body: {
        'action': 'create_document',
        'projectId': projectId,
        if (title != null) 'title': title,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (dpi != null) 'dpi': dpi,
        if (backgroundColor != null) 'backgroundColor': backgroundColor,
      },
    );

    if (response.status >= 400) {
      throw Exception(
        'createDocument failed with status ${response.status}: ${response.data}',
      );
    }

    final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final doc = data['document'];
    if (doc is! Map) {
      throw Exception('Missing document in createDocument response');
    }
    return doc.cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getDocumentWithCurrentVersion({
    required String documentId,
  }) async {
    final response = await _client.functions.invoke(
      'visual-documents',
      body: {
        'action': 'get_document',
        'documentId': documentId,
      },
    );

    if (response.status >= 400) {
      throw Exception(
        'getDocument failed with status ${response.status}: ${response.data}',
      );
    }

    final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    return data;
  }

  Future<Map<String, dynamic>> saveVersion({
    required String documentId,
    required Map<String, dynamic> canvasState,
    String? thumbnailAssetId,
  }) async {
    final response = await _client.functions.invoke(
      'visual-documents',
      body: {
        'action': 'save_version',
        'documentId': documentId,
        'canvasState': canvasState,
        if (thumbnailAssetId != null) 'thumbnailAssetId': thumbnailAssetId,
      },
    );

    if (response.status >= 400) {
      throw Exception(
        'saveVersion failed with status ${response.status}: ${response.data}',
      );
    }

    final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final version = data['version'];
    if (version is! Map) {
      throw Exception('Missing version in saveVersion response');
    }
    return version.cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> listVersions({
    required String documentId,
  }) async {
    final response = await _client.functions.invoke(
      'visual-documents',
      body: {
        'action': 'list_versions',
        'documentId': documentId,
      },
    );

    if (response.status >= 400) {
      throw Exception(
        'listVersions failed with status ${response.status}: ${response.data}',
      );
    }

    final data =
        (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final versions = data['versions'];
    if (versions is! List) {
      return const <Map<String, dynamic>>[];
    }

    return versions
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> restoreVersion({
    required String versionId,
  }) async {
    final response = await _client.functions.invoke(
      'visual-documents',
      body: {
        'action': 'restore_version',
        'versionId': versionId,
      },
    );

    if (response.status >= 400) {
      throw Exception(
        'restoreVersion failed with status ${response.status}: ${response.data}',
      );
    }

    final data =
        (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final version = data['version'];
    if (version is! Map) {
      throw Exception('Missing version in restoreVersion response');
    }
    return version.cast<String, dynamic>();
  }
}
