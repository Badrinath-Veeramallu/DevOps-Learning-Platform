/// Data models representing the DevOps Learning Platform Curriculum.
///
/// Exactly mirrors the schema of Web's `gitCurriculum.js` to ensure 100% data fidelity.
library;

class CurriculumLink {
  final String url;
  final String text;

  const CurriculumLink({required this.url, required this.text});

  factory CurriculumLink.fromJson(Map<String, dynamic> json) {
    return CurriculumLink(
      url: (json['url'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'url': url, 'text': text};
}

class CurriculumSnippet {
  final String code;
  final String language;

  const CurriculumSnippet({required this.code, required this.language});

  factory CurriculumSnippet.fromJson(Map<String, dynamic> json) {
    return CurriculumSnippet(
      code: (json['code'] ?? '').toString(),
      language: (json['language'] ?? 'bash').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'code': code, 'language': language};
}

class CurriculumSection {
  final int number;
  final String title;
  final List<String> paragraphs;
  final CurriculumLink? link;
  final List<String>? afterLinkParagraphs;
  final CurriculumSnippet? codeSnippet;
  final List<String>? postSnippetParagraphs;
  final CurriculumSnippet? secondSnippet;
  final List<String>? middleParagraphs;
  final CurriculumSnippet? thirdSnippet;
  final List<String>? afterThirdParagraphs;
  final CurriculumSnippet? fourthSnippet;
  final List<String>? listItems;
  final List<String>? closingParagraphs;

  const CurriculumSection({
    required this.number,
    required this.title,
    required this.paragraphs,
    this.link,
    this.afterLinkParagraphs,
    this.codeSnippet,
    this.postSnippetParagraphs,
    this.secondSnippet,
    this.middleParagraphs,
    this.thirdSnippet,
    this.afterThirdParagraphs,
    this.fourthSnippet,
    this.listItems,
    this.closingParagraphs,
  });

  factory CurriculumSection.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic list) {
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
      return const [];
    }

    return CurriculumSection(
      number: (json['number'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      paragraphs: parseStringList(json['paragraphs']),
      link: json['link'] != null
          ? CurriculumLink.fromJson(json['link'] as Map<String, dynamic>)
          : null,
      afterLinkParagraphs: json['afterLinkParagraphs'] != null
          ? parseStringList(json['afterLinkParagraphs'])
          : null,
      codeSnippet: json['codeSnippet'] != null
          ? CurriculumSnippet.fromJson(
              json['codeSnippet'] as Map<String, dynamic>,
            )
          : null,
      postSnippetParagraphs: json['postSnippetParagraphs'] != null
          ? parseStringList(json['postSnippetParagraphs'])
          : null,
      secondSnippet: json['secondSnippet'] != null
          ? CurriculumSnippet.fromJson(
              json['secondSnippet'] as Map<String, dynamic>,
            )
          : null,
      middleParagraphs: json['middleParagraphs'] != null
          ? parseStringList(json['middleParagraphs'])
          : null,
      thirdSnippet: json['thirdSnippet'] != null
          ? CurriculumSnippet.fromJson(
              json['thirdSnippet'] as Map<String, dynamic>,
            )
          : null,
      afterThirdParagraphs: json['afterThirdParagraphs'] != null
          ? parseStringList(json['afterThirdParagraphs'])
          : null,
      fourthSnippet: json['fourthSnippet'] != null
          ? CurriculumSnippet.fromJson(
              json['fourthSnippet'] as Map<String, dynamic>,
            )
          : null,
      listItems: json['listItems'] != null
          ? parseStringList(json['listItems'])
          : null,
      closingParagraphs: json['closingParagraphs'] != null
          ? parseStringList(json['closingParagraphs'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'title': title,
    'paragraphs': paragraphs,
    if (link != null) 'link': link!.toJson(),
    if (afterLinkParagraphs != null) 'afterLinkParagraphs': afterLinkParagraphs,
    if (codeSnippet != null) 'codeSnippet': codeSnippet!.toJson(),
    if (postSnippetParagraphs != null)
      'postSnippetParagraphs': postSnippetParagraphs,
    if (secondSnippet != null) 'secondSnippet': secondSnippet!.toJson(),
    if (middleParagraphs != null) 'middleParagraphs': middleParagraphs,
    if (thirdSnippet != null) 'thirdSnippet': thirdSnippet!.toJson(),
    if (afterThirdParagraphs != null)
      'afterThirdParagraphs': afterThirdParagraphs,
    if (fourthSnippet != null) 'fourthSnippet': fourthSnippet!.toJson(),
    if (listItems != null) 'listItems': listItems,
    if (closingParagraphs != null) 'closingParagraphs': closingParagraphs,
  };
}

class CurriculumModule {
  final String id;
  final int order;
  final String number;
  final String title;
  final String shortTitle;
  final String summary;
  final int estimatedMinutes;
  final List<String> objectives;
  final List<CurriculumSection> sections;

  const CurriculumModule({
    required this.id,
    required this.order,
    required this.number,
    required this.title,
    required this.shortTitle,
    required this.summary,
    required this.estimatedMinutes,
    required this.objectives,
    required this.sections,
  });

  factory CurriculumModule.fromJson(Map<String, dynamic> json) {
    return CurriculumModule(
      id: (json['id'] ?? '').toString(),
      order: (json['order'] as num?)?.toInt() ?? 0,
      number: (json['number'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      shortTitle: (json['shortTitle'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
      objectives: (json['objectives'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      sections: (json['sections'] as List? ?? [])
          .map((s) => CurriculumSection.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order': order,
    'number': number,
    'title': title,
    'shortTitle': shortTitle,
    'summary': summary,
    'estimatedMinutes': estimatedMinutes,
    'objectives': objectives,
    'sections': sections.map((s) => s.toJson()).toList(),
  };
}
