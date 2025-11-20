// ignore_for_file: no_leading_underscores_for_local_identifiers, non_constant_identifier_names

import 'package:intl/intl.dart';

class ParkingFunctions {
  ParkingFunctions({
    this.isAllowOvernightStr,
    this.openTimeStr,
    this.closedTimeStr,
    this.overnightTimeStr,
    this.vatRateNum,
    this.is24HrsStr,
    this.minsCanIssueTicketInt,
  });

  String? isAllowOvernightStr;
  String? openTimeStr;
  String? closedTimeStr;
  String? overnightTimeStr;
  num? vatRateNum;
  int? minsCanIssueTicketInt;
  String? is24HrsStr;
  int minsCanIssueTicket() => minsCanIssueTicketInt ?? 0;

  num vatRate() => vatRateNum ?? 0;

  String openTime() => openTimeStr ?? '00:00';

  String closedTime() => closedTimeStr ?? '24:00';

  bool isAllowOverNight() => (isAllowOvernightStr ?? 'N') == 'Y';

  String? overnightTime() => overnightTimeStr;

  DateTime timeConverter({
    Duration? addDuration,
    required String time,
    DateTime? dateTime,
  }) {
    DateTime today = dateTime ?? DateTime.now();
    DateTime res = DateTime.parse(
      "${(today).toString().split(' ')[0]} ${time.trim()}",
    );

    return res.add(addDuration ?? Duration());
  }

  bool isBeforeClosing({String? timeStart, DateTime? time}) {
    final now = time ?? DateTime.now();
    final timeLapse = timeConverter(
      dateTime: now,
      time: timeStart ?? openTime(),
    );

    final countDown = timeLapse.difference(now).inSeconds;

    bool gabby =
        ((countDown ~/ 60) + (countDown % 60 > 0 ? 1 : 0)) <=
            minsCanIssueTicket() &&
        now.isBefore(timeLapse);

    return gabby;
  }

  bool is24Hrs() => (is24HrsStr ?? 'N') == 'Y';

