// Weather events a device can subscribe to. Must match the "weather" trigger
// enum in content/schema/moment.schema.json.
export const WEATHER_EVENTS = [
  "RAIN_START",
  "RAIN_FIRST_OF_SEASON",
  "RAIN_AFTER",
  "RAIN_HEAVY",
  "THUNDER",
  "WIND_STRONG",
  "SNOW",
  "HEAT",
  "COLD",
] as const;

export type WeatherEvent = (typeof WEATHER_EVENTS)[number];

export function isWeatherEvent(value: unknown): value is WeatherEvent {
  return typeof value === "string" && (WEATHER_EVENTS as readonly string[]).includes(value);
}
