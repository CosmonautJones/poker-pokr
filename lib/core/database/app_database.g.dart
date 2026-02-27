// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameTypeMeta = const VerificationMeta(
    'gameType',
  );
  @override
  late final GeneratedColumn<int> gameType = GeneratedColumn<int>(
    'game_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<int> format = GeneratedColumn<int>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stakesMeta = const VerificationMeta('stakes');
  @override
  late final GeneratedColumn<String> stakes = GeneratedColumn<String>(
    'stakes',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buyInMeta = const VerificationMeta('buyIn');
  @override
  late final GeneratedColumn<double> buyIn = GeneratedColumn<double>(
    'buy_in',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashOutMeta = const VerificationMeta(
    'cashOut',
  );
  @override
  late final GeneratedColumn<double> cashOut = GeneratedColumn<double>(
    'cash_out',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profitLossMeta = const VerificationMeta(
    'profitLoss',
  );
  @override
  late final GeneratedColumn<double> profitLoss = GeneratedColumn<double>(
    'profit_loss',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hoursPlayedMeta = const VerificationMeta(
    'hoursPlayed',
  );
  @override
  late final GeneratedColumn<double> hoursPlayed = GeneratedColumn<double>(
    'hours_played',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    gameType,
    format,
    location,
    stakes,
    buyIn,
    cashOut,
    profitLoss,
    hoursPlayed,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('game_type')) {
      context.handle(
        _gameTypeMeta,
        gameType.isAcceptableOrUnknown(data['game_type']!, _gameTypeMeta),
      );
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('stakes')) {
      context.handle(
        _stakesMeta,
        stakes.isAcceptableOrUnknown(data['stakes']!, _stakesMeta),
      );
    } else if (isInserting) {
      context.missing(_stakesMeta);
    }
    if (data.containsKey('buy_in')) {
      context.handle(
        _buyInMeta,
        buyIn.isAcceptableOrUnknown(data['buy_in']!, _buyInMeta),
      );
    } else if (isInserting) {
      context.missing(_buyInMeta);
    }
    if (data.containsKey('cash_out')) {
      context.handle(
        _cashOutMeta,
        cashOut.isAcceptableOrUnknown(data['cash_out']!, _cashOutMeta),
      );
    } else if (isInserting) {
      context.missing(_cashOutMeta);
    }
    if (data.containsKey('profit_loss')) {
      context.handle(
        _profitLossMeta,
        profitLoss.isAcceptableOrUnknown(data['profit_loss']!, _profitLossMeta),
      );
    } else if (isInserting) {
      context.missing(_profitLossMeta);
    }
    if (data.containsKey('hours_played')) {
      context.handle(
        _hoursPlayedMeta,
        hoursPlayed.isAcceptableOrUnknown(
          data['hours_played']!,
          _hoursPlayedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hoursPlayedMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      gameType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_type'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}format'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      stakes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stakes'],
      )!,
      buyIn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}buy_in'],
      )!,
      cashOut: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cash_out'],
      )!,
      profitLoss: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profit_loss'],
      )!,
      hoursPlayed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hours_played'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final DateTime date;
  final int gameType;
  final int format;
  final String location;
  final String stakes;
  final double buyIn;
  final double cashOut;
  final double profitLoss;
  final double hoursPlayed;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Session({
    required this.id,
    required this.date,
    required this.gameType,
    required this.format,
    required this.location,
    required this.stakes,
    required this.buyIn,
    required this.cashOut,
    required this.profitLoss,
    required this.hoursPlayed,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['game_type'] = Variable<int>(gameType);
    map['format'] = Variable<int>(format);
    map['location'] = Variable<String>(location);
    map['stakes'] = Variable<String>(stakes);
    map['buy_in'] = Variable<double>(buyIn);
    map['cash_out'] = Variable<double>(cashOut);
    map['profit_loss'] = Variable<double>(profitLoss);
    map['hours_played'] = Variable<double>(hoursPlayed);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      date: Value(date),
      gameType: Value(gameType),
      format: Value(format),
      location: Value(location),
      stakes: Value(stakes),
      buyIn: Value(buyIn),
      cashOut: Value(cashOut),
      profitLoss: Value(profitLoss),
      hoursPlayed: Value(hoursPlayed),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      gameType: serializer.fromJson<int>(json['gameType']),
      format: serializer.fromJson<int>(json['format']),
      location: serializer.fromJson<String>(json['location']),
      stakes: serializer.fromJson<String>(json['stakes']),
      buyIn: serializer.fromJson<double>(json['buyIn']),
      cashOut: serializer.fromJson<double>(json['cashOut']),
      profitLoss: serializer.fromJson<double>(json['profitLoss']),
      hoursPlayed: serializer.fromJson<double>(json['hoursPlayed']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'gameType': serializer.toJson<int>(gameType),
      'format': serializer.toJson<int>(format),
      'location': serializer.toJson<String>(location),
      'stakes': serializer.toJson<String>(stakes),
      'buyIn': serializer.toJson<double>(buyIn),
      'cashOut': serializer.toJson<double>(cashOut),
      'profitLoss': serializer.toJson<double>(profitLoss),
      'hoursPlayed': serializer.toJson<double>(hoursPlayed),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Session copyWith({
    int? id,
    DateTime? date,
    int? gameType,
    int? format,
    String? location,
    String? stakes,
    double? buyIn,
    double? cashOut,
    double? profitLoss,
    double? hoursPlayed,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Session(
    id: id ?? this.id,
    date: date ?? this.date,
    gameType: gameType ?? this.gameType,
    format: format ?? this.format,
    location: location ?? this.location,
    stakes: stakes ?? this.stakes,
    buyIn: buyIn ?? this.buyIn,
    cashOut: cashOut ?? this.cashOut,
    profitLoss: profitLoss ?? this.profitLoss,
    hoursPlayed: hoursPlayed ?? this.hoursPlayed,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      gameType: data.gameType.present ? data.gameType.value : this.gameType,
      format: data.format.present ? data.format.value : this.format,
      location: data.location.present ? data.location.value : this.location,
      stakes: data.stakes.present ? data.stakes.value : this.stakes,
      buyIn: data.buyIn.present ? data.buyIn.value : this.buyIn,
      cashOut: data.cashOut.present ? data.cashOut.value : this.cashOut,
      profitLoss: data.profitLoss.present
          ? data.profitLoss.value
          : this.profitLoss,
      hoursPlayed: data.hoursPlayed.present
          ? data.hoursPlayed.value
          : this.hoursPlayed,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('gameType: $gameType, ')
          ..write('format: $format, ')
          ..write('location: $location, ')
          ..write('stakes: $stakes, ')
          ..write('buyIn: $buyIn, ')
          ..write('cashOut: $cashOut, ')
          ..write('profitLoss: $profitLoss, ')
          ..write('hoursPlayed: $hoursPlayed, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    gameType,
    format,
    location,
    stakes,
    buyIn,
    cashOut,
    profitLoss,
    hoursPlayed,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.date == this.date &&
          other.gameType == this.gameType &&
          other.format == this.format &&
          other.location == this.location &&
          other.stakes == this.stakes &&
          other.buyIn == this.buyIn &&
          other.cashOut == this.cashOut &&
          other.profitLoss == this.profitLoss &&
          other.hoursPlayed == this.hoursPlayed &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int> gameType;
  final Value<int> format;
  final Value<String> location;
  final Value<String> stakes;
  final Value<double> buyIn;
  final Value<double> cashOut;
  final Value<double> profitLoss;
  final Value<double> hoursPlayed;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.gameType = const Value.absent(),
    this.format = const Value.absent(),
    this.location = const Value.absent(),
    this.stakes = const Value.absent(),
    this.buyIn = const Value.absent(),
    this.cashOut = const Value.absent(),
    this.profitLoss = const Value.absent(),
    this.hoursPlayed = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.gameType = const Value.absent(),
    this.format = const Value.absent(),
    required String location,
    required String stakes,
    required double buyIn,
    required double cashOut,
    required double profitLoss,
    required double hoursPlayed,
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : date = Value(date),
       location = Value(location),
       stakes = Value(stakes),
       buyIn = Value(buyIn),
       cashOut = Value(cashOut),
       profitLoss = Value(profitLoss),
       hoursPlayed = Value(hoursPlayed);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? gameType,
    Expression<int>? format,
    Expression<String>? location,
    Expression<String>? stakes,
    Expression<double>? buyIn,
    Expression<double>? cashOut,
    Expression<double>? profitLoss,
    Expression<double>? hoursPlayed,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (gameType != null) 'game_type': gameType,
      if (format != null) 'format': format,
      if (location != null) 'location': location,
      if (stakes != null) 'stakes': stakes,
      if (buyIn != null) 'buy_in': buyIn,
      if (cashOut != null) 'cash_out': cashOut,
      if (profitLoss != null) 'profit_loss': profitLoss,
      if (hoursPlayed != null) 'hours_played': hoursPlayed,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<int>? gameType,
    Value<int>? format,
    Value<String>? location,
    Value<String>? stakes,
    Value<double>? buyIn,
    Value<double>? cashOut,
    Value<double>? profitLoss,
    Value<double>? hoursPlayed,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      gameType: gameType ?? this.gameType,
      format: format ?? this.format,
      location: location ?? this.location,
      stakes: stakes ?? this.stakes,
      buyIn: buyIn ?? this.buyIn,
      cashOut: cashOut ?? this.cashOut,
      profitLoss: profitLoss ?? this.profitLoss,
      hoursPlayed: hoursPlayed ?? this.hoursPlayed,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (gameType.present) {
      map['game_type'] = Variable<int>(gameType.value);
    }
    if (format.present) {
      map['format'] = Variable<int>(format.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (stakes.present) {
      map['stakes'] = Variable<String>(stakes.value);
    }
    if (buyIn.present) {
      map['buy_in'] = Variable<double>(buyIn.value);
    }
    if (cashOut.present) {
      map['cash_out'] = Variable<double>(cashOut.value);
    }
    if (profitLoss.present) {
      map['profit_loss'] = Variable<double>(profitLoss.value);
    }
    if (hoursPlayed.present) {
      map['hours_played'] = Variable<double>(hoursPlayed.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('gameType: $gameType, ')
          ..write('format: $format, ')
          ..write('location: $location, ')
          ..write('stakes: $stakes, ')
          ..write('buyIn: $buyIn, ')
          ..write('cashOut: $cashOut, ')
          ..write('profitLoss: $profitLoss, ')
          ..write('hoursPlayed: $hoursPlayed, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF4CAF50),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final int id;
  final String name;
  final int color;
  const Tag({required this.id, required this.name, required this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<int>(color);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(id: Value(id), name: Value(name), color: Value(color));
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int>(color),
    };
  }

  Tag copyWith({int? id, String? name, int? color}) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
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
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> color;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
  });
  TagsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Tag> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? color,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
    });
  }

  TagsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? color,
  }) {
    return TagsCompanion(
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
      map['color'] = Variable<int>(color.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }
}

class $SessionTagsTable extends SessionTags
    with TableInfo<$SessionTagsTable, SessionTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [sessionId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, tagId};
  @override
  SessionTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionTag(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $SessionTagsTable createAlias(String alias) {
    return $SessionTagsTable(attachedDatabase, alias);
  }
}

class SessionTag extends DataClass implements Insertable<SessionTag> {
  final int sessionId;
  final int tagId;
  const SessionTag({required this.sessionId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<int>(sessionId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  SessionTagsCompanion toCompanion(bool nullToAbsent) {
    return SessionTagsCompanion(
      sessionId: Value(sessionId),
      tagId: Value(tagId),
    );
  }

  factory SessionTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionTag(
      sessionId: serializer.fromJson<int>(json['sessionId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<int>(sessionId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  SessionTag copyWith({int? sessionId, int? tagId}) => SessionTag(
    sessionId: sessionId ?? this.sessionId,
    tagId: tagId ?? this.tagId,
  );
  SessionTag copyWithCompanion(SessionTagsCompanion data) {
    return SessionTag(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionTag(')
          ..write('sessionId: $sessionId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionTag &&
          other.sessionId == this.sessionId &&
          other.tagId == this.tagId);
}

class SessionTagsCompanion extends UpdateCompanion<SessionTag> {
  final Value<int> sessionId;
  final Value<int> tagId;
  final Value<int> rowid;
  const SessionTagsCompanion({
    this.sessionId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionTagsCompanion.insert({
    required int sessionId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       tagId = Value(tagId);
  static Insertable<SessionTag> custom({
    Expression<int>? sessionId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionTagsCompanion copyWith({
    Value<int>? sessionId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return SessionTagsCompanion(
      sessionId: sessionId ?? this.sessionId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionTagsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HandsTable extends Hands with TableInfo<$HandsTable, Hand> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HandsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playerCountMeta = const VerificationMeta(
    'playerCount',
  );
  @override
  late final GeneratedColumn<int> playerCount = GeneratedColumn<int>(
    'player_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _smallBlindMeta = const VerificationMeta(
    'smallBlind',
  );
  @override
  late final GeneratedColumn<double> smallBlind = GeneratedColumn<double>(
    'small_blind',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bigBlindMeta = const VerificationMeta(
    'bigBlind',
  );
  @override
  late final GeneratedColumn<double> bigBlind = GeneratedColumn<double>(
    'big_blind',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anteMeta = const VerificationMeta('ante');
  @override
  late final GeneratedColumn<double> ante = GeneratedColumn<double>(
    'ante',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _gameTypeMeta2 = const VerificationMeta(
    'gameType',
  );
  @override
  late final GeneratedColumn<int> gameType = GeneratedColumn<int>(
    'game_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _straddleMeta = const VerificationMeta(
    'straddle',
  );
  @override
  late final GeneratedColumn<double> straddle = GeneratedColumn<double>(
    'straddle',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _dealerIndexMeta = const VerificationMeta(
    'dealerIndex',
  );
  @override
  late final GeneratedColumn<int> dealerIndex = GeneratedColumn<int>(
    'dealer_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _holeCardsJsonMeta = const VerificationMeta(
    'holeCardsJson',
  );
  @override
  late final GeneratedColumn<String> holeCardsJson = GeneratedColumn<String>(
    'hole_cards_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<PlayerConfig>, String>
  playerConfigs = GeneratedColumn<String>(
    'player_configs',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<PlayerConfig>>($HandsTable.$converterplayerConfigs);
  @override
  late final GeneratedColumnWithTypeConverter<List<int>, String>
  communityCards = GeneratedColumn<String>(
    'community_cards',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<int>>($HandsTable.$convertercommunityCards);
  static const VerificationMeta _parentHandIdMeta = const VerificationMeta(
    'parentHandId',
  );
  @override
  late final GeneratedColumn<int> parentHandId = GeneratedColumn<int>(
    'parent_hand_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _branchAtActionIndexMeta =
      const VerificationMeta('branchAtActionIndex');
  @override
  late final GeneratedColumn<int> branchAtActionIndex = GeneratedColumn<int>(
    'branch_at_action_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    playerCount,
    smallBlind,
    bigBlind,
    ante,
    gameType,
    straddle,
    dealerIndex,
    holeCardsJson,
    playerConfigs,
    communityCards,
    parentHandId,
    branchAtActionIndex,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hands';
  @override
  VerificationContext validateIntegrity(
    Insertable<Hand> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('player_count')) {
      context.handle(
        _playerCountMeta,
        playerCount.isAcceptableOrUnknown(
          data['player_count']!,
          _playerCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playerCountMeta);
    }
    if (data.containsKey('small_blind')) {
      context.handle(
        _smallBlindMeta,
        smallBlind.isAcceptableOrUnknown(data['small_blind']!, _smallBlindMeta),
      );
    } else if (isInserting) {
      context.missing(_smallBlindMeta);
    }
    if (data.containsKey('big_blind')) {
      context.handle(
        _bigBlindMeta,
        bigBlind.isAcceptableOrUnknown(data['big_blind']!, _bigBlindMeta),
      );
    } else if (isInserting) {
      context.missing(_bigBlindMeta);
    }
    if (data.containsKey('ante')) {
      context.handle(
        _anteMeta,
        ante.isAcceptableOrUnknown(data['ante']!, _anteMeta),
      );
    }
    if (data.containsKey('game_type')) {
      context.handle(
        _gameTypeMeta2,
        gameType.isAcceptableOrUnknown(data['game_type']!, _gameTypeMeta2),
      );
    }
    if (data.containsKey('straddle')) {
      context.handle(
        _straddleMeta,
        straddle.isAcceptableOrUnknown(data['straddle']!, _straddleMeta),
      );
    }
    if (data.containsKey('dealer_index')) {
      context.handle(
        _dealerIndexMeta,
        dealerIndex.isAcceptableOrUnknown(
          data['dealer_index']!,
          _dealerIndexMeta,
        ),
      );
    }
    if (data.containsKey('hole_cards_json')) {
      context.handle(
        _holeCardsJsonMeta,
        holeCardsJson.isAcceptableOrUnknown(
          data['hole_cards_json']!,
          _holeCardsJsonMeta,
        ),
      );
    }
    if (data.containsKey('parent_hand_id')) {
      context.handle(
        _parentHandIdMeta,
        parentHandId.isAcceptableOrUnknown(
          data['parent_hand_id']!,
          _parentHandIdMeta,
        ),
      );
    }
    if (data.containsKey('branch_at_action_index')) {
      context.handle(
        _branchAtActionIndexMeta,
        branchAtActionIndex.isAcceptableOrUnknown(
          data['branch_at_action_index']!,
          _branchAtActionIndexMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Hand map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Hand(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      playerCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_count'],
      )!,
      smallBlind: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}small_blind'],
      )!,
      bigBlind: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}big_blind'],
      )!,
      ante: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ante'],
      )!,
      gameType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_type'],
      )!,
      straddle: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}straddle'],
      )!,
      dealerIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dealer_index'],
      )!,
      holeCardsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hole_cards_json'],
      )!,
      playerConfigs: $HandsTable.$converterplayerConfigs.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}player_configs'],
        )!,
      ),
      communityCards: $HandsTable.$convertercommunityCards.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}community_cards'],
        )!,
      ),
      parentHandId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_hand_id'],
      ),
      branchAtActionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}branch_at_action_index'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HandsTable createAlias(String alias) {
    return $HandsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<PlayerConfig>, String> $converterplayerConfigs =
      const PlayerConfigListConverter();
  static TypeConverter<List<int>, String> $convertercommunityCards =
      const CardListConverter();
}

class Hand extends DataClass implements Insertable<Hand> {
  final int id;
  final String? title;
  final String? description;
  final int playerCount;
  final double smallBlind;
  final double bigBlind;
  final double ante;
  final int gameType;
  final double straddle;
  final int dealerIndex;
  final String holeCardsJson;
  final List<PlayerConfig> playerConfigs;
  final List<int> communityCards;
  final int? parentHandId;
  final int? branchAtActionIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Hand({
    required this.id,
    this.title,
    this.description,
    required this.playerCount,
    required this.smallBlind,
    required this.bigBlind,
    required this.ante,
    required this.gameType,
    required this.straddle,
    required this.dealerIndex,
    required this.holeCardsJson,
    required this.playerConfigs,
    required this.communityCards,
    this.parentHandId,
    this.branchAtActionIndex,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['player_count'] = Variable<int>(playerCount);
    map['small_blind'] = Variable<double>(smallBlind);
    map['big_blind'] = Variable<double>(bigBlind);
    map['ante'] = Variable<double>(ante);
    map['game_type'] = Variable<int>(gameType);
    map['straddle'] = Variable<double>(straddle);
    map['dealer_index'] = Variable<int>(dealerIndex);
    map['hole_cards_json'] = Variable<String>(holeCardsJson);
    {
      map['player_configs'] = Variable<String>(
        $HandsTable.$converterplayerConfigs.toSql(playerConfigs),
      );
    }
    {
      map['community_cards'] = Variable<String>(
        $HandsTable.$convertercommunityCards.toSql(communityCards),
      );
    }
    if (!nullToAbsent || parentHandId != null) {
      map['parent_hand_id'] = Variable<int>(parentHandId);
    }
    if (!nullToAbsent || branchAtActionIndex != null) {
      map['branch_at_action_index'] = Variable<int>(branchAtActionIndex);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HandsCompanion toCompanion(bool nullToAbsent) {
    return HandsCompanion(
      id: Value(id),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      playerCount: Value(playerCount),
      smallBlind: Value(smallBlind),
      bigBlind: Value(bigBlind),
      ante: Value(ante),
      gameType: Value(gameType),
      straddle: Value(straddle),
      dealerIndex: Value(dealerIndex),
      holeCardsJson: Value(holeCardsJson),
      playerConfigs: Value(playerConfigs),
      communityCards: Value(communityCards),
      parentHandId: parentHandId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentHandId),
      branchAtActionIndex: branchAtActionIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(branchAtActionIndex),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Hand.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Hand(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      playerCount: serializer.fromJson<int>(json['playerCount']),
      smallBlind: serializer.fromJson<double>(json['smallBlind']),
      bigBlind: serializer.fromJson<double>(json['bigBlind']),
      ante: serializer.fromJson<double>(json['ante']),
      gameType: serializer.fromJson<int>(json['gameType']),
      straddle: serializer.fromJson<double>(json['straddle']),
      dealerIndex: serializer.fromJson<int>(json['dealerIndex']),
      holeCardsJson: serializer.fromJson<String>(json['holeCardsJson']),
      playerConfigs: serializer.fromJson<List<PlayerConfig>>(
        json['playerConfigs'],
      ),
      communityCards: serializer.fromJson<List<int>>(json['communityCards']),
      parentHandId: serializer.fromJson<int?>(json['parentHandId']),
      branchAtActionIndex: serializer.fromJson<int?>(
        json['branchAtActionIndex'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String?>(title),
      'description': serializer.toJson<String?>(description),
      'playerCount': serializer.toJson<int>(playerCount),
      'smallBlind': serializer.toJson<double>(smallBlind),
      'bigBlind': serializer.toJson<double>(bigBlind),
      'ante': serializer.toJson<double>(ante),
      'gameType': serializer.toJson<int>(gameType),
      'straddle': serializer.toJson<double>(straddle),
      'dealerIndex': serializer.toJson<int>(dealerIndex),
      'holeCardsJson': serializer.toJson<String>(holeCardsJson),
      'playerConfigs': serializer.toJson<List<PlayerConfig>>(playerConfigs),
      'communityCards': serializer.toJson<List<int>>(communityCards),
      'parentHandId': serializer.toJson<int?>(parentHandId),
      'branchAtActionIndex': serializer.toJson<int?>(branchAtActionIndex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Hand copyWith({
    int? id,
    Value<String?> title = const Value.absent(),
    Value<String?> description = const Value.absent(),
    int? playerCount,
    double? smallBlind,
    double? bigBlind,
    double? ante,
    int? gameType,
    double? straddle,
    int? dealerIndex,
    String? holeCardsJson,
    List<PlayerConfig>? playerConfigs,
    List<int>? communityCards,
    Value<int?> parentHandId = const Value.absent(),
    Value<int?> branchAtActionIndex = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Hand(
    id: id ?? this.id,
    title: title.present ? title.value : this.title,
    description: description.present ? description.value : this.description,
    playerCount: playerCount ?? this.playerCount,
    smallBlind: smallBlind ?? this.smallBlind,
    bigBlind: bigBlind ?? this.bigBlind,
    ante: ante ?? this.ante,
    gameType: gameType ?? this.gameType,
    straddle: straddle ?? this.straddle,
    dealerIndex: dealerIndex ?? this.dealerIndex,
    holeCardsJson: holeCardsJson ?? this.holeCardsJson,
    playerConfigs: playerConfigs ?? this.playerConfigs,
    communityCards: communityCards ?? this.communityCards,
    parentHandId: parentHandId.present ? parentHandId.value : this.parentHandId,
    branchAtActionIndex: branchAtActionIndex.present
        ? branchAtActionIndex.value
        : this.branchAtActionIndex,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Hand copyWithCompanion(HandsCompanion data) {
    return Hand(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      playerCount: data.playerCount.present
          ? data.playerCount.value
          : this.playerCount,
      smallBlind: data.smallBlind.present
          ? data.smallBlind.value
          : this.smallBlind,
      bigBlind: data.bigBlind.present ? data.bigBlind.value : this.bigBlind,
      ante: data.ante.present ? data.ante.value : this.ante,
      gameType: data.gameType.present ? data.gameType.value : this.gameType,
      straddle: data.straddle.present ? data.straddle.value : this.straddle,
      dealerIndex: data.dealerIndex.present
          ? data.dealerIndex.value
          : this.dealerIndex,
      holeCardsJson: data.holeCardsJson.present
          ? data.holeCardsJson.value
          : this.holeCardsJson,
      playerConfigs: data.playerConfigs.present
          ? data.playerConfigs.value
          : this.playerConfigs,
      communityCards: data.communityCards.present
          ? data.communityCards.value
          : this.communityCards,
      parentHandId: data.parentHandId.present
          ? data.parentHandId.value
          : this.parentHandId,
      branchAtActionIndex: data.branchAtActionIndex.present
          ? data.branchAtActionIndex.value
          : this.branchAtActionIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Hand(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('playerCount: $playerCount, ')
          ..write('smallBlind: $smallBlind, ')
          ..write('bigBlind: $bigBlind, ')
          ..write('ante: $ante, ')
          ..write('gameType: $gameType, ')
          ..write('straddle: $straddle, ')
          ..write('dealerIndex: $dealerIndex, ')
          ..write('holeCardsJson: $holeCardsJson, ')
          ..write('playerConfigs: $playerConfigs, ')
          ..write('communityCards: $communityCards, ')
          ..write('parentHandId: $parentHandId, ')
          ..write('branchAtActionIndex: $branchAtActionIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    playerCount,
    smallBlind,
    bigBlind,
    ante,
    gameType,
    straddle,
    dealerIndex,
    holeCardsJson,
    playerConfigs,
    communityCards,
    parentHandId,
    branchAtActionIndex,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Hand &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.playerCount == this.playerCount &&
          other.smallBlind == this.smallBlind &&
          other.bigBlind == this.bigBlind &&
          other.ante == this.ante &&
          other.gameType == this.gameType &&
          other.straddle == this.straddle &&
          other.dealerIndex == this.dealerIndex &&
          other.holeCardsJson == this.holeCardsJson &&
          other.playerConfigs == this.playerConfigs &&
          other.communityCards == this.communityCards &&
          other.parentHandId == this.parentHandId &&
          other.branchAtActionIndex == this.branchAtActionIndex &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HandsCompanion extends UpdateCompanion<Hand> {
  final Value<int> id;
  final Value<String?> title;
  final Value<String?> description;
  final Value<int> playerCount;
  final Value<double> smallBlind;
  final Value<double> bigBlind;
  final Value<double> ante;
  final Value<int> gameType;
  final Value<double> straddle;
  final Value<int> dealerIndex;
  final Value<String> holeCardsJson;
  final Value<List<PlayerConfig>> playerConfigs;
  final Value<List<int>> communityCards;
  final Value<int?> parentHandId;
  final Value<int?> branchAtActionIndex;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const HandsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.playerCount = const Value.absent(),
    this.smallBlind = const Value.absent(),
    this.bigBlind = const Value.absent(),
    this.ante = const Value.absent(),
    this.gameType = const Value.absent(),
    this.straddle = const Value.absent(),
    this.dealerIndex = const Value.absent(),
    this.holeCardsJson = const Value.absent(),
    this.playerConfigs = const Value.absent(),
    this.communityCards = const Value.absent(),
    this.parentHandId = const Value.absent(),
    this.branchAtActionIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  HandsCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    required int playerCount,
    required double smallBlind,
    required double bigBlind,
    this.ante = const Value.absent(),
    this.gameType = const Value.absent(),
    this.straddle = const Value.absent(),
    this.dealerIndex = const Value.absent(),
    this.holeCardsJson = const Value.absent(),
    required List<PlayerConfig> playerConfigs,
    required List<int> communityCards,
    this.parentHandId = const Value.absent(),
    this.branchAtActionIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : playerCount = Value(playerCount),
       smallBlind = Value(smallBlind),
       bigBlind = Value(bigBlind),
       playerConfigs = Value(playerConfigs),
       communityCards = Value(communityCards);
  static Insertable<Hand> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? playerCount,
    Expression<double>? smallBlind,
    Expression<double>? bigBlind,
    Expression<double>? ante,
    Expression<int>? gameType,
    Expression<double>? straddle,
    Expression<int>? dealerIndex,
    Expression<String>? holeCardsJson,
    Expression<String>? playerConfigs,
    Expression<String>? communityCards,
    Expression<int>? parentHandId,
    Expression<int>? branchAtActionIndex,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (playerCount != null) 'player_count': playerCount,
      if (smallBlind != null) 'small_blind': smallBlind,
      if (bigBlind != null) 'big_blind': bigBlind,
      if (ante != null) 'ante': ante,
      if (gameType != null) 'game_type': gameType,
      if (straddle != null) 'straddle': straddle,
      if (dealerIndex != null) 'dealer_index': dealerIndex,
      if (holeCardsJson != null) 'hole_cards_json': holeCardsJson,
      if (playerConfigs != null) 'player_configs': playerConfigs,
      if (communityCards != null) 'community_cards': communityCards,
      if (parentHandId != null) 'parent_hand_id': parentHandId,
      if (branchAtActionIndex != null)
        'branch_at_action_index': branchAtActionIndex,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  HandsCompanion copyWith({
    Value<int>? id,
    Value<String?>? title,
    Value<String?>? description,
    Value<int>? playerCount,
    Value<double>? smallBlind,
    Value<double>? bigBlind,
    Value<double>? ante,
    Value<int>? gameType,
    Value<double>? straddle,
    Value<int>? dealerIndex,
    Value<String>? holeCardsJson,
    Value<List<PlayerConfig>>? playerConfigs,
    Value<List<int>>? communityCards,
    Value<int?>? parentHandId,
    Value<int?>? branchAtActionIndex,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return HandsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      playerCount: playerCount ?? this.playerCount,
      smallBlind: smallBlind ?? this.smallBlind,
      bigBlind: bigBlind ?? this.bigBlind,
      ante: ante ?? this.ante,
      gameType: gameType ?? this.gameType,
      straddle: straddle ?? this.straddle,
      dealerIndex: dealerIndex ?? this.dealerIndex,
      holeCardsJson: holeCardsJson ?? this.holeCardsJson,
      playerConfigs: playerConfigs ?? this.playerConfigs,
      communityCards: communityCards ?? this.communityCards,
      parentHandId: parentHandId ?? this.parentHandId,
      branchAtActionIndex: branchAtActionIndex ?? this.branchAtActionIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (playerCount.present) {
      map['player_count'] = Variable<int>(playerCount.value);
    }
    if (smallBlind.present) {
      map['small_blind'] = Variable<double>(smallBlind.value);
    }
    if (bigBlind.present) {
      map['big_blind'] = Variable<double>(bigBlind.value);
    }
    if (ante.present) {
      map['ante'] = Variable<double>(ante.value);
    }
    if (gameType.present) {
      map['game_type'] = Variable<int>(gameType.value);
    }
    if (straddle.present) {
      map['straddle'] = Variable<double>(straddle.value);
    }
    if (dealerIndex.present) {
      map['dealer_index'] = Variable<int>(dealerIndex.value);
    }
    if (holeCardsJson.present) {
      map['hole_cards_json'] = Variable<String>(holeCardsJson.value);
    }
    if (playerConfigs.present) {
      map['player_configs'] = Variable<String>(
        $HandsTable.$converterplayerConfigs.toSql(playerConfigs.value),
      );
    }
    if (communityCards.present) {
      map['community_cards'] = Variable<String>(
        $HandsTable.$convertercommunityCards.toSql(communityCards.value),
      );
    }
    if (parentHandId.present) {
      map['parent_hand_id'] = Variable<int>(parentHandId.value);
    }
    if (branchAtActionIndex.present) {
      map['branch_at_action_index'] = Variable<int>(branchAtActionIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HandsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('playerCount: $playerCount, ')
          ..write('smallBlind: $smallBlind, ')
          ..write('bigBlind: $bigBlind, ')
          ..write('ante: $ante, ')
          ..write('gameType: $gameType, ')
          ..write('straddle: $straddle, ')
          ..write('dealerIndex: $dealerIndex, ')
          ..write('holeCardsJson: $holeCardsJson, ')
          ..write('playerConfigs: $playerConfigs, ')
          ..write('communityCards: $communityCards, ')
          ..write('parentHandId: $parentHandId, ')
          ..write('branchAtActionIndex: $branchAtActionIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $HandActionsTable extends HandActions
    with TableInfo<$HandActionsTable, HandAction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HandActionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _handIdMeta = const VerificationMeta('handId');
  @override
  late final GeneratedColumn<int> handId = GeneratedColumn<int>(
    'hand_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceIndexMeta = const VerificationMeta(
    'sequenceIndex',
  );
  @override
  late final GeneratedColumn<int> sequenceIndex = GeneratedColumn<int>(
    'sequence_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _streetMeta = const VerificationMeta('street');
  @override
  late final GeneratedColumn<int> street = GeneratedColumn<int>(
    'street',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerPositionMeta = const VerificationMeta(
    'playerPosition',
  );
  @override
  late final GeneratedColumn<int> playerPosition = GeneratedColumn<int>(
    'player_position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<int> actionType = GeneratedColumn<int>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _potAfterActionMeta = const VerificationMeta(
    'potAfterAction',
  );
  @override
  late final GeneratedColumn<double> potAfterAction = GeneratedColumn<double>(
    'pot_after_action',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    handId,
    sequenceIndex,
    street,
    playerPosition,
    actionType,
    amount,
    potAfterAction,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hand_actions';
  @override
  VerificationContext validateIntegrity(
    Insertable<HandAction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('hand_id')) {
      context.handle(
        _handIdMeta,
        handId.isAcceptableOrUnknown(data['hand_id']!, _handIdMeta),
      );
    } else if (isInserting) {
      context.missing(_handIdMeta);
    }
    if (data.containsKey('sequence_index')) {
      context.handle(
        _sequenceIndexMeta,
        sequenceIndex.isAcceptableOrUnknown(
          data['sequence_index']!,
          _sequenceIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sequenceIndexMeta);
    }
    if (data.containsKey('street')) {
      context.handle(
        _streetMeta,
        street.isAcceptableOrUnknown(data['street']!, _streetMeta),
      );
    } else if (isInserting) {
      context.missing(_streetMeta);
    }
    if (data.containsKey('player_position')) {
      context.handle(
        _playerPositionMeta,
        playerPosition.isAcceptableOrUnknown(
          data['player_position']!,
          _playerPositionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playerPositionMeta);
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('pot_after_action')) {
      context.handle(
        _potAfterActionMeta,
        potAfterAction.isAcceptableOrUnknown(
          data['pot_after_action']!,
          _potAfterActionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {handId, sequenceIndex},
  ];
  @override
  HandAction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HandAction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      handId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hand_id'],
      )!,
      sequenceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence_index'],
      )!,
      street: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}street'],
      )!,
      playerPosition: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_position'],
      )!,
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}action_type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      potAfterAction: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pot_after_action'],
      )!,
    );
  }

  @override
  $HandActionsTable createAlias(String alias) {
    return $HandActionsTable(attachedDatabase, alias);
  }
}

class HandAction extends DataClass implements Insertable<HandAction> {
  final int id;
  final int handId;
  final int sequenceIndex;
  final int street;
  final int playerPosition;
  final int actionType;
  final double amount;
  final double potAfterAction;
  const HandAction({
    required this.id,
    required this.handId,
    required this.sequenceIndex,
    required this.street,
    required this.playerPosition,
    required this.actionType,
    required this.amount,
    required this.potAfterAction,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['hand_id'] = Variable<int>(handId);
    map['sequence_index'] = Variable<int>(sequenceIndex);
    map['street'] = Variable<int>(street);
    map['player_position'] = Variable<int>(playerPosition);
    map['action_type'] = Variable<int>(actionType);
    map['amount'] = Variable<double>(amount);
    map['pot_after_action'] = Variable<double>(potAfterAction);
    return map;
  }

  HandActionsCompanion toCompanion(bool nullToAbsent) {
    return HandActionsCompanion(
      id: Value(id),
      handId: Value(handId),
      sequenceIndex: Value(sequenceIndex),
      street: Value(street),
      playerPosition: Value(playerPosition),
      actionType: Value(actionType),
      amount: Value(amount),
      potAfterAction: Value(potAfterAction),
    );
  }

  factory HandAction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HandAction(
      id: serializer.fromJson<int>(json['id']),
      handId: serializer.fromJson<int>(json['handId']),
      sequenceIndex: serializer.fromJson<int>(json['sequenceIndex']),
      street: serializer.fromJson<int>(json['street']),
      playerPosition: serializer.fromJson<int>(json['playerPosition']),
      actionType: serializer.fromJson<int>(json['actionType']),
      amount: serializer.fromJson<double>(json['amount']),
      potAfterAction: serializer.fromJson<double>(json['potAfterAction']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'handId': serializer.toJson<int>(handId),
      'sequenceIndex': serializer.toJson<int>(sequenceIndex),
      'street': serializer.toJson<int>(street),
      'playerPosition': serializer.toJson<int>(playerPosition),
      'actionType': serializer.toJson<int>(actionType),
      'amount': serializer.toJson<double>(amount),
      'potAfterAction': serializer.toJson<double>(potAfterAction),
    };
  }

  HandAction copyWith({
    int? id,
    int? handId,
    int? sequenceIndex,
    int? street,
    int? playerPosition,
    int? actionType,
    double? amount,
    double? potAfterAction,
  }) => HandAction(
    id: id ?? this.id,
    handId: handId ?? this.handId,
    sequenceIndex: sequenceIndex ?? this.sequenceIndex,
    street: street ?? this.street,
    playerPosition: playerPosition ?? this.playerPosition,
    actionType: actionType ?? this.actionType,
    amount: amount ?? this.amount,
    potAfterAction: potAfterAction ?? this.potAfterAction,
  );
  HandAction copyWithCompanion(HandActionsCompanion data) {
    return HandAction(
      id: data.id.present ? data.id.value : this.id,
      handId: data.handId.present ? data.handId.value : this.handId,
      sequenceIndex: data.sequenceIndex.present
          ? data.sequenceIndex.value
          : this.sequenceIndex,
      street: data.street.present ? data.street.value : this.street,
      playerPosition: data.playerPosition.present
          ? data.playerPosition.value
          : this.playerPosition,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      amount: data.amount.present ? data.amount.value : this.amount,
      potAfterAction: data.potAfterAction.present
          ? data.potAfterAction.value
          : this.potAfterAction,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HandAction(')
          ..write('id: $id, ')
          ..write('handId: $handId, ')
          ..write('sequenceIndex: $sequenceIndex, ')
          ..write('street: $street, ')
          ..write('playerPosition: $playerPosition, ')
          ..write('actionType: $actionType, ')
          ..write('amount: $amount, ')
          ..write('potAfterAction: $potAfterAction')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    handId,
    sequenceIndex,
    street,
    playerPosition,
    actionType,
    amount,
    potAfterAction,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HandAction &&
          other.id == this.id &&
          other.handId == this.handId &&
          other.sequenceIndex == this.sequenceIndex &&
          other.street == this.street &&
          other.playerPosition == this.playerPosition &&
          other.actionType == this.actionType &&
          other.amount == this.amount &&
          other.potAfterAction == this.potAfterAction);
}

class HandActionsCompanion extends UpdateCompanion<HandAction> {
  final Value<int> id;
  final Value<int> handId;
  final Value<int> sequenceIndex;
  final Value<int> street;
  final Value<int> playerPosition;
  final Value<int> actionType;
  final Value<double> amount;
  final Value<double> potAfterAction;
  const HandActionsCompanion({
    this.id = const Value.absent(),
    this.handId = const Value.absent(),
    this.sequenceIndex = const Value.absent(),
    this.street = const Value.absent(),
    this.playerPosition = const Value.absent(),
    this.actionType = const Value.absent(),
    this.amount = const Value.absent(),
    this.potAfterAction = const Value.absent(),
  });
  HandActionsCompanion.insert({
    this.id = const Value.absent(),
    required int handId,
    required int sequenceIndex,
    required int street,
    required int playerPosition,
    required int actionType,
    this.amount = const Value.absent(),
    this.potAfterAction = const Value.absent(),
  }) : handId = Value(handId),
       sequenceIndex = Value(sequenceIndex),
       street = Value(street),
       playerPosition = Value(playerPosition),
       actionType = Value(actionType);
  static Insertable<HandAction> custom({
    Expression<int>? id,
    Expression<int>? handId,
    Expression<int>? sequenceIndex,
    Expression<int>? street,
    Expression<int>? playerPosition,
    Expression<int>? actionType,
    Expression<double>? amount,
    Expression<double>? potAfterAction,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (handId != null) 'hand_id': handId,
      if (sequenceIndex != null) 'sequence_index': sequenceIndex,
      if (street != null) 'street': street,
      if (playerPosition != null) 'player_position': playerPosition,
      if (actionType != null) 'action_type': actionType,
      if (amount != null) 'amount': amount,
      if (potAfterAction != null) 'pot_after_action': potAfterAction,
    });
  }

  HandActionsCompanion copyWith({
    Value<int>? id,
    Value<int>? handId,
    Value<int>? sequenceIndex,
    Value<int>? street,
    Value<int>? playerPosition,
    Value<int>? actionType,
    Value<double>? amount,
    Value<double>? potAfterAction,
  }) {
    return HandActionsCompanion(
      id: id ?? this.id,
      handId: handId ?? this.handId,
      sequenceIndex: sequenceIndex ?? this.sequenceIndex,
      street: street ?? this.street,
      playerPosition: playerPosition ?? this.playerPosition,
      actionType: actionType ?? this.actionType,
      amount: amount ?? this.amount,
      potAfterAction: potAfterAction ?? this.potAfterAction,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (handId.present) {
      map['hand_id'] = Variable<int>(handId.value);
    }
    if (sequenceIndex.present) {
      map['sequence_index'] = Variable<int>(sequenceIndex.value);
    }
    if (street.present) {
      map['street'] = Variable<int>(street.value);
    }
    if (playerPosition.present) {
      map['player_position'] = Variable<int>(playerPosition.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<int>(actionType.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (potAfterAction.present) {
      map['pot_after_action'] = Variable<double>(potAfterAction.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HandActionsCompanion(')
          ..write('id: $id, ')
          ..write('handId: $handId, ')
          ..write('sequenceIndex: $sequenceIndex, ')
          ..write('street: $street, ')
          ..write('playerPosition: $playerPosition, ')
          ..write('actionType: $actionType, ')
          ..write('amount: $amount, ')
          ..write('potAfterAction: $potAfterAction')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $SessionTagsTable sessionTags = $SessionTagsTable(this);
  late final $HandsTable hands = $HandsTable(this);
  late final $HandActionsTable handActions = $HandActionsTable(this);
  late final SessionsDao sessionsDao = SessionsDao(this as AppDatabase);
  late final HandsDao handsDao = HandsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    tags,
    sessionTags,
    hands,
    handActions,
  ];
}

typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      required DateTime date,
      Value<int> gameType,
      Value<int> format,
      required String location,
      required String stakes,
      required double buyIn,
      required double cashOut,
      required double profitLoss,
      required double hoursPlayed,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<int> gameType,
      Value<int> format,
      Value<String> location,
      Value<String> stakes,
      Value<double> buyIn,
      Value<double> cashOut,
      Value<double> profitLoss,
      Value<double> hoursPlayed,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionTagsTable, List<SessionTag>>
  _sessionTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionTags,
    aliasName: $_aliasNameGenerator(db.sessions.id, db.sessionTags.sessionId),
  );

  $$SessionTagsTableProcessedTableManager get sessionTagsRefs {
    final manager = $$SessionTagsTableTableManager(
      $_db,
      $_db.sessionTags,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gameType => $composableBuilder(
    column: $table.gameType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stakes => $composableBuilder(
    column: $table.stakes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get buyIn => $composableBuilder(
    column: $table.buyIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashOut => $composableBuilder(
    column: $table.cashOut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profitLoss => $composableBuilder(
    column: $table.profitLoss,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hoursPlayed => $composableBuilder(
    column: $table.hoursPlayed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionTagsRefs(
    Expression<bool> Function($$SessionTagsTableFilterComposer f) f,
  ) {
    final $$SessionTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionTags,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionTagsTableFilterComposer(
            $db: $db,
            $table: $db.sessionTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gameType => $composableBuilder(
    column: $table.gameType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stakes => $composableBuilder(
    column: $table.stakes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get buyIn => $composableBuilder(
    column: $table.buyIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashOut => $composableBuilder(
    column: $table.cashOut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profitLoss => $composableBuilder(
    column: $table.profitLoss,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hoursPlayed => $composableBuilder(
    column: $table.hoursPlayed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get gameType =>
      $composableBuilder(column: $table.gameType, builder: (column) => column);

  GeneratedColumn<int> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get stakes =>
      $composableBuilder(column: $table.stakes, builder: (column) => column);

  GeneratedColumn<double> get buyIn =>
      $composableBuilder(column: $table.buyIn, builder: (column) => column);

  GeneratedColumn<double> get cashOut =>
      $composableBuilder(column: $table.cashOut, builder: (column) => column);

  GeneratedColumn<double> get profitLoss => $composableBuilder(
    column: $table.profitLoss,
    builder: (column) => column,
  );

  GeneratedColumn<double> get hoursPlayed => $composableBuilder(
    column: $table.hoursPlayed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> sessionTagsRefs<T extends Object>(
    Expression<T> Function($$SessionTagsTableAnnotationComposer a) f,
  ) {
    final $$SessionTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionTags,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, $$SessionsTableReferences),
          Session,
          PrefetchHooks Function({bool sessionTagsRefs})
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> gameType = const Value.absent(),
                Value<int> format = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> stakes = const Value.absent(),
                Value<double> buyIn = const Value.absent(),
                Value<double> cashOut = const Value.absent(),
                Value<double> profitLoss = const Value.absent(),
                Value<double> hoursPlayed = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                date: date,
                gameType: gameType,
                format: format,
                location: location,
                stakes: stakes,
                buyIn: buyIn,
                cashOut: cashOut,
                profitLoss: profitLoss,
                hoursPlayed: hoursPlayed,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                Value<int> gameType = const Value.absent(),
                Value<int> format = const Value.absent(),
                required String location,
                required String stakes,
                required double buyIn,
                required double cashOut,
                required double profitLoss,
                required double hoursPlayed,
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                date: date,
                gameType: gameType,
                format: format,
                location: location,
                stakes: stakes,
                buyIn: buyIn,
                cashOut: cashOut,
                profitLoss: profitLoss,
                hoursPlayed: hoursPlayed,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sessionTagsRefs) db.sessionTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionTagsRefs)
                    await $_getPrefetchedData<
                      Session,
                      $SessionsTable,
                      SessionTag
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._sessionTagsRefsTable(db),
                      managerFromTypedResult: (p0) => $$SessionsTableReferences(
                        db,
                        table,
                        p0,
                      ).sessionTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, $$SessionsTableReferences),
      Session,
      PrefetchHooks Function({bool sessionTagsRefs})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      Value<int> id,
      required String name,
      Value<int> color,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> color,
    });

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionTagsTable, List<SessionTag>>
  _sessionTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionTags,
    aliasName: $_aliasNameGenerator(db.tags.id, db.sessionTags.tagId),
  );

  $$SessionTagsTableProcessedTableManager get sessionTagsRefs {
    final manager = $$SessionTagsTableTableManager(
      $_db,
      $_db.sessionTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionTagsRefs(
    Expression<bool> Function($$SessionTagsTableFilterComposer f) f,
  ) {
    final $$SessionTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionTagsTableFilterComposer(
            $db: $db,
            $table: $db.sessionTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
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

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  Expression<T> sessionTagsRefs<T extends Object>(
    Expression<T> Function($$SessionTagsTableAnnotationComposer a) f,
  ) {
    final $$SessionTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool sessionTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> color = const Value.absent(),
              }) => TagsCompanion(id: id, name: name, color: color),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> color = const Value.absent(),
              }) => TagsCompanion.insert(id: id, name: name, color: color),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TagsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({sessionTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sessionTagsRefs) db.sessionTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, SessionTag>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences
                          ._sessionTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).sessionTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool sessionTagsRefs})
    >;
typedef $$SessionTagsTableCreateCompanionBuilder =
    SessionTagsCompanion Function({
      required int sessionId,
      required int tagId,
      Value<int> rowid,
    });
typedef $$SessionTagsTableUpdateCompanionBuilder =
    SessionTagsCompanion Function({
      Value<int> sessionId,
      Value<int> tagId,
      Value<int> rowid,
    });

final class $$SessionTagsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionTagsTable, SessionTag> {
  $$SessionTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.sessionTags.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) => db.tags.createAlias(
    $_aliasNameGenerator(db.sessionTags.tagId, db.tags.id),
  );

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SessionTagsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionTagsTable> {
  $$SessionTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionTagsTable> {
  $$SessionTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionTagsTable> {
  $$SessionTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionTagsTable,
          SessionTag,
          $$SessionTagsTableFilterComposer,
          $$SessionTagsTableOrderingComposer,
          $$SessionTagsTableAnnotationComposer,
          $$SessionTagsTableCreateCompanionBuilder,
          $$SessionTagsTableUpdateCompanionBuilder,
          (SessionTag, $$SessionTagsTableReferences),
          SessionTag,
          PrefetchHooks Function({bool sessionId, bool tagId})
        > {
  $$SessionTagsTableTableManager(_$AppDatabase db, $SessionTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sessionId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionTagsCompanion(
                sessionId: sessionId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sessionId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => SessionTagsCompanion.insert(
                sessionId: sessionId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$SessionTagsTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$SessionTagsTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$SessionTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$SessionTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SessionTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionTagsTable,
      SessionTag,
      $$SessionTagsTableFilterComposer,
      $$SessionTagsTableOrderingComposer,
      $$SessionTagsTableAnnotationComposer,
      $$SessionTagsTableCreateCompanionBuilder,
      $$SessionTagsTableUpdateCompanionBuilder,
      (SessionTag, $$SessionTagsTableReferences),
      SessionTag,
      PrefetchHooks Function({bool sessionId, bool tagId})
    >;
typedef $$HandsTableCreateCompanionBuilder =
    HandsCompanion Function({
      Value<int> id,
      Value<String?> title,
      Value<String?> description,
      required int playerCount,
      required double smallBlind,
      required double bigBlind,
      Value<double> ante,
      Value<int> gameType,
      Value<double> straddle,
      required List<PlayerConfig> playerConfigs,
      required List<int> communityCards,
      Value<int?> parentHandId,
      Value<int?> branchAtActionIndex,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$HandsTableUpdateCompanionBuilder =
    HandsCompanion Function({
      Value<int> id,
      Value<String?> title,
      Value<String?> description,
      Value<int> playerCount,
      Value<double> smallBlind,
      Value<double> bigBlind,
      Value<double> ante,
      Value<int> gameType,
      Value<double> straddle,
      Value<List<PlayerConfig>> playerConfigs,
      Value<List<int>> communityCards,
      Value<int?> parentHandId,
      Value<int?> branchAtActionIndex,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$HandsTableFilterComposer extends Composer<_$AppDatabase, $HandsTable> {
  $$HandsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playerCount => $composableBuilder(
    column: $table.playerCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get smallBlind => $composableBuilder(
    column: $table.smallBlind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bigBlind => $composableBuilder(
    column: $table.bigBlind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ante => $composableBuilder(
    column: $table.ante,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gameType => $composableBuilder(
    column: $table.gameType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get straddle => $composableBuilder(
    column: $table.straddle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<PlayerConfig>, List<PlayerConfig>, String>
  get playerConfigs => $composableBuilder(
    column: $table.playerConfigs,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<int>, List<int>, String>
  get communityCards => $composableBuilder(
    column: $table.communityCards,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get parentHandId => $composableBuilder(
    column: $table.parentHandId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get branchAtActionIndex => $composableBuilder(
    column: $table.branchAtActionIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HandsTableOrderingComposer
    extends Composer<_$AppDatabase, $HandsTable> {
  $$HandsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playerCount => $composableBuilder(
    column: $table.playerCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get smallBlind => $composableBuilder(
    column: $table.smallBlind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bigBlind => $composableBuilder(
    column: $table.bigBlind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ante => $composableBuilder(
    column: $table.ante,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gameType => $composableBuilder(
    column: $table.gameType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get straddle => $composableBuilder(
    column: $table.straddle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerConfigs => $composableBuilder(
    column: $table.playerConfigs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get communityCards => $composableBuilder(
    column: $table.communityCards,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parentHandId => $composableBuilder(
    column: $table.parentHandId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get branchAtActionIndex => $composableBuilder(
    column: $table.branchAtActionIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HandsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HandsTable> {
  $$HandsTableAnnotationComposer({
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
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playerCount => $composableBuilder(
    column: $table.playerCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get smallBlind => $composableBuilder(
    column: $table.smallBlind,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bigBlind =>
      $composableBuilder(column: $table.bigBlind, builder: (column) => column);

  GeneratedColumn<double> get ante =>
      $composableBuilder(column: $table.ante, builder: (column) => column);

  GeneratedColumn<int> get gameType =>
      $composableBuilder(column: $table.gameType, builder: (column) => column);

  GeneratedColumn<double> get straddle =>
      $composableBuilder(column: $table.straddle, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<PlayerConfig>, String>
  get playerConfigs => $composableBuilder(
    column: $table.playerConfigs,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<int>, String> get communityCards =>
      $composableBuilder(
        column: $table.communityCards,
        builder: (column) => column,
      );

  GeneratedColumn<int> get parentHandId => $composableBuilder(
    column: $table.parentHandId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get branchAtActionIndex => $composableBuilder(
    column: $table.branchAtActionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$HandsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HandsTable,
          Hand,
          $$HandsTableFilterComposer,
          $$HandsTableOrderingComposer,
          $$HandsTableAnnotationComposer,
          $$HandsTableCreateCompanionBuilder,
          $$HandsTableUpdateCompanionBuilder,
          (Hand, BaseReferences<_$AppDatabase, $HandsTable, Hand>),
          Hand,
          PrefetchHooks Function()
        > {
  $$HandsTableTableManager(_$AppDatabase db, $HandsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HandsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HandsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HandsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> playerCount = const Value.absent(),
                Value<double> smallBlind = const Value.absent(),
                Value<double> bigBlind = const Value.absent(),
                Value<double> ante = const Value.absent(),
                Value<int> gameType = const Value.absent(),
                Value<double> straddle = const Value.absent(),
                Value<List<PlayerConfig>> playerConfigs = const Value.absent(),
                Value<List<int>> communityCards = const Value.absent(),
                Value<int?> parentHandId = const Value.absent(),
                Value<int?> branchAtActionIndex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => HandsCompanion(
                id: id,
                title: title,
                description: description,
                playerCount: playerCount,
                smallBlind: smallBlind,
                bigBlind: bigBlind,
                ante: ante,
                gameType: gameType,
                straddle: straddle,
                playerConfigs: playerConfigs,
                communityCards: communityCards,
                parentHandId: parentHandId,
                branchAtActionIndex: branchAtActionIndex,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required int playerCount,
                required double smallBlind,
                required double bigBlind,
                Value<double> ante = const Value.absent(),
                Value<int> gameType = const Value.absent(),
                Value<double> straddle = const Value.absent(),
                required List<PlayerConfig> playerConfigs,
                required List<int> communityCards,
                Value<int?> parentHandId = const Value.absent(),
                Value<int?> branchAtActionIndex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => HandsCompanion.insert(
                id: id,
                title: title,
                description: description,
                playerCount: playerCount,
                smallBlind: smallBlind,
                bigBlind: bigBlind,
                ante: ante,
                gameType: gameType,
                straddle: straddle,
                playerConfigs: playerConfigs,
                communityCards: communityCards,
                parentHandId: parentHandId,
                branchAtActionIndex: branchAtActionIndex,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HandsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HandsTable,
      Hand,
      $$HandsTableFilterComposer,
      $$HandsTableOrderingComposer,
      $$HandsTableAnnotationComposer,
      $$HandsTableCreateCompanionBuilder,
      $$HandsTableUpdateCompanionBuilder,
      (Hand, BaseReferences<_$AppDatabase, $HandsTable, Hand>),
      Hand,
      PrefetchHooks Function()
    >;
typedef $$HandActionsTableCreateCompanionBuilder =
    HandActionsCompanion Function({
      Value<int> id,
      required int handId,
      required int sequenceIndex,
      required int street,
      required int playerPosition,
      required int actionType,
      Value<double> amount,
      Value<double> potAfterAction,
    });
typedef $$HandActionsTableUpdateCompanionBuilder =
    HandActionsCompanion Function({
      Value<int> id,
      Value<int> handId,
      Value<int> sequenceIndex,
      Value<int> street,
      Value<int> playerPosition,
      Value<int> actionType,
      Value<double> amount,
      Value<double> potAfterAction,
    });

class $$HandActionsTableFilterComposer
    extends Composer<_$AppDatabase, $HandActionsTable> {
  $$HandActionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get handId => $composableBuilder(
    column: $table.handId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequenceIndex => $composableBuilder(
    column: $table.sequenceIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get street => $composableBuilder(
    column: $table.street,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playerPosition => $composableBuilder(
    column: $table.playerPosition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get potAfterAction => $composableBuilder(
    column: $table.potAfterAction,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HandActionsTableOrderingComposer
    extends Composer<_$AppDatabase, $HandActionsTable> {
  $$HandActionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get handId => $composableBuilder(
    column: $table.handId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequenceIndex => $composableBuilder(
    column: $table.sequenceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get street => $composableBuilder(
    column: $table.street,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playerPosition => $composableBuilder(
    column: $table.playerPosition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get potAfterAction => $composableBuilder(
    column: $table.potAfterAction,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HandActionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HandActionsTable> {
  $$HandActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get handId =>
      $composableBuilder(column: $table.handId, builder: (column) => column);

  GeneratedColumn<int> get sequenceIndex => $composableBuilder(
    column: $table.sequenceIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get street =>
      $composableBuilder(column: $table.street, builder: (column) => column);

  GeneratedColumn<int> get playerPosition => $composableBuilder(
    column: $table.playerPosition,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get potAfterAction => $composableBuilder(
    column: $table.potAfterAction,
    builder: (column) => column,
  );
}

class $$HandActionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HandActionsTable,
          HandAction,
          $$HandActionsTableFilterComposer,
          $$HandActionsTableOrderingComposer,
          $$HandActionsTableAnnotationComposer,
          $$HandActionsTableCreateCompanionBuilder,
          $$HandActionsTableUpdateCompanionBuilder,
          (
            HandAction,
            BaseReferences<_$AppDatabase, $HandActionsTable, HandAction>,
          ),
          HandAction,
          PrefetchHooks Function()
        > {
  $$HandActionsTableTableManager(_$AppDatabase db, $HandActionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HandActionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HandActionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HandActionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> handId = const Value.absent(),
                Value<int> sequenceIndex = const Value.absent(),
                Value<int> street = const Value.absent(),
                Value<int> playerPosition = const Value.absent(),
                Value<int> actionType = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<double> potAfterAction = const Value.absent(),
              }) => HandActionsCompanion(
                id: id,
                handId: handId,
                sequenceIndex: sequenceIndex,
                street: street,
                playerPosition: playerPosition,
                actionType: actionType,
                amount: amount,
                potAfterAction: potAfterAction,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int handId,
                required int sequenceIndex,
                required int street,
                required int playerPosition,
                required int actionType,
                Value<double> amount = const Value.absent(),
                Value<double> potAfterAction = const Value.absent(),
              }) => HandActionsCompanion.insert(
                id: id,
                handId: handId,
                sequenceIndex: sequenceIndex,
                street: street,
                playerPosition: playerPosition,
                actionType: actionType,
                amount: amount,
                potAfterAction: potAfterAction,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HandActionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HandActionsTable,
      HandAction,
      $$HandActionsTableFilterComposer,
      $$HandActionsTableOrderingComposer,
      $$HandActionsTableAnnotationComposer,
      $$HandActionsTableCreateCompanionBuilder,
      $$HandActionsTableUpdateCompanionBuilder,
      (
        HandAction,
        BaseReferences<_$AppDatabase, $HandActionsTable, HandAction>,
      ),
      HandAction,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$SessionTagsTableTableManager get sessionTags =>
      $$SessionTagsTableTableManager(_db, _db.sessionTags);
  $$HandsTableTableManager get hands =>
      $$HandsTableTableManager(_db, _db.hands);
  $$HandActionsTableTableManager get handActions =>
      $$HandActionsTableTableManager(_db, _db.handActions);
}