  TicketData ticket({
    required Map parkRates,
    bool isIssueTicket = false,
    num serviceFee = 0,
    Map? promoData,
    DateTime? startTime,
    DateTime? endTime,
    int bookDiscPct = 0,
    num voucherAmt = 0,
    String customerType = 'R',
  }) {
    ParkingCountdownData parkingCountdownData = parkingCountdown();
    ParkingRateData parkRatesData = parkingRates(
      parkRates,
      customerType: customerType,
    );
    DateTime timeIn = startTime ?? DateTime.now();
    DateTime timeOut = endTime ?? DateTime.now();
    Map subscriptionData = parkRates["subscription_data"] ?? {};
    num subscriptionAmt = subscriptionData["subscription_rate"] ?? 0.0;
    String subscriptionType =
        subscriptionData["subscription_type_code"] ?? 'XXX';

    if (isIssueTicket) {
      timeIn = parkingCountdownData.now;

      if (is24Hrs()) {
        timeOut = timeIn.add(Duration(hours: parkRatesData.baseHours));
      } else if (parkingCountdownData.isOvernight) {
        final isBeforeOpen = isBeforeClosing(
          time: timeIn,
          timeStart: openTime(),
        );

        if (isBeforeOpen) {
          timeOut = parkingCountdownData.closeTime.add(
            Duration(hours: parkRatesData.baseHours),
          );
        } else {
          timeOut = parkingCountdownData.closeTime;
        }
      } else {
        final isBeforeClose = isBeforeClosing(
          time: timeIn,
          timeStart: closedTime(),
        );

        if (isBeforeClose) {
          timeOut = parkingCountdownData.closeTime;
        } else {
          timeOut = parkingCountdownData.now.add(
            Duration(hours: parkRatesData.baseHours),
          );

          if (timeOut.isAfter(parkingCountdownData.closeTime)) {
            timeOut = parkingCountdownData.closeTime;
          }
        }
      }
    }

    final ParkingTimeData parkingTimeData = parkingTime(
      startTime: timeIn,
      endTime: timeOut,
      gracePeriod: parkRatesData.gracePeriod,
    );

    int _no_hours = 0;
    num regAmt = 0;
    num overnightAmt = 0.0;

    int noNights = parkingTimeData.noOfNights;
    num _totalAmt = 0.0;

    if (parkingTimeData.consumedMinutes >= parkRatesData.freePeriod) {
      if (subscriptionType == 'O') {
        noNights--;
        overnightAmt = subscriptionAmt;
      }

      overnightAmt +=
          (isAllowOverNight()
              ? noNights >= 0
                  ? noNights
                  : 0
              : 0) *
          parkRatesData.overnightRate;

      _no_hours =
          parkingTimeData.regularHours +
          (!isAllowOverNight() || parkingTimeData.overnightTime.isNotEmpty
              ? parkingTimeData.overnightHours
              : 0);

      if (subscriptionType == 'M') {
        regAmt = subscriptionAmt;
        overnightAmt = 0.0;
      } else {
        regAmt = subscriptionType == 'E' ? subscriptionAmt : 0;

        regAmt += calculateRegAmt(
          noHours:
              _no_hours -
              (subscriptionType == 'E' ? parkingTimeData.firstDayRegHrs : 0),
          baseHours: parkRatesData.baseHours,
          noOfDays:
              parkingTimeData.noOfDays - (subscriptionType == 'E' ? 1 : 0),
          succeedingHours: parkRatesData.succeedingHours,
          consumedMinutes: parkingTimeData.consumedMinutes,
          freePeriod: parkRatesData.freePeriod,
          succeedingRate: parkRatesData.succeedingRate,
          baseRate: parkRatesData.baseRate,
        );
      }

      _totalAmt = regAmt + overnightAmt + serviceFee;
    }

    VatCalculationData vatCalculationData = vatCalculation(
      _totalAmt,
      customerType: customerType,
      parkRates: parkRates,
      promoData: promoData,
      bookDiscPct: bookDiscPct,
      voucherAmt: voucherAmt,
    );

    final theLastMsg =
        is24Hrs()
            ? parkRatesData.succeedingRate == 0
                ? 'A parking rate of ${parkRatesData.baseRate.toStringAsFixed(2)} applies for every ${parkRatesData.baseHours} hour(s). Note: any fraction of the base hour will be charged as a full hour.'
                : 'A succeeding rate of ${parkRatesData.succeedingRate.toStringAsFixed(2)} will start after ${DateFormat('h:mm a').format(timeOut).toString()}, ${DateFormat('MMM dd yyyy').format(timeOut)}.'
            : (parkingCountdownData.todayCloseTime.isAtSameMomentAs(timeOut) ||
                    subscriptionType == 'E') &&
                !(parkingCountdownData.isOvernight &&
                    parkingCountdownData.isAllowOvernight)
            ? 'An overnight rate of ${parkRatesData.overnightRate.toStringAsFixed(2)} will be charged after ${DateFormat('h:mm a').format(parkingCountdownData.todayCloseTime)}, ${DateFormat('MMM dd yyyy').format(parkingCountdownData.todayCloseTime)}.'
            : parkRatesData.succeedingRate == 0
            ? 'A parking rate of ${parkRatesData.baseRate.toStringAsFixed(2)} will apply starting from the opening time.'
            : 'A succeeding rate of ${parkRatesData.succeedingRate.toStringAsFixed(2)} will start after ${DateFormat('h:mm a').format(timeOut).toString()}, ${DateFormat('MMM dd yyyy').format(timeOut)}.';

    return TicketData(
      dateIn: timeIn.toString().split('.')[0],
      dateOut: timeOut.toString().split('.')[0],
      isOvernight: parkingCountdownData.isOvernight,
      isBeforeOpen: isBeforeClosing(time: timeIn, timeStart: openTime()),
      isBeforeClosing: isBeforeClosing(time: timeIn, timeStart: closedTime()),
      noOfHours: parkingTimeData.regularHours + parkingTimeData.overnightHours,
      regularAmount: double.parse(regAmt.toStringAsFixed(2)),
      openDateTime: parkingCountdownData.openTime,
      closeDateTime: parkingCountdownData.todayCloseTime,
      overnightAmount: overnightAmt,
      totalAmt: _totalAmt,
      isAllowOvernight: isAllowOverNight(),
      countdownData: parkingCountdownData,
      rateData: parkRatesData,
      timeData: parkingTimeData,
      vatData: vatCalculationData,
      is24Hrs: is24Hrs(),
      noteMsg: theLastMsg,
    );
  }

