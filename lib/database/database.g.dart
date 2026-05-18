// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $VersesTable extends Verses with TableInfo<$VersesTable, Verse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VersesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _bookMeta = const VerificationMeta('book');
  @override
  late final GeneratedColumn<String> book = GeneratedColumn<String>(
      'book', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chapterMeta =
      const VerificationMeta('chapter');
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
      'chapter', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _verseMeta = const VerificationMeta('verse');
  @override
  late final GeneratedColumn<int> verse = GeneratedColumn<int>(
      'verse', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _textContentMeta =
      const VerificationMeta('textContent');
  @override
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
      'text_content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _textContentNormalizedMeta =
      const VerificationMeta('textContentNormalized');
  @override
  late final GeneratedColumn<String> textContentNormalized =
      GeneratedColumn<String>('text_content_normalized', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _noteTextMeta =
      const VerificationMeta('noteText');
  @override
  late final GeneratedColumn<String> noteText = GeneratedColumn<String>(
      'note_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteColorMeta =
      const VerificationMeta('noteColor');
  @override
  late final GeneratedColumn<String> noteColor = GeneratedColumn<String>(
      'note_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isChapterReadMeta =
      const VerificationMeta('isChapterRead');
  @override
  late final GeneratedColumn<bool> isChapterRead = GeneratedColumn<bool>(
      'is_chapter_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_chapter_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        book,
        chapter,
        verse,
        textContent,
        textContentNormalized,
        isFavorite,
        noteText,
        noteColor,
        isChapterRead
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'verses';
  @override
  VerificationContext validateIntegrity(Insertable<Verse> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book')) {
      context.handle(
          _bookMeta, book.isAcceptableOrUnknown(data['book']!, _bookMeta));
    } else if (isInserting) {
      context.missing(_bookMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(_chapterMeta,
          chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta));
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('verse')) {
      context.handle(
          _verseMeta, verse.isAcceptableOrUnknown(data['verse']!, _verseMeta));
    } else if (isInserting) {
      context.missing(_verseMeta);
    }
    if (data.containsKey('text_content')) {
      context.handle(
          _textContentMeta,
          textContent.isAcceptableOrUnknown(
              data['text_content']!, _textContentMeta));
    } else if (isInserting) {
      context.missing(_textContentMeta);
    }
    if (data.containsKey('text_content_normalized')) {
      context.handle(
          _textContentNormalizedMeta,
          textContentNormalized.isAcceptableOrUnknown(
              data['text_content_normalized']!, _textContentNormalizedMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('note_text')) {
      context.handle(_noteTextMeta,
          noteText.isAcceptableOrUnknown(data['note_text']!, _noteTextMeta));
    }
    if (data.containsKey('note_color')) {
      context.handle(_noteColorMeta,
          noteColor.isAcceptableOrUnknown(data['note_color']!, _noteColorMeta));
    }
    if (data.containsKey('is_chapter_read')) {
      context.handle(
          _isChapterReadMeta,
          isChapterRead.isAcceptableOrUnknown(
              data['is_chapter_read']!, _isChapterReadMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Verse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Verse(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      book: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book'])!,
      chapter: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chapter'])!,
      verse: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}verse'])!,
      textContent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text_content'])!,
      textContentNormalized: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}text_content_normalized'])!,
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      noteText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_text']),
      noteColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_color']),
      isChapterRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_chapter_read'])!,
    );
  }

  @override
  $VersesTable createAlias(String alias) {
    return $VersesTable(attachedDatabase, alias);
  }
}

class Verse extends DataClass implements Insertable<Verse> {
  final int id;
  final String book;
  final int chapter;
  final int verse;
  final String textContent;
  final String textContentNormalized;
  final bool isFavorite;
  final String? noteText;
  final String? noteColor;
  final bool isChapterRead;
  const Verse(
      {required this.id,
      required this.book,
      required this.chapter,
      required this.verse,
      required this.textContent,
      required this.textContentNormalized,
      required this.isFavorite,
      this.noteText,
      this.noteColor,
      required this.isChapterRead});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book'] = Variable<String>(book);
    map['chapter'] = Variable<int>(chapter);
    map['verse'] = Variable<int>(verse);
    map['text_content'] = Variable<String>(textContent);
    map['text_content_normalized'] = Variable<String>(textContentNormalized);
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || noteText != null) {
      map['note_text'] = Variable<String>(noteText);
    }
    if (!nullToAbsent || noteColor != null) {
      map['note_color'] = Variable<String>(noteColor);
    }
    map['is_chapter_read'] = Variable<bool>(isChapterRead);
    return map;
  }

  VersesCompanion toCompanion(bool nullToAbsent) {
    return VersesCompanion(
      id: Value(id),
      book: Value(book),
      chapter: Value(chapter),
      verse: Value(verse),
      textContent: Value(textContent),
      textContentNormalized: Value(textContentNormalized),
      isFavorite: Value(isFavorite),
      noteText: noteText == null && nullToAbsent
          ? const Value.absent()
          : Value(noteText),
      noteColor: noteColor == null && nullToAbsent
          ? const Value.absent()
          : Value(noteColor),
      isChapterRead: Value(isChapterRead),
    );
  }

  factory Verse.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Verse(
      id: serializer.fromJson<int>(json['id']),
      book: serializer.fromJson<String>(json['book']),
      chapter: serializer.fromJson<int>(json['chapter']),
      verse: serializer.fromJson<int>(json['verse']),
      textContent: serializer.fromJson<String>(json['textContent']),
      textContentNormalized:
          serializer.fromJson<String>(json['textContentNormalized']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      noteText: serializer.fromJson<String?>(json['noteText']),
      noteColor: serializer.fromJson<String?>(json['noteColor']),
      isChapterRead: serializer.fromJson<bool>(json['isChapterRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'book': serializer.toJson<String>(book),
      'chapter': serializer.toJson<int>(chapter),
      'verse': serializer.toJson<int>(verse),
      'textContent': serializer.toJson<String>(textContent),
      'textContentNormalized': serializer.toJson<String>(textContentNormalized),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'noteText': serializer.toJson<String?>(noteText),
      'noteColor': serializer.toJson<String?>(noteColor),
      'isChapterRead': serializer.toJson<bool>(isChapterRead),
    };
  }

  Verse copyWith(
          {int? id,
          String? book,
          int? chapter,
          int? verse,
          String? textContent,
          String? textContentNormalized,
          bool? isFavorite,
          Value<String?> noteText = const Value.absent(),
          Value<String?> noteColor = const Value.absent(),
          bool? isChapterRead}) =>
      Verse(
        id: id ?? this.id,
        book: book ?? this.book,
        chapter: chapter ?? this.chapter,
        verse: verse ?? this.verse,
        textContent: textContent ?? this.textContent,
        textContentNormalized:
            textContentNormalized ?? this.textContentNormalized,
        isFavorite: isFavorite ?? this.isFavorite,
        noteText: noteText.present ? noteText.value : this.noteText,
        noteColor: noteColor.present ? noteColor.value : this.noteColor,
        isChapterRead: isChapterRead ?? this.isChapterRead,
      );
  Verse copyWithCompanion(VersesCompanion data) {
    return Verse(
      id: data.id.present ? data.id.value : this.id,
      book: data.book.present ? data.book.value : this.book,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      verse: data.verse.present ? data.verse.value : this.verse,
      textContent:
          data.textContent.present ? data.textContent.value : this.textContent,
      textContentNormalized: data.textContentNormalized.present
          ? data.textContentNormalized.value
          : this.textContentNormalized,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      noteText: data.noteText.present ? data.noteText.value : this.noteText,
      noteColor: data.noteColor.present ? data.noteColor.value : this.noteColor,
      isChapterRead: data.isChapterRead.present
          ? data.isChapterRead.value
          : this.isChapterRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Verse(')
          ..write('id: $id, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('verse: $verse, ')
          ..write('textContent: $textContent, ')
          ..write('textContentNormalized: $textContentNormalized, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('noteText: $noteText, ')
          ..write('noteColor: $noteColor, ')
          ..write('isChapterRead: $isChapterRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, book, chapter, verse, textContent,
      textContentNormalized, isFavorite, noteText, noteColor, isChapterRead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Verse &&
          other.id == this.id &&
          other.book == this.book &&
          other.chapter == this.chapter &&
          other.verse == this.verse &&
          other.textContent == this.textContent &&
          other.textContentNormalized == this.textContentNormalized &&
          other.isFavorite == this.isFavorite &&
          other.noteText == this.noteText &&
          other.noteColor == this.noteColor &&
          other.isChapterRead == this.isChapterRead);
}

class VersesCompanion extends UpdateCompanion<Verse> {
  final Value<int> id;
  final Value<String> book;
  final Value<int> chapter;
  final Value<int> verse;
  final Value<String> textContent;
  final Value<String> textContentNormalized;
  final Value<bool> isFavorite;
  final Value<String?> noteText;
  final Value<String?> noteColor;
  final Value<bool> isChapterRead;
  const VersesCompanion({
    this.id = const Value.absent(),
    this.book = const Value.absent(),
    this.chapter = const Value.absent(),
    this.verse = const Value.absent(),
    this.textContent = const Value.absent(),
    this.textContentNormalized = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.noteText = const Value.absent(),
    this.noteColor = const Value.absent(),
    this.isChapterRead = const Value.absent(),
  });
  VersesCompanion.insert({
    this.id = const Value.absent(),
    required String book,
    required int chapter,
    required int verse,
    required String textContent,
    this.textContentNormalized = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.noteText = const Value.absent(),
    this.noteColor = const Value.absent(),
    this.isChapterRead = const Value.absent(),
  })  : book = Value(book),
        chapter = Value(chapter),
        verse = Value(verse),
        textContent = Value(textContent);
  static Insertable<Verse> custom({
    Expression<int>? id,
    Expression<String>? book,
    Expression<int>? chapter,
    Expression<int>? verse,
    Expression<String>? textContent,
    Expression<String>? textContentNormalized,
    Expression<bool>? isFavorite,
    Expression<String>? noteText,
    Expression<String>? noteColor,
    Expression<bool>? isChapterRead,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (book != null) 'book': book,
      if (chapter != null) 'chapter': chapter,
      if (verse != null) 'verse': verse,
      if (textContent != null) 'text_content': textContent,
      if (textContentNormalized != null)
        'text_content_normalized': textContentNormalized,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (noteText != null) 'note_text': noteText,
      if (noteColor != null) 'note_color': noteColor,
      if (isChapterRead != null) 'is_chapter_read': isChapterRead,
    });
  }

  VersesCompanion copyWith(
      {Value<int>? id,
      Value<String>? book,
      Value<int>? chapter,
      Value<int>? verse,
      Value<String>? textContent,
      Value<String>? textContentNormalized,
      Value<bool>? isFavorite,
      Value<String?>? noteText,
      Value<String?>? noteColor,
      Value<bool>? isChapterRead}) {
    return VersesCompanion(
      id: id ?? this.id,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      textContent: textContent ?? this.textContent,
      textContentNormalized:
          textContentNormalized ?? this.textContentNormalized,
      isFavorite: isFavorite ?? this.isFavorite,
      noteText: noteText ?? this.noteText,
      noteColor: noteColor ?? this.noteColor,
      isChapterRead: isChapterRead ?? this.isChapterRead,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (book.present) {
      map['book'] = Variable<String>(book.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (verse.present) {
      map['verse'] = Variable<int>(verse.value);
    }
    if (textContent.present) {
      map['text_content'] = Variable<String>(textContent.value);
    }
    if (textContentNormalized.present) {
      map['text_content_normalized'] =
          Variable<String>(textContentNormalized.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (noteText.present) {
      map['note_text'] = Variable<String>(noteText.value);
    }
    if (noteColor.present) {
      map['note_color'] = Variable<String>(noteColor.value);
    }
    if (isChapterRead.present) {
      map['is_chapter_read'] = Variable<bool>(isChapterRead.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VersesCompanion(')
          ..write('id: $id, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('verse: $verse, ')
          ..write('textContent: $textContent, ')
          ..write('textContentNormalized: $textContentNormalized, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('noteText: $noteText, ')
          ..write('noteColor: $noteColor, ')
          ..write('isChapterRead: $isChapterRead')
          ..write(')'))
        .toString();
  }
}

class $PrayersTable extends Prayers with TableInfo<$PrayersTable, Prayer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dateAddedMeta =
      const VerificationMeta('dateAdded');
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
      'date_added', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _dateAnsweredMeta =
      const VerificationMeta('dateAnswered');
  @override
  late final GeneratedColumn<DateTime> dateAnswered = GeneratedColumn<DateTime>(
      'date_answered', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isAnsweredMeta =
      const VerificationMeta('isAnswered');
  @override
  late final GeneratedColumn<bool> isAnswered = GeneratedColumn<bool>(
      'is_answered', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_answered" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _hasReminderMeta =
      const VerificationMeta('hasReminder');
  @override
  late final GeneratedColumn<bool> hasReminder = GeneratedColumn<bool>(
      'has_reminder', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_reminder" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _reminderTimeMeta =
      const VerificationMeta('reminderTime');
  @override
  late final GeneratedColumn<DateTime> reminderTime = GeneratedColumn<DateTime>(
      'reminder_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _linkedVerseRefMeta =
      const VerificationMeta('linkedVerseRef');
  @override
  late final GeneratedColumn<String> linkedVerseRef = GeneratedColumn<String>(
      'linked_verse_ref', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _linkedVerseTextMeta =
      const VerificationMeta('linkedVerseText');
  @override
  late final GeneratedColumn<String> linkedVerseText = GeneratedColumn<String>(
      'linked_verse_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        priority,
        categoryId,
        dateAdded,
        dateAnswered,
        isAnswered,
        hasReminder,
        reminderTime,
        linkedVerseRef,
        linkedVerseText
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayers';
  @override
  VerificationContext validateIntegrity(Insertable<Prayer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('date_added')) {
      context.handle(_dateAddedMeta,
          dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta));
    }
    if (data.containsKey('date_answered')) {
      context.handle(
          _dateAnsweredMeta,
          dateAnswered.isAcceptableOrUnknown(
              data['date_answered']!, _dateAnsweredMeta));
    }
    if (data.containsKey('is_answered')) {
      context.handle(
          _isAnsweredMeta,
          isAnswered.isAcceptableOrUnknown(
              data['is_answered']!, _isAnsweredMeta));
    }
    if (data.containsKey('has_reminder')) {
      context.handle(
          _hasReminderMeta,
          hasReminder.isAcceptableOrUnknown(
              data['has_reminder']!, _hasReminderMeta));
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
          _reminderTimeMeta,
          reminderTime.isAcceptableOrUnknown(
              data['reminder_time']!, _reminderTimeMeta));
    }
    if (data.containsKey('linked_verse_ref')) {
      context.handle(
          _linkedVerseRefMeta,
          linkedVerseRef.isAcceptableOrUnknown(
              data['linked_verse_ref']!, _linkedVerseRefMeta));
    }
    if (data.containsKey('linked_verse_text')) {
      context.handle(
          _linkedVerseTextMeta,
          linkedVerseText.isAcceptableOrUnknown(
              data['linked_verse_text']!, _linkedVerseTextMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Prayer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Prayer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      dateAdded: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_added'])!,
      dateAnswered: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_answered']),
      isAnswered: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_answered'])!,
      hasReminder: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_reminder'])!,
      reminderTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}reminder_time']),
      linkedVerseRef: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}linked_verse_ref']),
      linkedVerseText: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}linked_verse_text']),
    );
  }

  @override
  $PrayersTable createAlias(String alias) {
    return $PrayersTable(attachedDatabase, alias);
  }
}

class Prayer extends DataClass implements Insertable<Prayer> {
  final int id;
  final String title;
  final String? description;
  final int priority;
  final int? categoryId;
  final DateTime dateAdded;
  final DateTime? dateAnswered;
  final bool isAnswered;
  final bool hasReminder;
  final DateTime? reminderTime;
  final String? linkedVerseRef;
  final String? linkedVerseText;
  const Prayer(
      {required this.id,
      required this.title,
      this.description,
      required this.priority,
      this.categoryId,
      required this.dateAdded,
      this.dateAnswered,
      required this.isAnswered,
      required this.hasReminder,
      this.reminderTime,
      this.linkedVerseRef,
      this.linkedVerseText});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['date_added'] = Variable<DateTime>(dateAdded);
    if (!nullToAbsent || dateAnswered != null) {
      map['date_answered'] = Variable<DateTime>(dateAnswered);
    }
    map['is_answered'] = Variable<bool>(isAnswered);
    map['has_reminder'] = Variable<bool>(hasReminder);
    if (!nullToAbsent || reminderTime != null) {
      map['reminder_time'] = Variable<DateTime>(reminderTime);
    }
    if (!nullToAbsent || linkedVerseRef != null) {
      map['linked_verse_ref'] = Variable<String>(linkedVerseRef);
    }
    if (!nullToAbsent || linkedVerseText != null) {
      map['linked_verse_text'] = Variable<String>(linkedVerseText);
    }
    return map;
  }

  PrayersCompanion toCompanion(bool nullToAbsent) {
    return PrayersCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      priority: Value(priority),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      dateAdded: Value(dateAdded),
      dateAnswered: dateAnswered == null && nullToAbsent
          ? const Value.absent()
          : Value(dateAnswered),
      isAnswered: Value(isAnswered),
      hasReminder: Value(hasReminder),
      reminderTime: reminderTime == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderTime),
      linkedVerseRef: linkedVerseRef == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedVerseRef),
      linkedVerseText: linkedVerseText == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedVerseText),
    );
  }

  factory Prayer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Prayer(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      priority: serializer.fromJson<int>(json['priority']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      dateAdded: serializer.fromJson<DateTime>(json['dateAdded']),
      dateAnswered: serializer.fromJson<DateTime?>(json['dateAnswered']),
      isAnswered: serializer.fromJson<bool>(json['isAnswered']),
      hasReminder: serializer.fromJson<bool>(json['hasReminder']),
      reminderTime: serializer.fromJson<DateTime?>(json['reminderTime']),
      linkedVerseRef: serializer.fromJson<String?>(json['linkedVerseRef']),
      linkedVerseText: serializer.fromJson<String?>(json['linkedVerseText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'priority': serializer.toJson<int>(priority),
      'categoryId': serializer.toJson<int?>(categoryId),
      'dateAdded': serializer.toJson<DateTime>(dateAdded),
      'dateAnswered': serializer.toJson<DateTime?>(dateAnswered),
      'isAnswered': serializer.toJson<bool>(isAnswered),
      'hasReminder': serializer.toJson<bool>(hasReminder),
      'reminderTime': serializer.toJson<DateTime?>(reminderTime),
      'linkedVerseRef': serializer.toJson<String?>(linkedVerseRef),
      'linkedVerseText': serializer.toJson<String?>(linkedVerseText),
    };
  }

  Prayer copyWith(
          {int? id,
          String? title,
          Value<String?> description = const Value.absent(),
          int? priority,
          Value<int?> categoryId = const Value.absent(),
          DateTime? dateAdded,
          Value<DateTime?> dateAnswered = const Value.absent(),
          bool? isAnswered,
          bool? hasReminder,
          Value<DateTime?> reminderTime = const Value.absent(),
          Value<String?> linkedVerseRef = const Value.absent(),
          Value<String?> linkedVerseText = const Value.absent()}) =>
      Prayer(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        priority: priority ?? this.priority,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        dateAdded: dateAdded ?? this.dateAdded,
        dateAnswered:
            dateAnswered.present ? dateAnswered.value : this.dateAnswered,
        isAnswered: isAnswered ?? this.isAnswered,
        hasReminder: hasReminder ?? this.hasReminder,
        reminderTime:
            reminderTime.present ? reminderTime.value : this.reminderTime,
        linkedVerseRef:
            linkedVerseRef.present ? linkedVerseRef.value : this.linkedVerseRef,
        linkedVerseText: linkedVerseText.present
            ? linkedVerseText.value
            : this.linkedVerseText,
      );
  Prayer copyWithCompanion(PrayersCompanion data) {
    return Prayer(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      priority: data.priority.present ? data.priority.value : this.priority,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
      dateAnswered: data.dateAnswered.present
          ? data.dateAnswered.value
          : this.dateAnswered,
      isAnswered:
          data.isAnswered.present ? data.isAnswered.value : this.isAnswered,
      hasReminder:
          data.hasReminder.present ? data.hasReminder.value : this.hasReminder,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      linkedVerseRef: data.linkedVerseRef.present
          ? data.linkedVerseRef.value
          : this.linkedVerseRef,
      linkedVerseText: data.linkedVerseText.present
          ? data.linkedVerseText.value
          : this.linkedVerseText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Prayer(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('categoryId: $categoryId, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('dateAnswered: $dateAnswered, ')
          ..write('isAnswered: $isAnswered, ')
          ..write('hasReminder: $hasReminder, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('linkedVerseRef: $linkedVerseRef, ')
          ..write('linkedVerseText: $linkedVerseText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      description,
      priority,
      categoryId,
      dateAdded,
      dateAnswered,
      isAnswered,
      hasReminder,
      reminderTime,
      linkedVerseRef,
      linkedVerseText);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Prayer &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.priority == this.priority &&
          other.categoryId == this.categoryId &&
          other.dateAdded == this.dateAdded &&
          other.dateAnswered == this.dateAnswered &&
          other.isAnswered == this.isAnswered &&
          other.hasReminder == this.hasReminder &&
          other.reminderTime == this.reminderTime &&
          other.linkedVerseRef == this.linkedVerseRef &&
          other.linkedVerseText == this.linkedVerseText);
}

class PrayersCompanion extends UpdateCompanion<Prayer> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> priority;
  final Value<int?> categoryId;
  final Value<DateTime> dateAdded;
  final Value<DateTime?> dateAnswered;
  final Value<bool> isAnswered;
  final Value<bool> hasReminder;
  final Value<DateTime?> reminderTime;
  final Value<String?> linkedVerseRef;
  final Value<String?> linkedVerseText;
  const PrayersCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.dateAnswered = const Value.absent(),
    this.isAnswered = const Value.absent(),
    this.hasReminder = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.linkedVerseRef = const Value.absent(),
    this.linkedVerseText = const Value.absent(),
  });
  PrayersCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.dateAnswered = const Value.absent(),
    this.isAnswered = const Value.absent(),
    this.hasReminder = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.linkedVerseRef = const Value.absent(),
    this.linkedVerseText = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Prayer> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? priority,
    Expression<int>? categoryId,
    Expression<DateTime>? dateAdded,
    Expression<DateTime>? dateAnswered,
    Expression<bool>? isAnswered,
    Expression<bool>? hasReminder,
    Expression<DateTime>? reminderTime,
    Expression<String>? linkedVerseRef,
    Expression<String>? linkedVerseText,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (priority != null) 'priority': priority,
      if (categoryId != null) 'category_id': categoryId,
      if (dateAdded != null) 'date_added': dateAdded,
      if (dateAnswered != null) 'date_answered': dateAnswered,
      if (isAnswered != null) 'is_answered': isAnswered,
      if (hasReminder != null) 'has_reminder': hasReminder,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (linkedVerseRef != null) 'linked_verse_ref': linkedVerseRef,
      if (linkedVerseText != null) 'linked_verse_text': linkedVerseText,
    });
  }

  PrayersCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<int>? priority,
      Value<int?>? categoryId,
      Value<DateTime>? dateAdded,
      Value<DateTime?>? dateAnswered,
      Value<bool>? isAnswered,
      Value<bool>? hasReminder,
      Value<DateTime?>? reminderTime,
      Value<String?>? linkedVerseRef,
      Value<String?>? linkedVerseText}) {
    return PrayersCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      dateAdded: dateAdded ?? this.dateAdded,
      dateAnswered: dateAnswered ?? this.dateAnswered,
      isAnswered: isAnswered ?? this.isAnswered,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderTime: reminderTime ?? this.reminderTime,
      linkedVerseRef: linkedVerseRef ?? this.linkedVerseRef,
      linkedVerseText: linkedVerseText ?? this.linkedVerseText,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    if (dateAnswered.present) {
      map['date_answered'] = Variable<DateTime>(dateAnswered.value);
    }
    if (isAnswered.present) {
      map['is_answered'] = Variable<bool>(isAnswered.value);
    }
    if (hasReminder.present) {
      map['has_reminder'] = Variable<bool>(hasReminder.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<DateTime>(reminderTime.value);
    }
    if (linkedVerseRef.present) {
      map['linked_verse_ref'] = Variable<String>(linkedVerseRef.value);
    }
    if (linkedVerseText.present) {
      map['linked_verse_text'] = Variable<String>(linkedVerseText.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayersCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('categoryId: $categoryId, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('dateAnswered: $dateAnswered, ')
          ..write('isAnswered: $isAnswered, ')
          ..write('hasReminder: $hasReminder, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('linkedVerseRef: $linkedVerseRef, ')
          ..write('linkedVerseText: $linkedVerseText')
          ..write(')'))
        .toString();
  }
}

class $PrayerCategoriesTable extends PrayerCategories
    with TableInfo<$PrayerCategoriesTable, PrayerCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayerCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('0xFFB39DDB'));
  @override
  List<GeneratedColumn> get $columns => [id, name, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayer_categories';
  @override
  VerificationContext validateIntegrity(Insertable<PrayerCategory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrayerCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrayerCategory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color'])!,
    );
  }

  @override
  $PrayerCategoriesTable createAlias(String alias) {
    return $PrayerCategoriesTable(attachedDatabase, alias);
  }
}

class PrayerCategory extends DataClass implements Insertable<PrayerCategory> {
  final int id;
  final String name;
  final String color;
  const PrayerCategory(
      {required this.id, required this.name, required this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<String>(color);
    return map;
  }

  PrayerCategoriesCompanion toCompanion(bool nullToAbsent) {
    return PrayerCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
    );
  }

  factory PrayerCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrayerCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String>(color),
    };
  }

  PrayerCategory copyWith({int? id, String? name, String? color}) =>
      PrayerCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
      );
  PrayerCategory copyWithCompanion(PrayerCategoriesCompanion data) {
    return PrayerCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrayerCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrayerCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color);
}

class PrayerCategoriesCompanion extends UpdateCompanion<PrayerCategory> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> color;
  const PrayerCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
  });
  PrayerCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
  }) : name = Value(name);
  static Insertable<PrayerCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? color,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
    });
  }

  PrayerCategoriesCompanion copyWith(
      {Value<int>? id, Value<String>? name, Value<String>? color}) {
    return PrayerCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayerCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }
}

class $FavoriteCollectionsTable extends FavoriteCollections
    with TableInfo<$FavoriteCollectionsTable, FavoriteCollection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteCollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#4E342E'));
  @override
  List<GeneratedColumn> get $columns => [id, name, colorHex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_collections';
  @override
  VerificationContext validateIntegrity(Insertable<FavoriteCollection> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FavoriteCollection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteCollection(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
    );
  }

  @override
  $FavoriteCollectionsTable createAlias(String alias) {
    return $FavoriteCollectionsTable(attachedDatabase, alias);
  }
}

class FavoriteCollection extends DataClass
    implements Insertable<FavoriteCollection> {
  final int id;
  final String name;
  final String colorHex;
  const FavoriteCollection(
      {required this.id, required this.name, required this.colorHex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color_hex'] = Variable<String>(colorHex);
    return map;
  }

  FavoriteCollectionsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteCollectionsCompanion(
      id: Value(id),
      name: Value(name),
      colorHex: Value(colorHex),
    );
  }

  factory FavoriteCollection.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteCollection(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'colorHex': serializer.toJson<String>(colorHex),
    };
  }

  FavoriteCollection copyWith({int? id, String? name, String? colorHex}) =>
      FavoriteCollection(
        id: id ?? this.id,
        name: name ?? this.name,
        colorHex: colorHex ?? this.colorHex,
      );
  FavoriteCollection copyWithCompanion(FavoriteCollectionsCompanion data) {
    return FavoriteCollection(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteCollection(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorHex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteCollection &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorHex == this.colorHex);
}

class FavoriteCollectionsCompanion extends UpdateCompanion<FavoriteCollection> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> colorHex;
  const FavoriteCollectionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorHex = const Value.absent(),
  });
  FavoriteCollectionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.colorHex = const Value.absent(),
  }) : name = Value(name);
  static Insertable<FavoriteCollection> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? colorHex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorHex != null) 'color_hex': colorHex,
    });
  }

  FavoriteCollectionsCompanion copyWith(
      {Value<int>? id, Value<String>? name, Value<String>? colorHex}) {
    return FavoriteCollectionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteCollectionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex')
          ..write(')'))
        .toString();
  }
}

