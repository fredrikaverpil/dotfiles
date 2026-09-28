// IANA zone ids, never offsets: a zone name is a rule set that tzdata
// evaluates per instant, so DST follows by itself. A stored offset is what
// would need correcting twice a year.
//
// The menu's "zones" provider lists these in order, so home comes first and
// the rest are grouped by region. Search only matches the city, not the id.

var home = { name: "Göteborg", zone: "Europe/Stockholm" }

var zones = [
  home,
  { name: "London", zone: "Europe/London" },
  { name: "Dublin", zone: "Europe/Dublin" },
  { name: "Lisbon", zone: "Europe/Lisbon" },
  { name: "Paris", zone: "Europe/Paris" },
  { name: "Amsterdam", zone: "Europe/Amsterdam" },
  { name: "Brussels", zone: "Europe/Brussels" },
  { name: "Berlin", zone: "Europe/Berlin" },
  { name: "Zurich", zone: "Europe/Zurich" },
  { name: "Madrid", zone: "Europe/Madrid" },
  { name: "Rome", zone: "Europe/Rome" },
  { name: "Copenhagen", zone: "Europe/Copenhagen" },
  { name: "Oslo", zone: "Europe/Oslo" },
  { name: "Helsinki", zone: "Europe/Helsinki" },
  { name: "Warsaw", zone: "Europe/Warsaw" },
  { name: "Athens", zone: "Europe/Athens" },
  { name: "Istanbul", zone: "Europe/Istanbul" },
  { name: "Moscow", zone: "Europe/Moscow" },
  { name: "Reykjavík", zone: "Atlantic/Reykjavik" },

  { name: "New York", zone: "America/New_York" },
  { name: "Toronto", zone: "America/Toronto" },
  { name: "Chicago", zone: "America/Chicago" },
  { name: "Denver", zone: "America/Denver" },
  { name: "Los Angeles", zone: "America/Los_Angeles" },
  { name: "Vancouver", zone: "America/Vancouver" },
  { name: "Mexico City", zone: "America/Mexico_City" },
  { name: "São Paulo", zone: "America/Sao_Paulo" },
  { name: "Buenos Aires", zone: "America/Argentina/Buenos_Aires" },

  { name: "Cairo", zone: "Africa/Cairo" },
  { name: "Lagos", zone: "Africa/Lagos" },
  { name: "Nairobi", zone: "Africa/Nairobi" },
  { name: "Johannesburg", zone: "Africa/Johannesburg" },

  { name: "Jerusalem", zone: "Asia/Jerusalem" },
  { name: "Dubai", zone: "Asia/Dubai" },
  { name: "Mumbai", zone: "Asia/Kolkata" },
  { name: "Bangkok", zone: "Asia/Bangkok" },
  { name: "Singapore", zone: "Asia/Singapore" },
  { name: "Hong Kong", zone: "Asia/Hong_Kong" },
  { name: "Shanghai", zone: "Asia/Shanghai" },
  { name: "Seoul", zone: "Asia/Seoul" },
  { name: "Tokyo", zone: "Asia/Tokyo" },

  { name: "Perth", zone: "Australia/Perth" },
  { name: "Adelaide", zone: "Australia/Adelaide" },
  { name: "Sydney", zone: "Australia/Sydney" },
  { name: "Auckland", zone: "Pacific/Auckland" },

  { name: "UTC", zone: "UTC" },
]
