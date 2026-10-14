import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myrg/core/network/api_exception.dart';
import 'package:myrg/core/constants/app_assets.dart';
import 'package:myrg/features/activity/data/activity_api.dart';
import 'package:myrg/features/activity/data/activity_repository.dart';
import 'package:myrg/features/activity/data/notification_api.dart';
import 'package:myrg/features/auth/data/auth_api.dart';
import 'package:myrg/features/auth/data/demo_session.dart';
import 'package:myrg/features/membership/data/member_repository.dart';
import 'package:myrg/features/branch/models/branch.dart';
import 'package:myrg/features/membership/data/member_api.dart';
import 'package:myrg/features/simulation/data/catalog_valuation_repository.dart';
import 'package:myrg/features/activity/models/activity_transaction.dart';
import 'package:myrg/features/membership/models/member_profile.dart';

/// The pieces that turn MyRG backend answers into the app's models (docs/integrasi-flutter.md).
void main() {
  // The app gets Indonesian date names from flutter_localizations; plain unit tests load them here.
  setUpAll(() => initializeDateFormatting('id'));

  group('ApiException', () {
    test('reads errors.code, message and Retry-After', () {
      final e = ApiException.fromResponse(429, {
        'success': false,
        'message': 'Terlalu banyak percobaan.',
        'errors': {'code': 'ACCOUNT_LOCKED'},
      }, '900');

      expect(e.code, 'ACCOUNT_LOCKED');
      expect(e.message, 'Terlalu banyak percobaan.');
      expect(e.retryAfterSeconds, 900);
    });

    test(
      '422 field errors become VALIDATION with the first message per field',
      () {
        final e = ApiException.fromResponse(422, {
          'success': false,
          'message': 'The email field must be a valid email address.',
          'errors': {
            'email': ['Format email tidak valid'],
          },
        }, null);

        expect(e.code, 'VALIDATION');
        expect(e.fieldErrors['email'], 'Format email tidak valid');
        expect(e.displayMessage, 'Format email tidak valid');
      },
    );

    test('a non-JSON error still gives a usable message', () {
      final e = ApiException.fromResponse(502, '<html>', null);
      expect(e.code, 'HTTP_502');
      expect(e.message, isNotEmpty);
    });
  });

  test('a backend transaction maps to ActivityTransaction', () {
    final tx = ActivityApi.fromApi({
      'transactionNumber': '070240720175549',
      'location': 'Outlet Sudirman',
      'pawnDate': '2026-06-01',
      'amount': 1500000,
      'debt': 1500000,
      'loanAmount': 1500000,
      'item': {'itemName': 'iPhone 13 128GB', 'itemType': 'Handphone'},
      'activityStatus': 'needsAttention',
      'attentionLabel': 'Jatuh tempo dalam 3 hari',
      'dateLabel': '1 Juni 2026',
      'dueDateLabel': '1 Juli 2026',
      'amountLabel': 'Rp 1.500.000',
    });

    expect(tx.id, '070240720175549');
    expect(tx.reference, '#070240720175549');
    expect(tx.title, 'iPhone 13 128GB');
    expect(tx.subtitle, 'Handphone');
    expect(tx.status, ActivityStatus.needsAttention);
    expect(tx.attentionLabel, 'Jatuh tempo dalam 3 hari');
    expect(tx.dueDate, '1 Juli 2026');
    expect(tx.amount, 'Rp 1.500.000');
    expect(tx.pawn!.principal, 1500000);
    expect(tx.pawn!.branchName, 'Outlet Sudirman');
  });

  test('an unknown status falls back to processing', () {
    final tx = ActivityApi.fromApi({
      'transactionNumber': 'X',
      'activityStatus': 'somethingNew',
    });
    expect(tx.status, ActivityStatus.processing);
    expect(tx.title, 'Barang gadai');
  });

  test('tier progress uses XP while the card shows the points balance', () {
    const member = MemberProfile(
      name: 'Budi',
      number: '020500070223',
      tier: MemberTier.gold,
      points: 300, // "Poin ErGe" balance
      xp: 4500, // tier progress
      levelStart: 3000,
      levelTarget: 6000,
      balance: 0,
      voucherCount: 0,
      hasPawned: true,
      identityVerified: false,
      bankVerified: false,
    );

    expect(member.pointsToUpgrade, 1500); // "Raih 1.500 poin untuk upgrade"
    expect(member.progress, 0.5);
    expect(MemberTier.bronze.label, 'Bronze');
  });

  test('a transaction detail maps extensions, redeem and item attributes', () {
    final tx = ActivityApi.fromApi({
      'transactionNumber': '070240720175549',
      'activityStatus': 'completed',
      'item': {
        'itemName': 'iPhone 13 128GB',
        'itemAttribute': 'Warna: Hitam, IMEI: 356938035643809, Kondisi: Baik',
      },
      'summary': {
        'extensions': [
          {
            'date': '2026-05-01',
            'nextDueDate': '2026-06-01',
            'paidAmount': 175000,
          },
        ],
        'redeemedAt': '2026-06-20',
        'redeemPaymentType': 'TRANSFER',
      },
    });

    final pawn = tx.pawn!;
    expect(pawn.imei, '356938035643809');
    expect(pawn.condition, 'Baik');
    expect(pawn.extensionEvents, hasLength(1));
    expect(pawn.extensionEvents.first.label, 'Perpanjangan ke-1');
    expect(pawn.extensionEvents.first.date, contains('Rp 175.000'));
    expect(pawn.redeemedAt, isNotNull);
    expect(pawn.redemptionMethod, 'Transfer / VA');
  });

  test('a backend outlet maps to Branch with admin hours and no distance', () {
    final branch = Branch.fromApi({
      'code': '045',
      'name': 'Outlet Sudirman',
      'address': 'Jl. Sudirman 1',
      'phone': ' 021-555 ',
      'distanceKm': null,
      'todayLabel': '08:00 - 17:00 WIB',
      'services': ['Gadai HP'],
      'openingHours': [
        {
          'days': 'Senin - Jumat',
          'hours': {'open': '08:00', 'close': '17:00'},
        },
        {'days': 'Minggu', 'hours': null},
      ],
    });

    expect(branch.id, '045');
    expect(branch.phone, '021-555');
    expect(branch.distanceKm, isNull);
    expect(branch.hours, '08:00 - 17:00 WIB');
    expect(branch.services, ['Gadai HP']);
    expect(branch.openingHours, [
      ('Senin - Jumat', '08:00 - 17:00'),
      ('Minggu', 'Tutup'),
    ]);
  });

  test('an inbox item keeps its transaction number for opening the detail', () {
    final n = InboxNotification.fromApi({
      'id': 7,
      'type': 'PERPANJANGAN',
      'title': 'Perpanjangan berhasil',
      'body': 'Jatuh tempo baru 1 Juli 2026',
      'data': {'transactionNumber': '070240720175549'},
      'read': false,
      'createdAt': '2026-06-01T10:00:00+07:00',
    });

    expect(n.id, 7);
    expect(n.read, isFalse);
    expect(n.transactionNumber, '070240720175549');
    expect(n.createdAt, isNotNull);
  });

  test('catalog categories get the matching Figma icon', () {
    expect(
      CatalogValuationRepository.iconFor('Laptop'),
      AppAssets.valuationLaptop,
    );
    expect(
      CatalogValuationRepository.iconFor('Kamera'),
      AppAssets.valuationCamera,
    );
    expect(
      CatalogValuationRepository.iconFor('Handphone'),
      AppAssets.valuationPhone,
    );
  });

  test('profile photo and birth date reach the account screens', () {
    addTearDown(DemoSession.reset);
    MemberApi.applyProfile({
      'phone': '+6281234567890',
      'email': null,
      'birthDate': '1995-08-17',
      'avatarUrl': 'http://localhost:8000/storage/avatars/a.jpg',
    });

    final contact = DemoSession.contact.value;
    expect(contact.email, '');
    expect(contact.birthDate, '1995-08-17');
    // localhost is the laptop, not the emulator: the link points at the API host instead.
    expect(contact.avatarUrl, 'http://10.0.2.2:8000/storage/avatars/a.jpg');
  });

  test('photo links on a real server are kept as they are', () {
    const url = 'https://api.myrg.id/storage/avatars/a.jpg';
    expect(MemberApi.reachableUrl(url), url);
    expect(MemberApi.reachableUrl(null), isNull);
  });

  test('logging out leaves nothing of the previous member on screen', () {
    addTearDown(DemoSession.reset);
    ActivityApi.ongoing.value = [
      ActivityApi.fromApi({'transactionNumber': 'A-1'}),
    ];
    ActivityApi.history.value = const [];
    DemoSession.setContact(email: 'budi@example.com', phone: '+6281234567890');

    AuthApi.clearLocalData();

    expect(ActivityApi.ongoing.value, isNull);
    expect(ActivityApi.history.value, isNull);
    expect(DemoSession.contact.value.phone, '');
    expect(MemberRepository.profile.value.name, '');
    expect(MemberRepository.profile.value.number, '');
  });

  test('demo mode keeps its sample pawns and never shows a loading state', () {
    ActivityApi.clear();
    expect(ActivityRepository.loading, isFalse);
    expect(ActivityRepository.ongoing, ActivityRepository.fixtureOngoing);
    expect(ActivityApi.loadError.value, isNull);
  });
}