class $CollectionVersesTable extends CollectionVerses
    with TableInfo<$CollectionVersesTable, CollectionVerse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionVersesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _collectionIdMeta =
      const VerificationMeta('collectionId');
  @override
  late final GeneratedColumn<int> collectionId = GeneratedColumn<int>(
      'collection_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _verseIdMeta =
      const VerificationMeta('verseId');
  @override
  late final GeneratedColumn<int> verseId = GeneratedColumn<int>(
      'verse_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [collectionId, verseId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection_verses';
  @override
  VerificationContext validateIntegrity(Insertable<CollectionVerse> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('collection_id')) {
      context.handle(
          _collectionIdMeta,
          collectionId.isAcceptableOrUnknown(
              data['collection_id']!, _collectionIdMeta));
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('verse_id')) {
      context.handle(_verseIdMeta,
          verseId.isAcceptableOrUnknown(data['verse_id']!, _verseIdMeta));
    } else if (isInserting) {
      context.missing(_verseIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {collectionId, verseId};
  @override
  CollectionVerse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionVerse(
      collectionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}collection_id'])!,
      verseId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}verse_id'])!,
    );
  }

  @override
  $CollectionVersesTable createAlias(String alias) {
    return $CollectionVersesTable(attachedDatabase, alias);
  }
}

