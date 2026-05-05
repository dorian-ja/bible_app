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
          ..write('isFavorite: $isFavorite, ')
          ..write('noteText: $noteText, ')
          ..write('noteColor: $noteColor, ')
          ..write('isChapterRead: $isChapterRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, book, chapter, verse, textContent,
      isFavorite, noteText, noteColor, isChapterRead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Verse &&
          other.id == this.id &&
          other.book == this.book &&
          other.chapter == this.chapter &&
          other.verse == this.verse &&
          other.textContent == this.textContent &&
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
          ..write('isFavorite: $isFavorite, ')
          ..write('noteText: $noteText, ')
          ..write('noteColor: $noteColor, ')
          ..write('isChapterRead: $isChapterRead')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VersesTable verses = $VersesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [verses];
}

typedef $$VersesTableCreateCompanionBuilder = VersesCompanion Function({
  Value<int> id,
  required String book,
  required int chapter,
  required int verse,
  required String textContent,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VersesTableTableManager get verses =>
      $$VersesTableTableManager(_db, _db.verses);
}