  num calculateRegAmt({
    required int noHours,
    required num baseHours,
    required int noOfDays,
    required int succeedingHours,
    required int consumedMinutes,
    required num freePeriod,
    required num succeedingRate,
    required num baseRate,
  }) {
    num regAmt = 0;

    num _succedingHr = noHours - (baseHours * (noOfDays >= 0 ? noOfDays : 0));

    _succedingHr = _succedingHr <= 0 ? 0 : _succedingHr;

    final baseRateAmt = baseRate * (noOfDays >= 0 ? noOfDays : 0);

    final _succeedingRate =
        ((_succedingHr ~/ succeedingHours) +
            (_succedingHr % succeedingHours > 0 ? 1 : 0)) *
        succeedingRate;

    regAmt = baseRateAmt + (_succeedingRate < 0 ? 0 : _succeedingRate);

    if (succeedingRate == 0 && (consumedMinutes >= freePeriod)) {
      regAmt = baseRate * noOfDays;
    }

    if (is24Hrs()) {
      final resHrs = (noHours - baseHours) > 0 ? noHours - baseHours : 0;
      regAmt = baseRate;

      if (_succeedingRate > 0) {
        regAmt +=
            ((resHrs ~/ succeedingHours) +
                (resHrs % succeedingHours > 0 ? 1 : 0)) *
            succeedingRate;
      } else {
        final noOfBaseHrsPassed =
            (resHrs ~/ baseHours) + ((resHrs % baseHours) > 0 ? 1 : 0);

        regAmt += noOfBaseHrsPassed * baseRate;
      }
    }

    return noHours <= 0 ? 0.0 : regAmt;
  }

  ParkingCountdownData parkingCountdown() {
    DateTime bookingTime = DateTime.now();

    final splitStartTime = openTime().split(":");
    final splitEndTime = closedTime().split(":");

    final startHr = int.parse(splitStartTime[0]);
    final startMin = int.parse(splitStartTime[1]);

    final closeHr = int.parse(splitEndTime[0]);
    final closeMin = int.parse(splitEndTime[1]);

    final openDateTime = DateTime(
      bookingTime.year,
      bookingTime.month,
      bookingTime.day,
      startHr,
      startMin,
    );
    final closeDateTime = DateTime(
      bookingTime.year,
      bookingTime.month,
      bookingTime.day,
      closeHr,
      closeMin,
    );

    DateTime startDateTime = openDateTime;
    DateTime endDateTime = closeDateTime;
    bool isOverNight = false;

    if (bookingTime.isBefore(openDateTime)) {
      startDateTime = closeDateTime.subtract(Duration(days: 1));
      endDateTime = openDateTime;
      isOverNight = true;
    } else if (bookingTime.isAfter(closeDateTime) ||
        isBeforeClosing(time: bookingTime, timeStart: closedTime())) {
      startDateTime = closeDateTime;
      endDateTime = openDateTime.add(Duration(days: 1));
      isOverNight = true;
    }

    final difference = endDateTime.difference(bookingTime);
    final numHour = difference.inHours;
    final numMins = difference.inMinutes % 60;
    final numSecs = difference.inSeconds % 60;

    final inSecsOpen = difference.inSeconds;
    final inSecsClose = endDateTime.difference(startDateTime).inSeconds;

    final trailingString =
        '${numHour > 0 ? '$numHour hr${numHour > 1 ? 's' : ''}' : ''}'
        '${numHour > 0 && numMins > 0 ? ' & ' : ''}'
        '${numMins > 0 ? '$numMins min${numMins > 1 ? 's' : ''}' : ''}'
        '${numHour <= 0 && numSecs >= 0 && numMins > 0 ? ' & ' : ''}'
        '${numHour <= 0 && numSecs >= 0 ? '$numSecs sec${numSecs > 1 ? 's' : ''}' : ''}';

    final trailingText =
        is24Hrs()
            ? 'Open 24 hours a day'
            : isOverNight && isAllowOverNight()
            ? 'Remaining overnight parking: $trailingString'
            : isOverNight && !isAllowOverNight()
            ? 'Remaining time until parking opens: $trailingString'
            : 'Remaining regular parking: $trailingString';

    return ParkingCountdownData(
      now: bookingTime,
      openTime: startDateTime,
      closeTime: endDateTime,
      todayCloseTime: closeDateTime,
      gapInMins: closeDateTime.difference(openDateTime).inMinutes,
      trailingText: trailingText,
      remainingHours: numHour,
      remainingMinutes: numMins,
      countdown: trailingString,
      isOvernight: isOverNight,
      isAllowOvernight: isAllowOverNight(),
      percentage:
          is24Hrs() ? 1 : (inSecsClose == 0 ? 0 : inSecsOpen / inSecsClose),
    );
  }

