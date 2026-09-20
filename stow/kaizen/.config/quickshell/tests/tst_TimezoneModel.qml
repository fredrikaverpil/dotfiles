import QtQuick
import QtTest
import "../plugins/services/timezone/TimezoneModel.js" as Timezone

TestCase {
  name: "TimezoneModel"

  // Verbatim from `zdump -v -c 2025,2028`, sentinel lines included: they are
  // what the parser has to survive.
  readonly property string stockholm: [
    "zone|Europe/Stockholm",
    "link|/nix/store/fh8svr4ds87z84iarfnxrlfpjlbmc816-tzdata-2026c/share/zoneinfo/Europe/Stockholm",
    "ntp|yes",
    "clock|20:05:20|2026-09-20|Sun|+0200|CEST",
    "utc|18:05:20|2026-09-20",
    "dump|Europe/Stockholm  -9223372036854775808 (gmtime failed) = -9223372036854775808 (localtime failed)",
    "dump|Europe/Stockholm  -67768040609744008 (gmtime failed) = Thu Jan  1 00:00:00 -2147481748 LMT isdst=0 gmtoff=3208",
    "dump|Europe/Stockholm  Thu Jan  1 00:00:00 -2147481748 UT = Thu Jan  1 00:53:28 -2147481748 LMT isdst=0 gmtoff=3208",
    "dump|Europe/Stockholm  Sun Mar 30 00:59:59 2025 UT = Sun Mar 30 01:59:59 2025 CET isdst=0 gmtoff=3600",
    "dump|Europe/Stockholm  Sun Mar 30 01:00:00 2025 UT = Sun Mar 30 03:00:00 2025 CEST isdst=1 gmtoff=7200",
    "dump|Europe/Stockholm  Sun Oct 26 00:59:59 2025 UT = Sun Oct 26 02:59:59 2025 CEST isdst=1 gmtoff=7200",
    "dump|Europe/Stockholm  Sun Oct 26 01:00:00 2025 UT = Sun Oct 26 02:00:00 2025 CET isdst=0 gmtoff=3600",
    "dump|Europe/Stockholm  Sun Mar 29 00:59:59 2026 UT = Sun Mar 29 01:59:59 2026 CET isdst=0 gmtoff=3600",
    "dump|Europe/Stockholm  Sun Mar 29 01:00:00 2026 UT = Sun Mar 29 03:00:00 2026 CEST isdst=1 gmtoff=7200",
    "dump|Europe/Stockholm  Sun Oct 25 00:59:59 2026 UT = Sun Oct 25 02:59:59 2026 CEST isdst=1 gmtoff=7200",
    "dump|Europe/Stockholm  Sun Oct 25 01:00:00 2026 UT = Sun Oct 25 02:00:00 2026 CET isdst=0 gmtoff=3600",
    "dump|Europe/Stockholm  Sun Mar 28 00:59:59 2027 UT = Sun Mar 28 01:59:59 2027 CET isdst=0 gmtoff=3600",
    "dump|Europe/Stockholm  Sun Mar 28 01:00:00 2027 UT = Sun Mar 28 03:00:00 2027 CEST isdst=1 gmtoff=7200",
    "dump|Europe/Stockholm  Sun Oct 31 00:59:59 2027 UT = Sun Oct 31 02:59:59 2027 CEST isdst=1 gmtoff=7200",
    "dump|Europe/Stockholm  Sun Oct 31 01:00:00 2027 UT = Sun Oct 31 02:00:00 2027 CET isdst=0 gmtoff=3600",
    "dump|Europe/Stockholm  Wed Dec 31 22:59:59 2147485547 UT = Wed Dec 31 23:59:59 2147485547 CET isdst=0 gmtoff=3600",
    "dump|Europe/Stockholm  9223372036854775807 (gmtime failed) = 9223372036854775807 (localtime failed)",
  ].join("\n")

  readonly property string tokyo: [
    "zone|Asia/Tokyo",
    "link|/nix/store/fh8svr4ds87z84iarfnxrlfpjlbmc816-tzdata-2026c/share/zoneinfo/Asia/Tokyo",
    "ntp|yes",
    "clock|03:05:20|2026-09-21|Mon|+0900|JST",
    "utc|18:05:20|2026-09-20",
    "dump|Asia/Tokyo  -9223372036854775808 (gmtime failed) = -9223372036854775808 (localtime failed)",
    "dump|Asia/Tokyo  9223372036854775807 (gmtime failed) = 9223372036854775807 (localtime failed)",
  ].join("\n")

  readonly property double now: Date.UTC(2026, 8, 20, 18, 5, 20)

  function test_a_zone_on_summer_time_reports_it_and_the_change_still_ahead() {
    const parsed = Timezone.parse(stockholm, now)
    verify(parsed.zone === "Europe/Stockholm")
    verify(parsed.synchronized === true)
    verify(parsed.time === "20:05:20")
    verify(parsed.date === "2026-09-20")
    verify(parsed.weekday === "Sun")
    verify(parsed.offset === "+0200")
    verify(parsed.abbreviation === "CEST")
    verify(parsed.utcTime === "18:05:20")
    verify(parsed.dst.observed === true)
    verify(parsed.dst.inEffect === true)
    verify(Timezone.dstLabel(parsed.dst) === "In effect")
    // The change ahead is described by the offset it brings, not the one it ends.
    verify(Timezone.nextLabel(parsed.dst) === "Sun 25 Oct 2026, 02:00 → CET (UTC+01:00)")
  }

  function test_a_zone_without_dst_says_so_rather_than_guessing() {
    const parsed = Timezone.parse(tokyo, now)
    verify(parsed.zone === "Asia/Tokyo")
    verify(parsed.abbreviation === "JST")
    verify(parsed.dst.observed === false)
    verify(parsed.dst.inEffect === false)
    verify(parsed.dst.next === null)
    verify(Timezone.dstLabel(parsed.dst) === "Not observed")
    verify(Timezone.nextLabel(parsed.dst) === "No further changes")
  }

  function test_each_change_is_read_from_its_second_line_not_its_last_second() {
    const list = Timezone.transitions(stockholm.split("\n")
      .filter(line => line.indexOf("dump|") === 0)
      .map(line => line.slice(5)).join("\n"))
    // Three years of changes; the LMT and far-future sentinel lines never parse.
    verify(list.length === 6)
    verify(list[0].abbreviation === "CEST")
    verify(list[0].dst === true)
    verify(list[0].at === Date.UTC(2025, 2, 30, 1, 0, 0))
    verify(list[3].abbreviation === "CET")
    verify(list[3].dst === false)
    verify(list[3].at === Date.UTC(2026, 9, 25, 1, 0, 0))
    verify(list[5].at === Date.UTC(2027, 9, 31, 1, 0, 0))
  }

  function test_state_before_the_years_first_change_is_standard_time() {
    const parsed = Timezone.parse(stockholm, Date.UTC(2026, 0, 15, 12, 0, 0))
    verify(parsed.dst.inEffect === false)
    verify(Timezone.dstLabel(parsed.dst) === "Standard time")
    verify(Timezone.nextLabel(parsed.dst) === "Sun 29 Mar 2026, 03:00 → CEST (UTC+02:00)")
  }

  // What a pick rejected by a read-only /etc/localtime leaves behind: timedated
  // reports the new zone, the link still points at the old one.
  function test_a_zone_timedated_could_not_write_reads_back_as_not_applied() {
    const parsed = Timezone.parse(stockholm.replace("zone|Europe/Stockholm", "zone|Asia/Tokyo"), now)
    verify(parsed.zone === "Asia/Tokyo")
    verify(Timezone.zoneMismatch(parsed.zone, parsed.link) === "Europe/Stockholm")
    // The clock keeps reporting the zone actually in force.
    verify(parsed.abbreviation === "CEST")
  }

  function test_an_applied_zone_and_an_unreadable_link_both_make_no_claim() {
    const parsed = Timezone.parse(stockholm, now)
    verify(Timezone.zoneMismatch(parsed.zone, parsed.link) === "")
    verify(Timezone.effectiveZone("/etc/zoneinfo/Europe/Stockholm") === "Europe/Stockholm")
    verify(Timezone.effectiveZone("/nix/store/abc-tzdata-2026c/share/zoneinfo/Asia/Tokyo") === "Asia/Tokyo")
    // No localtime at all, as right after a rebuild drops the managed entry.
    verify(Timezone.effectiveZone("/etc/localtime") === "")
    verify(Timezone.zoneMismatch("Asia/Tokyo", "/etc/localtime") === "")
    verify(Timezone.zoneMismatch("", "/etc/zoneinfo/Europe/Stockholm") === "")
  }

  function test_offsets_read_back_in_both_directions_including_odd_ones() {
    verify(Timezone.offsetSeconds("+0900") === 32400)
    verify(Timezone.offsetSeconds("-0430") === -16200)
    verify(Timezone.offsetSeconds("+0545") === 20700)
    verify(Timezone.offsetSeconds("nonsense") === null)
    verify(Timezone.offsetLabel(32400) === "UTC+09:00")
    verify(Timezone.offsetLabel(-16200) === "UTC-04:30")
    verify(Timezone.offsetLabel(20700) === "UTC+05:45")
    verify(Timezone.offsetLabel(0) === "UTC+00:00")
  }

  // Kathmandu and Chatham have no abbreviation, so date(1) prints the offset twice.
  function test_an_abbreviation_that_only_repeats_the_offset_is_dropped() {
    verify(Timezone.abbreviationLabel("+0545", "+0545") === "")
    verify(Timezone.abbreviationLabel("JST", "+0900") === "JST")
  }

  function test_a_shell_zone_behind_the_system_is_detected_by_its_offset() {
    // Qt still on CEST (-120) while date(1) reports Tokyo.
    verify(Timezone.staleClock("+0900", -120) === true)
    verify(Timezone.staleClock("+0200", -120) === false)
    verify(Timezone.staleClock("", -120) === false)
  }

  function test_an_empty_or_truncated_probe_renders_blanks_not_undefined() {
    const parsed = Timezone.parse("", now)
    verify(parsed.zone === "")
    verify(parsed.time === "")
    verify(parsed.synchronized === false)
    verify(parsed.dst.observed === false)
    verify(Timezone.dstLabel(parsed.dst) === "Not observed")
    const partial = Timezone.parse("zone|Asia/Tokyo\nclock|03:05", now)
    verify(partial.zone === "Asia/Tokyo")
    verify(partial.time === "")
  }
}
