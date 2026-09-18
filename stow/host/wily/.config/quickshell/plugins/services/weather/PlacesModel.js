// Coordinates carry two decimals: api.met.no rejects finer than four, ~1 km is
// indistinguishable in a forecast, and it keeps a home address out of a public
// repository. See WeatherModel.coordinate.
//
// The menu's "places" provider lists these in order, so home comes first and
// the rest are grouped by region. Search only matches the name, not country.

var home = { name: "Göteborg", country: "Sweden", latitude: 57.71, longitude: 11.97 }

var places = [
  home,
  { name: "Stockholm", country: "Sweden", latitude: 59.33, longitude: 18.07 },
  { name: "Malmö", country: "Sweden", latitude: 55.60, longitude: 13.00 },
  { name: "Copenhagen", country: "Denmark", latitude: 55.68, longitude: 12.57 },
  { name: "Oslo", country: "Norway", latitude: 59.91, longitude: 10.75 },
  { name: "Helsinki", country: "Finland", latitude: 60.17, longitude: 24.94 },
  { name: "Reykjavík", country: "Iceland", latitude: 64.15, longitude: -21.94 },

  { name: "London", country: "United Kingdom", latitude: 51.51, longitude: -0.13 },
  { name: "Dublin", country: "Ireland", latitude: 53.35, longitude: -6.26 },
  { name: "Paris", country: "France", latitude: 48.86, longitude: 2.35 },
  { name: "Amsterdam", country: "Netherlands", latitude: 52.37, longitude: 4.90 },
  { name: "Brussels", country: "Belgium", latitude: 50.85, longitude: 4.35 },
  { name: "Berlin", country: "Germany", latitude: 52.52, longitude: 13.40 },
  { name: "Munich", country: "Germany", latitude: 48.14, longitude: 11.58 },
  { name: "Zurich", country: "Switzerland", latitude: 47.37, longitude: 8.54 },
  { name: "Vienna", country: "Austria", latitude: 48.21, longitude: 16.37 },
  { name: "Prague", country: "Czechia", latitude: 50.08, longitude: 14.44 },
  { name: "Warsaw", country: "Poland", latitude: 52.23, longitude: 21.01 },
  { name: "Madrid", country: "Spain", latitude: 40.42, longitude: -3.70 },
  { name: "Barcelona", country: "Spain", latitude: 41.39, longitude: 2.17 },
  { name: "Lisbon", country: "Portugal", latitude: 38.72, longitude: -9.14 },
  { name: "Rome", country: "Italy", latitude: 41.90, longitude: 12.50 },
  { name: "Milan", country: "Italy", latitude: 45.46, longitude: 9.19 },
  { name: "Athens", country: "Greece", latitude: 37.98, longitude: 23.73 },
  { name: "Istanbul", country: "Türkiye", latitude: 41.01, longitude: 28.98 },
  { name: "Moscow", country: "Russia", latitude: 55.76, longitude: 37.62 },

  { name: "New York", country: "United States", latitude: 40.71, longitude: -74.01 },
  { name: "Chicago", country: "United States", latitude: 41.88, longitude: -87.63 },
  { name: "San Francisco", country: "United States", latitude: 37.77, longitude: -122.42 },
  { name: "Los Angeles", country: "United States", latitude: 34.05, longitude: -118.24 },
  { name: "Seattle", country: "United States", latitude: 47.61, longitude: -122.33 },
  { name: "Toronto", country: "Canada", latitude: 43.65, longitude: -79.38 },
  { name: "Vancouver", country: "Canada", latitude: 49.28, longitude: -123.12 },
  { name: "Mexico City", country: "Mexico", latitude: 19.43, longitude: -99.13 },
  { name: "São Paulo", country: "Brazil", latitude: -23.55, longitude: -46.63 },
  { name: "Rio de Janeiro", country: "Brazil", latitude: -22.91, longitude: -43.17 },
  { name: "Buenos Aires", country: "Argentina", latitude: -34.60, longitude: -58.38 },

  { name: "Cairo", country: "Egypt", latitude: 30.04, longitude: 31.24 },
  { name: "Lagos", country: "Nigeria", latitude: 6.52, longitude: 3.38 },
  { name: "Nairobi", country: "Kenya", latitude: -1.29, longitude: 36.82 },
  { name: "Johannesburg", country: "South Africa", latitude: -26.20, longitude: 28.05 },
  { name: "Cape Town", country: "South Africa", latitude: -33.92, longitude: 18.42 },

  { name: "Tel Aviv", country: "Israel", latitude: 32.09, longitude: 34.78 },
  { name: "Dubai", country: "United Arab Emirates", latitude: 25.20, longitude: 55.27 },
  { name: "Delhi", country: "India", latitude: 28.61, longitude: 77.21 },
  { name: "Mumbai", country: "India", latitude: 19.08, longitude: 72.88 },
  { name: "Bangkok", country: "Thailand", latitude: 13.76, longitude: 100.50 },
  { name: "Singapore", country: "Singapore", latitude: 1.35, longitude: 103.82 },
  { name: "Jakarta", country: "Indonesia", latitude: -6.21, longitude: 106.85 },
  { name: "Hong Kong", country: "China", latitude: 22.32, longitude: 114.17 },
  { name: "Shanghai", country: "China", latitude: 31.23, longitude: 121.47 },
  { name: "Beijing", country: "China", latitude: 39.90, longitude: 116.41 },
  { name: "Seoul", country: "South Korea", latitude: 37.57, longitude: 126.98 },
  { name: "Tokyo", country: "Japan", latitude: 35.68, longitude: 139.69 },
  { name: "Osaka", country: "Japan", latitude: 34.69, longitude: 135.50 },

  { name: "Sydney", country: "Australia", latitude: -33.87, longitude: 151.21 },
  { name: "Melbourne", country: "Australia", latitude: -37.81, longitude: 144.96 },
  { name: "Auckland", country: "New Zealand", latitude: -36.85, longitude: 174.76 },
]