  ParkingTimeData parkingTime({
    required DateTime startTime,
    required int gracePeriod,
    DateTime? endTime,
  }) {
    DateTime end = endTime ?? DateTime.now();
    final _overAllMins = end.difference(startTime).inMinutes;
    final _overAllHrs = end.difference(startTime).inHours;
    final consumedNoHrs = formatDuration(end.difference(startTime));
    final grace = gracePeriod > 0 ? gracePeriod : 2;

    int regularHours = 0;
    int firstDayRegHrs = 0;
    int overnightHours = 0;
    int overnightPasses = 0;
    int daysPasses = 0;

    DateTime current = startTime;

    while (current.isBefore(end)) {
      final List<String> regStartTimeParts = openTime().split(':');
      final List<String> regEndTimeParts = closedTime().split(':');
      final List<String> overNightTimeParts = (overnightTime() ?? '00:00')
          .split(':');

      final DateTime onTime = DateTime(
        current.year,
        current.month,
        current.day,
        int.parse(overNightTimeParts[0]),
        int.parse(overNightTimeParts[1]),
      );

      final DateTime regStart = DateTime(
        current.year,
        current.month,
        current.day,
        int.parse(regStartTimeParts[0]),
        int.parse(regStartTimeParts[1]),
      );
      final DateTime regEnd = DateTime(
        current.year,
        current.month,
        current.day,
        int.parse(regEndTimeParts[0]),
        int.parse(regEndTimeParts[1]),
      );

      final DateTime nextDay = DateTime(
        current.year,
        current.month,
        current.day + 1,
        00,
        00,
      );

      final DateTime regularEffectiveStart =
          current.isBefore(regStart) ? regStart : current;
      final DateTime regularEffectiveEnd = regEnd.isBefore(end) ? regEnd : end;

      final regular = regularEffectiveEnd.difference(regularEffectiveStart);

      final regularInHrs =
          (regular.inMinutes < 0 ? 0 : regular.inMinutes % 60) >= grace
              ? (regular.inHours < 0 ? 0 : regular.inHours) +
                  (isBeforeClosing(
                        time: regularEffectiveStart,
                        timeStart: closedTime(),
                      )
                      ? 0
                      : 1)
              : regular.inHours < 0
              ? 0
              : regular.inHours;

      regularHours += regularInHrs;

      if (regularInHrs > 0 &&
          !isBeforeClosing(time: current, timeStart: closedTime()))
        daysPasses++;

      if (daysPasses == 1) firstDayRegHrs = regularInHrs;

      if (overnightTime() != null &&
          (current.isBefore(onTime) && regularEffectiveEnd.isAfter(onTime))) {
        overnightPasses++;
      }

      if (current.isBefore(regStart) && !is24Hrs()) {
        final night = regStart.difference(current);

        final otHrs =
            (night.inMinutes < 0 ? 0 : night.inMinutes % 60) >= grace
                ? (night.inHours < 0 ? 0 : night.inHours) +
                    (isBeforeClosing(time: current, timeStart: openTime())
                        ? 0
                        : 1)
                : night.inHours < 0
                ? 0
                : night.inHours;

        overnightHours += otHrs;

        if (otHrs > 0 &&
            overnightTime() == null &&
            !current.isAtSameMomentAs(nextDay.subtract(Duration(days: 1)))) {
          overnightPasses++;
        }
      }

      if (end.isAfter(regEnd) || current.isAfter(regEnd) && !is24Hrs()) {
        final night = (nextDay.isBefore(end) ? nextDay : end).difference(
          current.isAfter(regEnd) ? current : regEnd,
        );

        final otHrs =
            (night.inMinutes < 0 ? 0 : night.inMinutes % 60) >= grace
                ? night.inHours + 1
                : night.inHours;

        overnightHours += otHrs;

        if (otHrs > 0 && overnightTime() == null) {
          overnightPasses++;
        }
      }

      current = nextDay;
    }

    if (is24Hrs()) {
      regularHours =
          (_overAllMins < 0 ? 0 : _overAllMins % 60) >= grace
              ? (_overAllHrs < 0 ? 0 : _overAllHrs) + 1
              : (_overAllHrs < 0 ? 0 : _overAllHrs);
    }

    return ParkingTimeData(
      regularHours: regularHours < 0 ? 0 : regularHours,
      firstDayRegHrs: firstDayRegHrs,
      overnightHours: overnightHours < 0 ? 0 : overnightHours,
      noOfDays: daysPasses,
      overnightTime: overnightTime() ?? '',
      noOfNights: overnightPasses < 0 ? 0 : overnightPasses,
      consumedMinutes: _overAllMins,
      duration: consumedNoHrs,
    );
  }