class CollectionVerse extends DataClass implements Insertable<CollectionVerse> {
  final int collectionId;
  final int verseId;
  const CollectionVerse({required this.collectionId, required this.verseId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['collection_id'] = Variable<int>(collectionId);
    map['verse_id'] = Variable<int>(verseId);
    return map;
  }

  CollectionVersesCompanion toCompanion(bool nullToAbsent) {
    return CollectionVersesCompanion(
      collectionId: Value(collectionId),
      verseId: Value(verseId),
    );
  }

  factory CollectionVerse.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionVerse(
      collectionId: serializer.fromJson<int>(json['collectionId']),
      verseId: serializer.fromJson<int>(json['verseId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'collectionId': serializer.toJson<int>(collectionId),
      'verseId': serializer.toJson<int>(verseId),
    };
  }

  CollectionVerse copyWith({int? collectionId, int? verseId}) =>
      CollectionVerse(
        collectionId: collectionId ?? this.collectionId,
        verseId: verseId ?? this.verseId,
      );
  CollectionVerse copyWithCompanion(CollectionVersesCompanion data) {
    return CollectionVerse(
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      verseId: data.verseId.present ? data.verseId.value : this.verseId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionVerse(')
          ..write('collectionId: $collectionId, ')
          ..write('verseId: $verseId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(collectionId, verseId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionVerse &&
          other.collectionId == this.collectionId &&
          other.verseId == this.verseId);
}

class CollectionVersesCompanion extends UpdateCompanion<CollectionVerse> {
  final Value<int> collectionId;
  final Value<int> verseId;
  final Value<int> rowid;
  const CollectionVersesCompanion({
    this.collectionId = const Value.absent(),
    this.verseId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionVersesCompanion.insert({
    required int collectionId,
    required int verseId,
    this.rowid = const Value.absent(),
  })  : collectionId = Value(collectionId),
        verseId = Value(verseId);
  static Insertable<CollectionVerse> custom({
    Expression<int>? collectionId,
    Expression<int>? verseId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (collectionId != null) 'collection_id': collectionId,
      if (verseId != null) 'verse_id': verseId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionVersesCompanion copyWith(
      {Value<int>? collectionId, Value<int>? verseId, Value<int>? rowid}) {
    return CollectionVersesCompanion(
      collectionId: collectionId ?? this.collectionId,
      verseId: verseId ?? this.verseId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (collectionId.present) {
      map['collection_id'] = Variable<int>(collectionId.value);
    }
    if (verseId.present) {
      map['verse_id'] = Variable<int>(verseId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionVersesCompanion(')
          ..write('collectionId: $collectionId, ')
          ..write('verseId: $verseId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VersesTable verses = $VersesTable(this);
  late final $PrayersTable prayers = $PrayersTable(this);
  late final $PrayerCategoriesTable prayerCategories =
      $PrayerCategoriesTable(this);
  late final $FavoriteCollectionsTable favoriteCollections =
      $FavoriteCollectionsTable(this);
  late final $CollectionVersesTable collectionVerses =
      $CollectionVersesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        verses,
        prayers,
        prayerCategories,
        favoriteCollections,
        collectionVerses
      ];
}

typedef $$VersesTableCreateCompanionBuilder = VersesCompanion Function({
  Value<int> id,
  required String book,
  required int chapter,
  required int verse,
  required String textContent,
  Value<String> textContentNormalized,
  Value<bool> isFavorite,
  Value<String?> noteText,
  Value<String?> noteColor,
  Value<bool> isChapterRead,
});
typedef $$VersesTableUpdateCompanionBuilder = VersesCompanion Function({
  Value<int> id,
  Value<String> book,
  Value<int> chapter,
  Value<int> verse,
  Value<String> textContent,
  Value<String> textContentNormalized,
  Value<bool> isFavorite,
  Value<String?> noteText,
  Value<String?> noteColor,
  Value<bool> isChapterRead,
});

class $$VersesTableFilterComposer
    extends Composer<_$AppDatabase, $VersesTable> {
  $$VersesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get book => $composableBuilder(
      column: $table.book, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get chapter => $composableBuilder(
      column: $table.chapter, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get verse => $composableBuilder(
      column: $table.verse, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get textContent => $composableBuilder(
      column: $table.textContent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get textContentNormalized => $composableBuilder(
      column: $table.textContentNormalized,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get noteText => $composableBuilder(
      column: $table.noteText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get noteColor => $composableBuilder(
      column: $table.noteColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isChapterRead => $composableBuilder(
      column: $table.isChapterRead, builder: (column) => ColumnFilters(column));
}

class $$VersesTableOrderingComposer
    extends Composer<_$AppDatabase, $VersesTable> {
  $$VersesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get book => $composableBuilder(
      column: $table.book, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get chapter => $composableBuilder(
      column: $table.chapter, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get verse => $composableBuilder(
      column: $table.verse, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textContent => $composableBuilder(
      column: $table.textContent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textContentNormalized => $composableBuilder(
      column: $table.textContentNormalized,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get noteText => $composableBuilder(
      column: $table.noteText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get noteColor => $composableBuilder(
      column: $table.noteColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isChapterRead => $composableBuilder(
      column: $table.isChapterRead,
      builder: (column) => ColumnOrderings(column));
}

class $$VersesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VersesTable> {
  $$VersesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get book =>
      $composableBuilder(column: $table.book, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get verse =>
      $composableBuilder(column: $table.verse, builder: (column) => column);

  GeneratedColumn<String> get textContent => $composableBuilder(
      column: $table.textContent, builder: (column) => column);

  GeneratedColumn<String> get textContentNormalized => $composableBuilder(
      column: $table.textContentNormalized, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<String> get noteText =>
      $composableBuilder(column: $table.noteText, builder: (column) => column);

  GeneratedColumn<String> get noteColor =>
      $composableBuilder(column: $table.noteColor, builder: (column) => column);

  GeneratedColumn<bool> get isChapterRead => $composableBuilder(
      column: $table.isChapterRead, builder: (column) => column);
}

class $$VersesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VersesTable,
    Verse,
    $$VersesTableFilterComposer,
    $$VersesTableOrderingComposer,
    $$VersesTableAnnotationComposer,
    $$VersesTableCreateCompanionBuilder,
    $$VersesTableUpdateCompanionBuilder,
    (Verse, BaseReferences<_$AppDatabase, $VersesTable, Verse>),
    Verse,
    PrefetchHooks Function()> {
  $$VersesTableTableManager(_$AppDatabase db, $VersesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VersesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VersesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VersesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> book = const Value.absent(),
            Value<int> chapter = const Value.absent(),
            Value<int> verse = const Value.absent(),
            Value<String> textContent = const Value.absent(),
            Value<String> textContentNormalized = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<String?> noteText = const Value.absent(),
            Value<String?> noteColor = const Value.absent(),
            Value<bool> isChapterRead = const Value.absent(),
          }) =>
              VersesCompanion(
            id: id,
            book: book,
            chapter: chapter,
            verse: verse,
            textContent: textContent,
            textContentNormalized: textContentNormalized,
            isFavorite: isFavorite,
            noteText: noteText,
            noteColor: noteColor,
            isChapterRead: isChapterRead,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String book,
            required int chapter,
            required int verse,
            required String textContent,
            Value<String> textContentNormalized = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<String?> noteText = const Value.absent(),
            Value<String?> noteColor = const Value.absent(),
            Value<bool> isChapterRead = const Value.absent(),
          }) =>
              VersesCompanion.insert(
            id: id,
            book: book,
            chapter: chapter,
            verse: verse,
            textContent: textContent,
            textContentNormalized: textContentNormalized,
            isFavorite: isFavorite,
            noteText: noteText,
            noteColor: noteColor,
            isChapterRead: isChapterRead,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VersesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VersesTable,
    Verse,
    $$VersesTableFilterComposer,
    $$VersesTableOrderingComposer,
    $$VersesTableAnnotationComposer,
    $$VersesTableCreateCompanionBuilder,
    $$VersesTableUpdateCompanionBuilder,
    (Verse, BaseReferences<_$AppDatabase, $VersesTable, Verse>),
    Verse,
    PrefetchHooks Function()>;
typedef $$PrayersTableCreateCompanionBuilder = PrayersCompanion Function({
  Value<int> id,
  required String title,
  Value<String?> description,
  Value<int> priority,
  Value<int?> categoryId,
  Value<DateTime> dateAdded,
  Value<DateTime?> dateAnswered,
  Value<bool> isAnswered,
  Value<bool> hasReminder,
  Value<DateTime?> reminderTime,
  Value<String?> linkedVerseRef,
  Value<String?> linkedVerseText,
});
typedef $$PrayersTableUpdateCompanionBuilder = PrayersCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String?> description,
  Value<int> priority,
  Value<int?> categoryId,
  Value<DateTime> dateAdded,
  Value<DateTime?> dateAnswered,
  Value<bool> isAnswered,
  Value<bool> hasReminder,
  Value<DateTime?> reminderTime,
  Value<String?> linkedVerseRef,
  Value<String?> linkedVerseText,
});

class $$PrayersTableFilterComposer
    extends Composer<_$AppDatabase, $PrayersTable> {
  $$PrayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dateAdded => $composableBuilder(
      column: $table.dateAdded, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dateAnswered => $composableBuilder(
      column: $table.dateAnswered, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isAnswered => $composableBuilder(
      column: $table.isAnswered, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasReminder => $composableBuilder(
      column: $table.hasReminder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get reminderTime => $composableBuilder(
      column: $table.reminderTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get linkedVerseRef => $composableBuilder(
      column: $table.linkedVerseRef,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get linkedVerseText => $composableBuilder(
      column: $table.linkedVerseText,
      builder: (column) => ColumnFilters(column));
}

class $$PrayersTableOrderingComposer
    extends Composer<_$AppDatabase, $PrayersTable> {
  $$PrayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dateAdded => $composableBuilder(
      column: $table.dateAdded, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dateAnswered => $composableBuilder(
      column: $table.dateAnswered,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isAnswered => $composableBuilder(
      column: $table.isAnswered, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasReminder => $composableBuilder(
      column: $table.hasReminder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get reminderTime => $composableBuilder(
      column: $table.reminderTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get linkedVerseRef => $composableBuilder(
      column: $table.linkedVerseRef,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get linkedVerseText => $composableBuilder(
      column: $table.linkedVerseText,
      builder: (column) => ColumnOrderings(column));
}

class $$PrayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrayersTable> {
  $$PrayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<DateTime> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  GeneratedColumn<DateTime> get dateAnswered => $composableBuilder(
      column: $table.dateAnswered, builder: (column) => column);

  GeneratedColumn<bool> get isAnswered => $composableBuilder(
      column: $table.isAnswered, builder: (column) => column);

  GeneratedColumn<bool> get hasReminder => $composableBuilder(
      column: $table.hasReminder, builder: (column) => column);

  GeneratedColumn<DateTime> get reminderTime => $composableBuilder(
      column: $table.reminderTime, builder: (column) => column);

  GeneratedColumn<String> get linkedVerseRef => $composableBuilder(
      column: $table.linkedVerseRef, builder: (column) => column);

  GeneratedColumn<String> get linkedVerseText => $composableBuilder(
      column: $table.linkedVerseText, builder: (column) => column);
}

class $$PrayersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PrayersTable,
    Prayer,
    $$PrayersTableFilterComposer,
    $$PrayersTableOrderingComposer,
    $$PrayersTableAnnotationComposer,
    $$PrayersTableCreateCompanionBuilder,
    $$PrayersTableUpdateCompanionBuilder,
    (Prayer, BaseReferences<_$AppDatabase, $PrayersTable, Prayer>),
    Prayer,
    PrefetchHooks Function()> {
  $$PrayersTableTableManager(_$AppDatabase db, $PrayersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<DateTime> dateAdded = const Value.absent(),
            Value<DateTime?> dateAnswered = const Value.absent(),
            Value<bool> isAnswered = const Value.absent(),
            Value<bool> hasReminder = const Value.absent(),
            Value<DateTime?> reminderTime = const Value.absent(),
            Value<String?> linkedVerseRef = const Value.absent(),
            Value<String?> linkedVerseText = const Value.absent(),
          }) =>
              PrayersCompanion(
            id: id,
            title: title,
            description: description,
            priority: priority,
            categoryId: categoryId,
            dateAdded: dateAdded,
            dateAnswered: dateAnswered,
            isAnswered: isAnswered,
            hasReminder: hasReminder,
            reminderTime: reminderTime,
            linkedVerseRef: linkedVerseRef,
            linkedVerseText: linkedVerseText,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String?> description = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<DateTime> dateAdded = const Value.absent(),
            Value<DateTime?> dateAnswered = const Value.absent(),
            Value<bool> isAnswered = const Value.absent(),
            Value<bool> hasReminder = const Value.absent(),
            Value<DateTime?> reminderTime = const Value.absent(),
            Value<String?> linkedVerseRef = const Value.absent(),
            Value<String?> linkedVerseText = const Value.absent(),
          }) =>
              PrayersCompanion.insert(
            id: id,
            title: title,
            description: description,
            priority: priority,
            categoryId: categoryId,
            dateAdded: dateAdded,
            dateAnswered: dateAnswered,
            isAnswered: isAnswered,
            hasReminder: hasReminder,
            reminderTime: reminderTime,
            linkedVerseRef: linkedVerseRef,
            linkedVerseText: linkedVerseText,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PrayersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PrayersTable,
    Prayer,
    $$PrayersTableFilterComposer,
    $$PrayersTableOrderingComposer,
    $$PrayersTableAnnotationComposer,
    $$PrayersTableCreateCompanionBuilder,
    $$PrayersTableUpdateCompanionBuilder,
    (Prayer, BaseReferences<_$AppDatabase, $PrayersTable, Prayer>),
    Prayer,
    PrefetchHooks Function()>;
typedef $$PrayerCategoriesTableCreateCompanionBuilder
    = PrayerCategoriesCompanion Function({
  Value<int> id,
  required String name,
  Value<String> color,
});
typedef $$PrayerCategoriesTableUpdateCompanionBuilder
    = PrayerCategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> color,
});

class $$PrayerCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $PrayerCategoriesTable> {
  $$PrayerCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));
}

class $$PrayerCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PrayerCategoriesTable> {
  $$PrayerCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));
}

class $$PrayerCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrayerCategoriesTable> {
  $$PrayerCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);
}

class $$PrayerCategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PrayerCategoriesTable,
    PrayerCategory,
    $$PrayerCategoriesTableFilterComposer,
    $$PrayerCategoriesTableOrderingComposer,
    $$PrayerCategoriesTableAnnotationComposer,
    $$PrayerCategoriesTableCreateCompanionBuilder,
    $$PrayerCategoriesTableUpdateCompanionBuilder,
    (
      PrayerCategory,
      BaseReferences<_$AppDatabase, $PrayerCategoriesTable, PrayerCategory>
    ),
    PrayerCategory,
    PrefetchHooks Function()> {
  $$PrayerCategoriesTableTableManager(
      _$AppDatabase db, $PrayerCategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrayerCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrayerCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrayerCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> color = const Value.absent(),
          }) =>
              PrayerCategoriesCompanion(
            id: id,
            name: name,
            color: color,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> color = const Value.absent(),
          }) =>
              PrayerCategoriesCompanion.insert(
            id: id,
            name: name,
            color: color,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PrayerCategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PrayerCategoriesTable,
    PrayerCategory,
    $$PrayerCategoriesTableFilterComposer,
    $$PrayerCategoriesTableOrderingComposer,
    $$PrayerCategoriesTableAnnotationComposer,
    $$PrayerCategoriesTableCreateCompanionBuilder,
    $$PrayerCategoriesTableUpdateCompanionBuilder,
    (
      PrayerCategory,
      BaseReferences<_$AppDatabase, $PrayerCategoriesTable, PrayerCategory>
    ),
    PrayerCategory,
    PrefetchHooks Function()>;
typedef $$FavoriteCollectionsTableCreateCompanionBuilder
    = FavoriteCollectionsCompanion Function({
  Value<int> id,
  required String name,
  Value<String> colorHex,
});
typedef $$FavoriteCollectionsTableUpdateCompanionBuilder
    = FavoriteCollectionsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> colorHex,
});

class $$FavoriteCollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $FavoriteCollectionsTable> {
  $$FavoriteCollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));
}

class $$FavoriteCollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoriteCollectionsTable> {
  $$FavoriteCollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));
}

class $$FavoriteCollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoriteCollectionsTable> {
  $$FavoriteCollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);
}

class $$FavoriteCollectionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FavoriteCollectionsTable,
    FavoriteCollection,
    $$FavoriteCollectionsTableFilterComposer,
    $$FavoriteCollectionsTableOrderingComposer,
    $$FavoriteCollectionsTableAnnotationComposer,
    $$FavoriteCollectionsTableCreateCompanionBuilder,
    $$FavoriteCollectionsTableUpdateCompanionBuilder,
    (
      FavoriteCollection,
      BaseReferences<_$AppDatabase, $FavoriteCollectionsTable,
          FavoriteCollection>
    ),
    FavoriteCollection,
    PrefetchHooks Function()> {
  $$FavoriteCollectionsTableTableManager(
      _$AppDatabase db, $FavoriteCollectionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteCollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteCollectionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteCollectionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
          }) =>
              FavoriteCollectionsCompanion(
            id: id,
            name: name,
            colorHex: colorHex,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> colorHex = const Value.absent(),
          }) =>
              FavoriteCollectionsCompanion.insert(
            id: id,
            name: name,
            colorHex: colorHex,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FavoriteCollectionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FavoriteCollectionsTable,
    FavoriteCollection,
    $$FavoriteCollectionsTableFilterComposer,
    $$FavoriteCollectionsTableOrderingComposer,
    $$FavoriteCollectionsTableAnnotationComposer,
    $$FavoriteCollectionsTableCreateCompanionBuilder,
    $$FavoriteCollectionsTableUpdateCompanionBuilder,
    (
      FavoriteCollection,
      BaseReferences<_$AppDatabase, $FavoriteCollectionsTable,
          FavoriteCollection>
    ),
    FavoriteCollection,
    PrefetchHooks Function()>;
typedef $$CollectionVersesTableCreateCompanionBuilder
    = CollectionVersesCompanion Function({
  required int collectionId,
  required int verseId,
  Value<int> rowid,
});
typedef $$CollectionVersesTableUpdateCompanionBuilder
    = CollectionVersesCompanion Function({
  Value<int> collectionId,
  Value<int> verseId,
  Value<int> rowid,
});

class $$CollectionVersesTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionVersesTable> {
  $$CollectionVersesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get collectionId => $composableBuilder(
      column: $table.collectionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get verseId => $composableBuilder(
      column: $table.verseId, builder: (column) => ColumnFilters(column));
}

class $$CollectionVersesTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionVersesTable> {
  $$CollectionVersesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get collectionId => $composableBuilder(
      column: $table.collectionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get verseId => $composableBuilder(
      column: $table.verseId, builder: (column) => ColumnOrderings(column));
}

class $$CollectionVersesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionVersesTable> {
  $$CollectionVersesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get collectionId => $composableBuilder(
      column: $table.collectionId, builder: (column) => column);

  GeneratedColumn<int> get verseId =>
      $composableBuilder(column: $table.verseId, builder: (column) => column);
}

class $$CollectionVersesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CollectionVersesTable,
    CollectionVerse,
    $$CollectionVersesTableFilterComposer,
    $$CollectionVersesTableOrderingComposer,
    $$CollectionVersesTableAnnotationComposer,
    $$CollectionVersesTableCreateCompanionBuilder,
    $$CollectionVersesTableUpdateCompanionBuilder,
    (
      CollectionVerse,
      BaseReferences<_$AppDatabase, $CollectionVersesTable, CollectionVerse>
    ),
    CollectionVerse,
    PrefetchHooks Function()> {
  $$CollectionVersesTableTableManager(
      _$AppDatabase db, $CollectionVersesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionVersesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionVersesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionVersesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> collectionId = const Value.absent(),
            Value<int> verseId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CollectionVersesCompanion(
            collectionId: collectionId,
            verseId: verseId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int collectionId,
            required int verseId,
            Value<int> rowid = const Value.absent(),
          }) =>
              CollectionVersesCompanion.insert(
            collectionId: collectionId,
            verseId: verseId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CollectionVersesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CollectionVersesTable,
    CollectionVerse,
    $$CollectionVersesTableFilterComposer,
    $$CollectionVersesTableOrderingComposer,
    $$CollectionVersesTableAnnotationComposer,
    $$CollectionVersesTableCreateCompanionBuilder,
    $$CollectionVersesTableUpdateCompanionBuilder,
    (
      CollectionVerse,
      BaseReferences<_$AppDatabase, $CollectionVersesTable, CollectionVerse>
    ),
    CollectionVerse,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VersesTableTableManager get verses =>
      $$VersesTableTableManager(_db, _db.verses);
  $$PrayersTableTableManager get prayers =>
      $$PrayersTableTableManager(_db, _db.prayers);
  $$PrayerCategoriesTableTableManager get prayerCategories =>
      $$PrayerCategoriesTableTableManager(_db, _db.prayerCategories);
  $$FavoriteCollectionsTableTableManager get favoriteCollections =>
      $$FavoriteCollectionsTableTableManager(_db, _db.favoriteCollections);
  $$CollectionVersesTableTableManager get collectionVerses =>
      $$CollectionVersesTableTableManager(_db, _db.collectionVerses);
}