  ParkingRateData parkingRates(dynamic parkRates, {String customerType = 'R'}) {
    int _discountRate() {
      if (customerType == 'S') return parkRates["sc_discount"] ?? 0;
      if (customerType == 'P') return parkRates["pwd_discount"] ?? 0;
      return 0;
    }

    num _baseRate() {
      if (customerType == 'S') return parkRates["sc_base_rate"];
      if (customerType == 'P') return parkRates["pwd_base_rate"];
      if (customerType == 'T') return parkRates["tenant_base_rate"];
      return parkRates["base_rate"];
    }

    int _freePeriod() {
      if (customerType == 'S') return parkRates["sc_free_period"] ?? 1;
      if (customerType == 'P') return parkRates["pwd_free_period"] ?? 1;
      if (customerType == 'T') return parkRates["tenant_free_period"] ?? 1;
      return parkRates["free_period"] ?? 1;
    }

    num _succeedingRate() {
      if (customerType == 'S') return parkRates["sc_succeeding_rate"];
      if (customerType == 'P') return parkRates["pwd_succeeding_rate"];
      if (customerType == 'T') return parkRates["tenant_succeeding_rate"];
      return parkRates["succeeding_rate"];
    }

    return ParkingRateData(
      succeedingRate: _succeedingRate(),
      freePeriod: _freePeriod() == 0 ? 1 : _freePeriod(),
      gracePeriod:
          (parkRates["grace_period"] ?? 0) > 0
              ? (parkRates["grace_period"] ?? 0)
              : 2,
      baseRate: _baseRate(),
      discountRate: _discountRate(),
      overnightRate: parkRates["overnight_rate"] ?? 0,
      baseHours:
          (parkRates["base_hours"] ?? 0) > 0
              ? (parkRates["base_hours"] ?? 0)
              : 1,
      succeedingHours:
          (parkRates["succeeding_hours"] ?? 1) == 0
              ? 1
              : (parkRates["succeeding_hours"] ?? 1),
    );
  }

  VatCalculationData vatCalculation(
    num amount, {
    String customerType = 'R',
    required Map parkRates,
    Map? promoData,
    int bookDiscPct = 0,
    num voucherAmt = 0,
  }) {
    final _parkRates = parkingRates(parkRates, customerType: customerType);
    num totalAmt = (amount - voucherAmt) <= 0 ? 0 : amount - voucherAmt;
    final num vat = vatRate() == 0 ? 1 : 1 + (vatRate() / 100);
    num vatAmt = totalAmt - (totalAmt / vat);
    final num vatableSales = totalAmt / vat;

    num discountAmt = 0.0;
    int? promoId;
    num discountRate =
        _parkRates.discountRate > bookDiscPct
            ? _parkRates.discountRate
            : bookDiscPct;

    if (customerType == 'S' || customerType == 'P') {
      discountAmt =
          vatableSales * (discountRate == 0 ? 0 : (discountRate / 100));
      totalAmt = double.parse((vatableSales - discountAmt).toStringAsFixed(2));
    }

    if (customerType == 'R' && (promoData != null || discountRate > 0)) {
      if (promoData != null) {
        promoId = promoData["promo_id"];
        if ((promoData["discount_pct"] ?? 0) > 0) {
          discountAmt = vatableSales * ((promoData["discount_pct"] / 100) ?? 0);
          discountRate = promoData["discount_pct"] ?? 0;
        } else {
          discountAmt = promoData["discount_amt"] ?? 0;
        }
      } else {
        discountAmt =
            vatableSales * (discountRate <= 0 ? 0 : (discountRate / 100));
      }

      totalAmt = vatableSales - discountAmt;
      vatAmt = totalAmt - (totalAmt / vat);
      totalAmt += vatAmt;
    }

    return VatCalculationData(
      promoId: promoId,
      discountRate: discountRate,
      baseHours: parkRates["base_hours"] ?? 1,
      discountAmount: double.parse(discountAmt.toStringAsFixed(2)),
      vatAmount: double.parse(vatAmt.toStringAsFixed(2)),
      vatSalesAmount:
          (customerType == 'S' || customerType == 'P')
              ? 0
              : double.parse(vatableSales.toStringAsFixed(2)),
      vatExemptAmount:
          (customerType == 'S' || customerType == 'P')
              ? double.parse(vatableSales.toStringAsFixed(2))
              : 0,
      totalAmount: double.parse(totalAmt.toStringAsFixed(2)),
      vatRate: vatRate(),
    );
  }

  Map vatCal(num amount) {
    Map res = {};

    num totalAmt = amount;
    final num vat = vatRate() == 0 ? 1 : 1 + (vatRate() / 100);
    num vatAmt = totalAmt - (totalAmt / vat);
    final num vatableSales = totalAmt / vat;

    res["disc_rate"] = 0;
    res["disc_amt"] = 0.0;
    res["vat_rate"] = vatRate();
    res["vat_amt"] = double.parse(vatAmt.toStringAsFixed(2));
    res["vat_sales_amt"] = double.parse(vatableSales.toStringAsFixed(2));
    res["vat_exempt_amt"] = 0.0;
    res["amount"] = totalAmt;

    return res;
  }

  String formatDuration(Duration duration) {
    final d = duration.inDays;
    final h = duration.inHours.remainder(24);
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);

    if (d > 0) return '${d}d ${h}h';
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class ParkingTimeData {
  final int regularHours;
  final int firstDayRegHrs;
  final int overnightHours;
  final int noOfDays;
  final String overnightTime;
  final int noOfNights;
  final int consumedMinutes;
  final String duration;

  ParkingTimeData({
    required this.regularHours,
    required this.firstDayRegHrs,
    required this.overnightHours,
    required this.noOfDays,
    required this.overnightTime,
    required this.noOfNights,
    required this.consumedMinutes,
    required this.duration,
  });
}

class ParkingRateData {
  final num succeedingRate;
  final int freePeriod;
  final int gracePeriod;
  final num baseRate;
  final int discountRate;
  final num overnightRate;
  final int baseHours;
  final int succeedingHours;

  ParkingRateData({
    required this.succeedingRate,
    required this.freePeriod,
    required this.gracePeriod,
    required this.baseRate,
    required this.discountRate,
    required this.overnightRate,
    required this.baseHours,
    required this.succeedingHours,
  });
}

class VatCalculationData {
  final int? promoId;
  final num discountRate;
  final int baseHours;
  final num discountAmount;
  final num vatAmount;
  final num vatSalesAmount;
  final num vatExemptAmount;
  final num totalAmount;
  final num vatRate;

  VatCalculationData({
    this.promoId,
    required this.discountRate,
    required this.baseHours,
    required this.discountAmount,
    required this.vatAmount,
    required this.vatSalesAmount,
    required this.vatExemptAmount,
    required this.totalAmount,
    required this.vatRate,
  });
}

class ParkingCountdownData {
  final DateTime now;
  final DateTime openTime;
  final DateTime closeTime;
  final DateTime todayCloseTime;
  final int gapInMins;
  final String trailingText;
  final int remainingHours;
  final int remainingMinutes;
  final String countdown;
  final bool isOvernight;
  final double percentage;
  final bool isAllowOvernight;

  ParkingCountdownData({
    required this.now,
    required this.openTime,
    required this.closeTime,
    required this.todayCloseTime,
    required this.gapInMins,
    required this.trailingText,
    required this.remainingHours,
    required this.remainingMinutes,
    required this.countdown,
    required this.isOvernight,
    required this.percentage,
    required this.isAllowOvernight,
  });
}

class TicketData {
  final String dateIn;
  final String dateOut;
  final bool isOvernight;
  final int noOfHours;
  final double regularAmount;
  final num overnightAmount;
  final num totalAmt;
  final bool isAllowOvernight;
  final bool isBeforeOpen;
  final bool isBeforeClosing;
  final ParkingCountdownData countdownData;
  final ParkingRateData rateData;
  final ParkingTimeData timeData;
  final VatCalculationData vatData;
  final DateTime openDateTime;
  final DateTime closeDateTime;
  final bool is24Hrs;
  final String noteMsg;

  TicketData({
    required this.dateIn,
    required this.dateOut,
    required this.openDateTime,
    required this.closeDateTime,
    required this.isOvernight,
    required this.noOfHours,
    required this.regularAmount,
    required this.overnightAmount,
    required this.totalAmt,
    required this.isBeforeOpen,
    required this.isBeforeClosing,
    required this.isAllowOvernight,
    required this.countdownData,
    required this.rateData,
    required this.timeData,
    required this.vatData,
    required this.is24Hrs,
    required this.noteMsg,
  });
}
